#include "manualcontroller.h"
#include "globaldata.h"
#include "networkinterfaces.h"
#include "parammanager.h"
#include <QtMath>
#include <QCoreApplication>
#include <QKeyEvent>
#include <QSet>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <cstring>
#include <SDL2/SDL.h>

ManualController* ManualController::s_instance = nullptr;

ManualController::ManualController(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
{
    s_instance = this;
    m_timer->setInterval(TICK_INTERVAL);
    connect(m_timer, &QTimer::timeout, this, &ManualController::tick);
    m_lastMouseTime.start();
    QCoreApplication::instance()->installEventFilter(this);
    m_gamepadCmdFd = socket(AF_INET, SOCK_DGRAM, 0);
    initSDL();
    for (int s = 0; s < MAX_SLOTS; ++s) {
        loadSlotParams(s);
    }
    updateStatus();
}

ManualController::~ManualController() {
    QCoreApplication::instance()->removeEventFilter(this);
    for (int s = 0; s < MAX_SLOTS; ++s) {
        closeGamepadSlot(s);
    }
    if (m_sdlInitialized) {
        SDL_QuitSubSystem(SDL_INIT_GAMECONTROLLER);
        m_sdlInitialized = false;
    }
    if (m_gamepadCmdFd >= 0) close(m_gamepadCmdFd);
    if (s_instance == this) s_instance = nullptr;
}

bool ManualController::eventFilter(QObject *obj, QEvent *event) {
    if (!m_active || m_useGamepad) return QObject::eventFilter(obj, event);

    if (event->type() == QEvent::KeyPress || event->type() == QEvent::KeyRelease) {
        QKeyEvent *keyEvent = static_cast<QKeyEvent*>(event);
        if (!keyEvent->isAutoRepeat()) {
            int key = keyEvent->key();
            bool pressed = (event->type() == QEvent::KeyPress);
            processKey(key, pressed);
            if (key == Qt::Key_W || key == Qt::Key_A ||
                key == Qt::Key_S || key == Qt::Key_D ||
                key == Qt::Key_Space || key == Qt::Key_Shift ||
                key == Qt::Key_Control) {
                return true;
            }
        }
    }
    return QObject::eventFilter(obj, event);
}

void ManualController::processKey(int key, bool pressed) {
    m_keyState[key] = pressed;
    if (key == Qt::Key_Space && pressed) m_emergencyStop = true;
    if (!m_keyState.value(Qt::Key_Space, false)) m_emergencyStop = false;
}

void ManualController::setMouseFieldPos(qreal x, qreal y) {
    m_mouseFieldPos = QVector2D(x, y);
    m_mouseActive = true;
    m_lastMouseTime.restart();
}

void ManualController::setMouseActive(bool active) { m_mouseActive = active; }
void ManualController::setKickActive(bool active) { m_kick = active; }
void ManualController::setDribbleActive(bool active) { m_slots[m_selectedSlot].dribble = active; emit dribbleChanged(); }

void ManualController::setUseGamepad(bool use) {
    if (m_useGamepad == use) return;
    m_useGamepad = use;
    if (use) {
        pollAllGamepads();
    }
    if (!use) {
        m_kick = false;
        for (int s = 0; s < MAX_SLOTS; ++s) {
            m_slots[s].dribble = false;
        }
        emit dribbleChanged();
    }
    m_keyState.clear();
    emit useGamepadChanged();
}

void ManualController::setActive(bool active) {
    if (m_active == active) return;
    m_active = active;
    if (active) {
        m_timer->start();
        m_keyState.clear();
        m_emergencyStop = false;
        for (int s = 0; s < MAX_SLOTS; ++s) {
            m_slots[s].cmdGlobalVx = 0;
            m_slots[s].cmdGlobalVy = 0;
            m_slots[s].dribble = false;
        }
        m_kick = false;
        emit dribbleChanged();
    } else {
        m_timer->stop();
        m_keyState.clear();
        for (int s = 0; s < MAX_SLOTS; ++s) {
            m_slots[s].cmdGlobalVx = 0;
            m_slots[s].cmdGlobalVy = 0;
            m_slots[s].currentVx = 0;
            m_slots[s].currentVy = 0;
            m_slots[s].currentVr = 0;
        }
        emit velocityChanged();
    }
    updateStatus();
    emit activeChanged();
}

void ManualController::setSelectedSlot(int slot) {
    if (slot < 0 || slot >= MAX_SLOTS || m_selectedSlot == slot) return;
    m_selectedSlot = slot;
    emit selectedSlotChanged();
    emit robotIdChanged();
    emit maxSpeedChanged();
    emit slowSpeedChanged();
    emit maxRotSpeedChanged();
    emit kickPowerChanged();
    emit accelerationChanged();
    emit decelerationChanged();
    emit rotKpChanged();
    emit rotKdChanged();
    emit dgRotSpeedChanged();
    emit dgAngleThreshChanged();
    emit dgRotCenterXChanged();
    emit dgRotCenterYChanged();
    emit autoFaceChanged();
    emit brakeRatioChanged();
    emit brakeThreshChanged();
    emit dgPullBallChanged();
    emit gamepadLayoutChanged();
    emit velocityChanged();
    emit dribbleChanged();
}

QString ManualController::slotParamKey(int si, const QString& key) const {
    if (si == 0) return QString("Manual/%1").arg(key);
    return QString("Manual/Slot%1/%2").arg(si).arg(key);
}

void ManualController::loadSlotParams(int si) {
    auto* zpm = ZSS::ZParamManager::instance();
    auto& s = m_slots[si];
    zpm->loadParam(s.robotId, slotParamKey(si, "robotId"), si == 0 ? 1 : si + 1);
    zpm->loadParam(s.maxSpeed, slotParamKey(si, "maxSpeed"), 1.2);
    zpm->loadParam(s.slowSpeed, slotParamKey(si, "slowSpeed"), 1.0);
    zpm->loadParam(s.maxRotSpeed, slotParamKey(si, "maxRotSpeed"), 10.0);
    zpm->loadParam(s.kickPower, slotParamKey(si, "kickPower"), 5.0);
    zpm->loadParam(s.acceleration, slotParamKey(si, "acceleration"), 1.6);
    zpm->loadParam(s.deceleration, slotParamKey(si, "deceleration"), 12.0);
    zpm->loadParam(s.rotKp, slotParamKey(si, "rotKp"), 6.5);
    zpm->loadParam(s.rotKd, slotParamKey(si, "rotKd"), 0);
    zpm->loadParam(s.dgRotSpeed, slotParamKey(si, "dgRotSpeed"), 4.5);
    zpm->loadParam(s.dgAngleThresh, slotParamKey(si, "dgAngleThresh"), 20.0);
    zpm->loadParam(s.dgRotCenterX, slotParamKey(si, "dgRotCenterX"), 120.0);
    zpm->loadParam(s.dgRotCenterY, slotParamKey(si, "dgRotCenterY"), 0.0);
    zpm->loadParam(s.autoFace, slotParamKey(si, "autoFace"), false);
    zpm->loadParam(s.brakeRatio, slotParamKey(si, "brakeRatio"), 0.5);
    zpm->loadParam(s.brakeThresh, slotParamKey(si, "brakeThresh"), 0.4);
    zpm->loadParam(s.dgPullBall, slotParamKey(si, "dgPullBall"), true);
    zpm->loadParam(s.gamepadLayout, slotParamKey(si, "gamepadLayout"), 0);
}

// Per-slot setters
void ManualController::setRobotId(int id) { auto& s = m_slots[m_selectedSlot]; if (s.robotId != id) { s.robotId = id; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "robotId"), id); emit robotIdChanged(); } }
void ManualController::setMaxSpeed(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.maxSpeed, v)) return; s.maxSpeed = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "maxSpeed"), v); emit maxSpeedChanged(); }
void ManualController::setSlowSpeed(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.slowSpeed, v)) return; s.slowSpeed = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "slowSpeed"), v); emit slowSpeedChanged(); }
void ManualController::setMaxRotSpeed(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.maxRotSpeed, v)) return; s.maxRotSpeed = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "maxRotSpeed"), v); emit maxRotSpeedChanged(); }
void ManualController::setKickPower(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.kickPower, v)) return; s.kickPower = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "kickPower"), v); emit kickPowerChanged(); }
void ManualController::setAcceleration(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.acceleration, v)) return; s.acceleration = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "acceleration"), v); emit accelerationChanged(); }
void ManualController::setDeceleration(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.deceleration, v)) return; s.deceleration = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "deceleration"), v); emit decelerationChanged(); }
void ManualController::setRotKp(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.rotKp, v)) return; s.rotKp = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "rotKp"), v); emit rotKpChanged(); }
void ManualController::setRotKd(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.rotKd, v)) return; s.rotKd = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "rotKd"), v); emit rotKdChanged(); }
void ManualController::setDgRotSpeed(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.dgRotSpeed, v)) return; s.dgRotSpeed = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "dgRotSpeed"), v); emit dgRotSpeedChanged(); }
void ManualController::setDgAngleThresh(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.dgAngleThresh, v)) return; s.dgAngleThresh = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "dgAngleThresh"), v); emit dgAngleThreshChanged(); }
void ManualController::setDgRotCenterX(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.dgRotCenterX, v)) return; s.dgRotCenterX = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "dgRotCenterX"), v); emit dgRotCenterXChanged(); }
void ManualController::setDgRotCenterY(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.dgRotCenterY, v)) return; s.dgRotCenterY = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "dgRotCenterY"), v); emit dgRotCenterYChanged(); }
void ManualController::setAutoFace(bool v) { auto& s = m_slots[m_selectedSlot]; if (s.autoFace == v) return; s.autoFace = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "autoFace"), v); emit autoFaceChanged(); }
void ManualController::setBrakeRatio(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.brakeRatio, v)) return; s.brakeRatio = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "brakeRatio"), v); emit brakeRatioChanged(); }
void ManualController::setBrakeThresh(qreal v) { auto& s = m_slots[m_selectedSlot]; if (qFuzzyCompare(s.brakeThresh, v)) return; s.brakeThresh = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "brakeThresh"), v); emit brakeThreshChanged(); }
void ManualController::setDgPullBall(bool v) { auto& s = m_slots[m_selectedSlot]; if (s.dgPullBall == v) return; s.dgPullBall = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "dgPullBall"), v); emit dgPullBallChanged(); }
void ManualController::setGamepadLayout(int v) { auto& s = m_slots[m_selectedSlot]; if (s.gamepadLayout == v) return; s.gamepadLayout = v; ZSS::ZParamManager::instance()->changeParam(slotParamKey(m_selectedSlot, "gamepadLayout"), v); emit gamepadLayoutChanged(); }

// Multi-slot API for QML
bool ManualController::slotConnected(int slot) const {
    if (slot < 0 || slot >= MAX_SLOTS) return false;
    return m_slots[slot].connected;
}
int ManualController::slotRobotId(int slot) const {
    if (slot < 0 || slot >= MAX_SLOTS) return -1;
    return m_slots[slot].robotId;
}
int ManualController::slotLayout(int slot) const {
    if (slot < 0 || slot >= MAX_SLOTS) return 0;
    return m_slots[slot].gamepadLayout;
}
int ManualController::slotCount() const {
    int c = 0;
    for (int s = 0; s < MAX_SLOTS; ++s) if (m_slots[s].connected) ++c;
    return c;
}
bool ManualController::gamepadConnected() const {
    for (int s = 0; s < MAX_SLOTS; ++s) if (m_slots[s].connected) return true;
    return false;
}

// Team setter
void ManualController::setTeam(int team) { if (m_team != team) { m_team = team; emit teamChanged(); } }

void ManualController::sendSlotCmd(int si, float vx, float vy, float vr,
                                    bool kick, float kickPower, bool dribble) {
    if (m_gamepadCmdFd < 0) return;
    const int BTN_COUNT = 16;
    const int PKT_SIZE = 35;
    uint8_t buf[PKT_SIZE];
    std::memset(buf, 0, PKT_SIZE);

    auto& slot = m_slots[si];
    if (slot.gamepad) {
        SDL_Joystick* joy = SDL_GameControllerGetJoystick(slot.gamepad);
        if (joy) {
            if (slot.gamepadLayout == 0) {
                for (int i = 0; i < BTN_COUNT; ++i) {
                    buf[i] = SDL_JoystickGetButton(joy, i) ? 1 : 0;
                }
            } else {
                static const int xoneToLogical[] = {0, 1, 3, 4, 6, 7};
                for (int raw = 0; raw < 6; ++raw) {
                    buf[xoneToLogical[raw]] = SDL_JoystickGetButton(joy, raw) ? 1 : 0;
                }
                buf[13] = SDL_JoystickGetButton(joy, 9) ? 1 : 0;
            }
        }
    }

    buf[BTN_COUNT] = dribble ? 1 : 0;
    buf[BTN_COUNT + 1] = static_cast<uint8_t>(slot.robotId);

    float fvx = vx, fvy = vy, fvr = vr, fkp = kickPower;
    std::memcpy(&buf[18], &fvx, 4);
    std::memcpy(&buf[22], &fvy, 4);
    std::memcpy(&buf[26], &fvr, 4);
    std::memcpy(&buf[30], &fkp, 4);
    buf[34] = kick ? 1 : 0;

    struct sockaddr_in addr;
    std::memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(ZSS::Athena::GAMEPAD_CMD_SEND[m_team]);
    inet_pton(AF_INET, ZSS::LOCAL_ADDRESS.toLatin1().constData(), &addr.sin_addr);
    sendto(m_gamepadCmdFd, buf, PKT_SIZE, 0,
           (struct sockaddr*)&addr, sizeof(addr));
}

void ManualController::tick() {
    if (!m_active) return;

    if (m_useGamepad) {
        pollAllGamepads();
        for (int s = 0; s < MAX_SLOTS; ++s) {
            if (m_slots[s].connected) {
                tickSlot(s);
            }
        }
    } else {
        tickSlot(m_selectedSlot);
    }
}

void ManualController::tickSlot(int si) {
    auto& slot = m_slots[si];
    bool isGp = m_useGamepad && slot.connected;

    auto& maintain = GlobalData::instance()->maintain[0];
    int robotIdx = -1;
    for (int j = 0; j < maintain.robotSize[m_team]; j++) {
        if (maintain.robot[m_team][j].id == static_cast<unsigned short>(slot.robotId)) {
            robotIdx = j;
            break;
        }
    }
    if (robotIdx < 0) return;

    auto& robot = maintain.robot[m_team][robotIdx];
    double robotAngle = robot.angle;
    double actualRotVel = robot.rotateVel;

    if (!isGp && m_emergencyStop) {
        slot.cmdGlobalVx = 0;
        slot.cmdGlobalVy = 0;
        slot.currentVx = slot.currentVy = slot.currentVr = 0;
        if (si == m_selectedSlot) emit velocityChanged();
        sendSlotCmd(si, 0, 0, 0, false, 0, false);
        return;
    }

    bool skillActive = isGp && (slot.gpBtnA || slot.gpBtnB || slot.gpBtnX || slot.gpBtnY);
    if (skillActive) {
        slot.cmdGlobalVx = 0;
        slot.cmdGlobalVy = 0;
        slot.currentVx = slot.currentVy = slot.currentVr = 0;
        if (si == m_selectedSlot) emit velocityChanged();
        sendSlotCmd(si, 0, 0, 0, false, 0, false);
        return;
    }

    double targetVx = 0, targetVy = 0;
    double speed = slot.maxSpeed;

    if (isGp) {
        targetVx = slot.gpLeftX * speed;
        targetVy = slot.gpLeftY * speed;
    } else {
        if (m_keyState.value(Qt::Key_Control, false)) speed = slot.slowSpeed;
        if (m_keyState.value(Qt::Key_W, false)) targetVy += speed;
        if (m_keyState.value(Qt::Key_S, false)) targetVy -= speed;
        if (m_keyState.value(Qt::Key_A, false)) targetVx -= speed;
        if (m_keyState.value(Qt::Key_D, false)) targetVx += speed;
    }

    double targetMag = qSqrt(targetVx * targetVx + targetVy * targetVy);
    if (targetMag > speed) {
        targetVx *= speed / targetMag;
        targetVy *= speed / targetMag;
        targetMag = speed;
    }

    double cmdVr = 0;
    bool hasRightStick = false;
    if (isGp) {
        double rightMag = qSqrt(slot.gpRightX * slot.gpRightX + slot.gpRightY * slot.gpRightY);
        if (rightMag > 0.15) {
            hasRightStick = true;
            double targetAngle = qAtan2(slot.gpRightY, slot.gpRightX);
            double angleDiff = targetAngle - robotAngle;
            while (angleDiff > M_PI) angleDiff -= 2 * M_PI;
            while (angleDiff < -M_PI) angleDiff += 2 * M_PI;
            cmdVr = slot.rotKp * angleDiff - slot.rotKd * actualRotVel;
            cmdVr = clamp(cmdVr, -slot.maxRotSpeed, slot.maxRotSpeed);
            if (qAbs(angleDiff) < qDegreesToRadians(0.5)) cmdVr = 0;
        }
    } else if (m_mouseActive) {
        double robotXm = robot.pos.x() / 1000.0;
        double robotYm = robot.pos.y() / 1000.0;
        double mouseXm = m_mouseFieldPos.x() / 1000.0;
        double mouseYm = m_mouseFieldPos.y() / 1000.0;
        double targetAngle = qAtan2(mouseYm - robotYm, mouseXm - robotXm);
        double angleDiff = targetAngle - robotAngle;
        while (angleDiff > M_PI) angleDiff -= 2 * M_PI;
        while (angleDiff < -M_PI) angleDiff += 2 * M_PI;
        cmdVr = slot.rotKp * angleDiff - slot.rotKd * actualRotVel;
        cmdVr = clamp(cmdVr, -slot.maxRotSpeed, slot.maxRotSpeed);
        if (qAbs(angleDiff) < qDegreesToRadians(0.5)) cmdVr = 0;
    }

    double cmdMagPrev = qSqrt(slot.cmdGlobalVx * slot.cmdGlobalVx + slot.cmdGlobalVy * slot.cmdGlobalVy);
    bool targetDropping = (slot.prevTargetMag > 0.3) && (targetMag < slot.prevTargetMag * slot.brakeThresh);
    slot.prevTargetMag = targetMag;

    if (!targetDropping && targetMag >= 0.01) {
        slot.braking = false;
    }

    if (targetDropping || targetMag < 0.01) {
        if (!slot.braking && cmdMagPrev > 0.15) {
            slot.braking = true;
            slot.brakeVx = -slot.cmdGlobalVx * slot.brakeRatio;
            slot.brakeVy = -slot.cmdGlobalVy * slot.brakeRatio;
        }
        if (slot.braking) {
            slot.cmdGlobalVx = slot.brakeVx;
            slot.cmdGlobalVy = slot.brakeVy;
            slot.brakeVx = moveTowards(slot.brakeVx, 0, slot.deceleration * DT);
            slot.brakeVy = moveTowards(slot.brakeVy, 0, slot.deceleration * DT);
            if (qAbs(slot.brakeVx) < 0.01 && qAbs(slot.brakeVy) < 0.01) {
                slot.braking = false;
                slot.cmdGlobalVx = 0;
                slot.cmdGlobalVy = 0;
            }
        } else {
            slot.cmdGlobalVx = moveTowards(slot.cmdGlobalVx, 0, slot.deceleration * DT);
            slot.cmdGlobalVy = moveTowards(slot.cmdGlobalVy, 0, slot.deceleration * DT);
        }
    } else {
        bool sameDirX = (slot.cmdGlobalVx == 0) || (slot.cmdGlobalVx > 0) == (targetVx > 0);
        bool sameDirY = (slot.cmdGlobalVy == 0) || (slot.cmdGlobalVy > 0) == (targetVy > 0);
        if (sameDirX) {
            slot.cmdGlobalVx = moveTowards(slot.cmdGlobalVx, targetVx, slot.acceleration * DT);
        } else {
            slot.cmdGlobalVx = moveTowards(slot.cmdGlobalVx, 0, slot.deceleration * 2 * DT);
        }
        if (sameDirY) {
            slot.cmdGlobalVy = moveTowards(slot.cmdGlobalVy, targetVy, slot.acceleration * DT);
        } else {
            slot.cmdGlobalVy = moveTowards(slot.cmdGlobalVy, 0, slot.deceleration * 2 * DT);
        }
    }

    double cmdMag = qSqrt(slot.cmdGlobalVx * slot.cmdGlobalVx + slot.cmdGlobalVy * slot.cmdGlobalVy);
    if (cmdMag > slot.maxSpeed * 1.5) {
        slot.cmdGlobalVx *= slot.maxSpeed * 1.5 / cmdMag;
        slot.cmdGlobalVy *= slot.maxSpeed * 1.5 / cmdMag;
        cmdMag = slot.maxSpeed * 1.5;
    }

    if (slot.autoFace && !hasRightStick && isGp && cmdMag > 0.15) {
        double moveDir = qAtan2(slot.cmdGlobalVy, slot.cmdGlobalVx);
        double angleDiff = moveDir - robotAngle;
        while (angleDiff > M_PI) angleDiff -= 2 * M_PI;
        while (angleDiff < -M_PI) angleDiff += 2 * M_PI;
        cmdVr = slot.rotKp * angleDiff - slot.rotKd * actualRotVel;
        cmdVr = clamp(cmdVr, -slot.maxRotSpeed, slot.maxRotSpeed);
        if (qAbs(angleDiff) < qDegreesToRadians(0.5)) cmdVr = 0;
    }

    double cosA = qCos(robotAngle);
    double sinA = qSin(robotAngle);
    double cmdLocalVx = slot.cmdGlobalVx * cosA + slot.cmdGlobalVy * sinA;
    double cmdLocalVy = -slot.cmdGlobalVx * sinA + slot.cmdGlobalVy * cosA;

    bool doKick = m_kick;
    double kickPwr = slot.kickPower;
    bool doDribble = slot.dribble;

    if (isGp) {
        if (slot.gpBtnLB) {
            doKick = true;
            double rightMag = qSqrt(slot.gpRightX * slot.gpRightX + slot.gpRightY * slot.gpRightY);
            kickPwr = qMin(rightMag, 1.0) * slot.kickPower;
            if (kickPwr < 0.1) kickPwr = slot.kickPower * 0.3;
        }
        if (slot.gpBtnRB && !slot.gpBtnRBPrev) {
            slot.dribble = !slot.dribble;
            if (si == m_selectedSlot) emit dribbleChanged();
        }
        doDribble = slot.dribble;
    }

    slot.currentVx = slot.cmdGlobalVx;
    slot.currentVy = slot.cmdGlobalVy;
    slot.currentVr = cmdVr;

    double sendVx = cmdLocalVx;
    double sendVy = cmdLocalVy;
    double sendMag = qSqrt(sendVx * sendVx + sendVy * sendVy);
    if (sendMag < 0.15) {
        sendVx = 0;
        sendVy = 0;
    }

    if (doDribble && slot.gpRightTrigger > 0.5 && cmdMag > 0.15) {
        double moveDir = qAtan2(slot.cmdGlobalVy, slot.cmdGlobalVx);
        double faceAngle = slot.dgPullBall ? (moveDir + M_PI) : moveDir;
        double dgAngleDiff = faceAngle - robotAngle;
        while (dgAngleDiff > M_PI) dgAngleDiff -= 2 * M_PI;
        while (dgAngleDiff < -M_PI) dgAngleDiff += 2 * M_PI;

        if (qAbs(dgAngleDiff) > qDegreesToRadians(slot.dgAngleThresh)) {
            double omega = (dgAngleDiff > 0 ? 1.0 : -1.0) * slot.dgRotSpeed;
            double me2centerX = slot.dgRotCenterX;
            double me2centerY = slot.dgRotCenterY;
            double radius = qSqrt(me2centerX * me2centerX + me2centerY * me2centerY);
            double tangDir = qAtan2(-me2centerX, me2centerY);
            double targetVelMod = radius * omega;
            sendVx = targetVelMod * qCos(tangDir) / 1000.0;
            sendVy = targetVelMod * qSin(tangDir) / 1000.0;
            cmdVr = omega;
        } else {
            cmdVr = slot.rotKp * dgAngleDiff - slot.rotKd * actualRotVel;
            cmdVr = clamp(cmdVr, -slot.maxRotSpeed, slot.maxRotSpeed);
        }
    }

    sendSlotCmd(si, static_cast<float>(sendVx * 1000.0), static_cast<float>(sendVy * 1000.0),
                static_cast<float>(cmdVr), doKick, static_cast<float>(kickPwr * 1000.0),
                doDribble);

    if (si == m_selectedSlot) emit velocityChanged();
}

void ManualController::initSDL() {
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
    SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1");
    if (SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) == 0) {
        m_sdlInitialized = true;
    }
}

void ManualController::openGamepad(int deviceIndex, int slotIndex) {
    closeGamepadSlot(slotIndex);
    m_slots[slotIndex].gamepad = SDL_GameControllerOpen(deviceIndex);
    if (m_slots[slotIndex].gamepad) {
        m_slots[slotIndex].connected = true;
        emit gamepadConnectedChanged();
        emit slotsChanged();
    }
}

void ManualController::closeGamepadSlot(int slotIndex) {
    auto& slot = m_slots[slotIndex];
    if (slot.gamepad) {
        SDL_GameControllerClose(slot.gamepad);
        slot.gamepad = nullptr;
    }
    if (slot.connected) {
        slot.connected = false;
        emit gamepadConnectedChanged();
        emit slotsChanged();
    }
}

double ManualController::applyDeadzone(short raw, short deadzone) {
    int r = raw;
    if (qAbs(r) < deadzone) return 0.0;
    double normalized = static_cast<double>(r) / 32767.0;
    double dz = static_cast<double>(deadzone) / 32767.0;
    double sign = (r > 0) ? 1.0 : -1.0;
    return sign * (qAbs(normalized) - dz) / (1.0 - dz);
}

void ManualController::pollAllGamepads() {
    if (!m_sdlInitialized) return;
    SDL_GameControllerUpdate();

    for (int s = 0; s < MAX_SLOTS; ++s) {
        if (m_slots[s].connected && m_slots[s].gamepad) {
            if (!SDL_GameControllerGetAttached(m_slots[s].gamepad)) {
                closeGamepadSlot(s);
            }
        }
    }

    QSet<SDL_JoystickID> openIds;
    for (int s = 0; s < MAX_SLOTS; ++s) {
        if (m_slots[s].connected && m_slots[s].gamepad) {
            SDL_Joystick* joy = SDL_GameControllerGetJoystick(m_slots[s].gamepad);
            if (joy) openIds.insert(SDL_JoystickInstanceID(joy));
        }
    }

    for (int i = 0; i < SDL_NumJoysticks(); ++i) {
        if (!SDL_IsGameController(i)) continue;
        SDL_JoystickID instId = SDL_JoystickGetDeviceInstanceID(i);
        if (openIds.contains(instId)) continue;

        int freeSlot = -1;
        for (int s = 0; s < MAX_SLOTS; ++s) {
            if (!m_slots[s].connected) { freeSlot = s; break; }
        }
        if (freeSlot >= 0) openGamepad(i, freeSlot);
    }

    for (int s = 0; s < MAX_SLOTS; ++s) {
        if (!m_slots[s].connected || !m_slots[s].gamepad) continue;
        SDL_Joystick* joy = SDL_GameControllerGetJoystick(m_slots[s].gamepad);
        if (!joy) continue;
        if (m_slots[s].gamepadLayout == 0) {
            pollGamepadXpad(s, joy);
        } else {
            pollGamepadXone(s, joy);
        }
    }
}

void ManualController::pollGamepadXpad(int si, SDL_Joystick* joy) {
    auto& slot = m_slots[si];
    SDL_GameController* gc = slot.gamepad;
    double leftX = applyDeadzone(SDL_GameControllerGetAxis(gc, SDL_CONTROLLER_AXIS_LEFTX));
    double leftY = applyDeadzone(SDL_GameControllerGetAxis(gc, SDL_CONTROLLER_AXIS_LEFTY));

    short rawRX = SDL_JoystickGetAxis(joy, 2);
    short rawRY = SDL_JoystickGetAxis(joy, 3);
    double rightX = applyDeadzone(rawRX);
    double rightY = applyDeadzone(rawRY);

    slot.gpBtnA = SDL_GameControllerGetButton(gc, SDL_CONTROLLER_BUTTON_A);
    slot.gpBtnB = SDL_GameControllerGetButton(gc, SDL_CONTROLLER_BUTTON_B);
    slot.gpBtnX = SDL_GameControllerGetButton(gc, SDL_CONTROLLER_BUTTON_X);
    slot.gpBtnY = SDL_GameControllerGetButton(gc, SDL_CONTROLLER_BUTTON_Y);
    bool btnLB = SDL_JoystickGetButton(joy, 6);
    bool btnRB = SDL_JoystickGetButton(joy, 7);
    bool btnBack = SDL_JoystickGetButton(joy, 4);
    bool btnStart = SDL_JoystickGetButton(joy, 5);
    bool btnLStick = SDL_JoystickGetButton(joy, 13);

    if (btnLStick && !slot.gpBtnLStick) {
        slot.savedMaxSpeed = slot.maxSpeed;
        slot.savedAcceleration = slot.acceleration;
        slot.maxSpeed = 3.0;
        slot.acceleration = 6.0;
    } else if (!btnLStick && slot.gpBtnLStick) {
        slot.maxSpeed = slot.savedMaxSpeed;
        slot.acceleration = slot.savedAcceleration;
    }
    slot.gpBtnLStick = btnLStick;

    slot.gpBtnLB = btnLB;
    slot.gpBtnRBPrev = slot.gpBtnRB;
    slot.gpBtnRB = btnRB;
    slot.gpBtnBack = btnBack;
    slot.gpBtnStart = btnStart;

    auto dz = [](double v, double d) -> double {
        return (qAbs(v) < d) ? 0.0 : v;
    };
    slot.gpLeftX = dz(leftX, 0.15);
    slot.gpLeftY = dz(-leftY, 0.15);
    slot.gpRightX = dz(rightX, 0.15);
    slot.gpRightY = dz(-rightY, 0.15);
    short rawRT = SDL_JoystickGetAxis(joy, 4);
    slot.gpRightTrigger = qMin(1.0, static_cast<double>(qMax(rawRT, (short)0)) / 32767.0);
}

void ManualController::pollGamepadXone(int si, SDL_Joystick* joy) {
    auto& slot = m_slots[si];
    double leftX = applyDeadzone(SDL_JoystickGetAxis(joy, 0));
    double leftY = applyDeadzone(SDL_JoystickGetAxis(joy, 1));
    double rightX = applyDeadzone(SDL_JoystickGetAxis(joy, 3));
    double rightY = applyDeadzone(SDL_JoystickGetAxis(joy, 4));

    slot.gpBtnA = SDL_JoystickGetButton(joy, 0);
    slot.gpBtnB = SDL_JoystickGetButton(joy, 1);
    slot.gpBtnX = SDL_JoystickGetButton(joy, 2);
    slot.gpBtnY = SDL_JoystickGetButton(joy, 3);
    bool btnLB = SDL_JoystickGetButton(joy, 4);
    bool btnRB = SDL_JoystickGetButton(joy, 5);
    bool btnBack = SDL_JoystickGetButton(joy, 6);
    bool btnStart = SDL_JoystickGetButton(joy, 7);
    bool btnLStick = SDL_JoystickGetButton(joy, 9);

    if (btnLStick && !slot.gpBtnLStick) {
        slot.savedMaxSpeed = slot.maxSpeed;
        slot.savedAcceleration = slot.acceleration;
        slot.maxSpeed = 3.0;
        slot.acceleration = 6.0;
    } else if (!btnLStick && slot.gpBtnLStick) {
        slot.maxSpeed = slot.savedMaxSpeed;
        slot.acceleration = slot.savedAcceleration;
    }
    slot.gpBtnLStick = btnLStick;

    slot.gpBtnLB = btnLB;
    slot.gpBtnRBPrev = slot.gpBtnRB;
    slot.gpBtnRB = btnRB;
    slot.gpBtnBack = btnBack;
    slot.gpBtnStart = btnStart;

    auto dz = [](double v, double d) -> double {
        return (qAbs(v) < d) ? 0.0 : v;
    };
    slot.gpLeftX = dz(leftX, 0.15);
    slot.gpLeftY = dz(-leftY, 0.15);
    slot.gpRightX = dz(rightX, 0.15);
    slot.gpRightY = dz(-rightY, 0.15);
    short rawRT = SDL_JoystickGetAxis(joy, 5);
    slot.gpRightTrigger = qMin(1.0, static_cast<double>(qMax(rawRT, (short)0)) / 32767.0);
}

void ManualController::updateStatus() {
    if (!m_active) {
        m_statusText = QStringLiteral("Manual: OFF");
    } else {
        int cnt = slotCount();
        if (m_useGamepad) {
            m_statusText = QStringLiteral("Manual: %1 %2 gamepad(s) ACTIVE")
                .arg(m_team == 0 ? "Blue" : "Yellow")
                .arg(cnt);
        } else {
            m_statusText = QStringLiteral("Manual: %1 #%2 [Keyboard] ACTIVE")
                .arg(m_team == 0 ? "Blue" : "Yellow")
                .arg(m_slots[m_selectedSlot].robotId);
        }
    }
    emit statusChanged();
}
