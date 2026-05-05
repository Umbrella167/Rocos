#include "manualcontroller.h"
#include "globaldata.h"
#include "networkinterfaces.h"
#include "parammanager.h"
#include <QtMath>
#include <QCoreApplication>
#include <QKeyEvent>
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
    auto* zpm = ZSS::ZParamManager::instance();
    zpm->loadParam(m_robotId, "Manual/robotId", 0);
    zpm->loadParam(m_maxSpeed, "Manual/maxSpeed", 3.0);
    zpm->loadParam(m_slowSpeed, "Manual/slowSpeed", 1.0);
    zpm->loadParam(m_maxRotSpeed, "Manual/maxRotSpeed", 10.0);
    zpm->loadParam(m_kickPower, "Manual/kickPower", 5.0);
    zpm->loadParam(m_acceleration, "Manual/acceleration", 6.0);
    zpm->loadParam(m_deceleration, "Manual/deceleration", 12.0);
    zpm->loadParam(m_rotKp, "Manual/rotKp", 8.0);
    zpm->loadParam(m_rotKd, "Manual/rotKd", 1.5);
    updateStatus();
}

ManualController::~ManualController() {
    QCoreApplication::instance()->removeEventFilter(this);
    closeGamepad();
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
void ManualController::setDribbleActive(bool active) { m_dribble = active; emit dribbleChanged(); }

void ManualController::setUseGamepad(bool use) {
    if (m_useGamepad == use) return;
    m_useGamepad = use;
    if (use && !m_gamepad) {
        for (int i = 0; i < SDL_NumJoysticks(); ++i) {
            if (SDL_IsGameController(i)) {
                openGamepad(i);
                break;
            }
        }
    }
    if (!use) {
        m_kick = false;
        m_dribble = false;
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
        m_dribble = false;
        m_kick = false;
        m_emergencyStop = false;
        m_cmdGlobalVx = 0;
        m_cmdGlobalVy = 0;
        emit dribbleChanged();
    } else {
        m_timer->stop();
        m_keyState.clear();
        m_cmdGlobalVx = 0;
        m_cmdGlobalVy = 0;
        m_currentVx = m_currentVy = m_currentVr = 0;
        emit velocityChanged();
    }
    updateStatus();
    emit activeChanged();
}

void ManualController::setRobotId(int id) { if (m_robotId != id) { m_robotId = id; ZSS::ZParamManager::instance()->changeParam("Manual/robotId", id); emit robotIdChanged(); } }
void ManualController::setTeam(int team) { if (m_team != team) { m_team = team; emit teamChanged(); } }
void ManualController::setMaxSpeed(qreal v) { if (qFuzzyCompare(m_maxSpeed, v)) return; m_maxSpeed = v; ZSS::ZParamManager::instance()->changeParam("Manual/maxSpeed", v); emit maxSpeedChanged(); }
void ManualController::setSlowSpeed(qreal v) { if (qFuzzyCompare(m_slowSpeed, v)) return; m_slowSpeed = v; ZSS::ZParamManager::instance()->changeParam("Manual/slowSpeed", v); emit slowSpeedChanged(); }
void ManualController::setMaxRotSpeed(qreal v) { if (qFuzzyCompare(m_maxRotSpeed, v)) return; m_maxRotSpeed = v; ZSS::ZParamManager::instance()->changeParam("Manual/maxRotSpeed", v); emit maxRotSpeedChanged(); }
void ManualController::setKickPower(qreal v) { if (qFuzzyCompare(m_kickPower, v)) return; m_kickPower = v; ZSS::ZParamManager::instance()->changeParam("Manual/kickPower", v); emit kickPowerChanged(); }
void ManualController::setAcceleration(qreal v) { if (qFuzzyCompare(m_acceleration, v)) return; m_acceleration = v; ZSS::ZParamManager::instance()->changeParam("Manual/acceleration", v); emit accelerationChanged(); }
void ManualController::setDeceleration(qreal v) { if (qFuzzyCompare(m_deceleration, v)) return; m_deceleration = v; ZSS::ZParamManager::instance()->changeParam("Manual/deceleration", v); emit decelerationChanged(); }
void ManualController::setRotKp(qreal v) { if (qFuzzyCompare(m_rotKp, v)) return; m_rotKp = v; ZSS::ZParamManager::instance()->changeParam("Manual/rotKp", v); emit rotKpChanged(); }
void ManualController::setRotKd(qreal v) { if (qFuzzyCompare(m_rotKd, v)) return; m_rotKd = v; ZSS::ZParamManager::instance()->changeParam("Manual/rotKd", v); emit rotKdChanged(); }

void ManualController::sendGamepadCmd(float vx, float vy, float vr,
                                       bool kick, float kickPower, bool dribble) {
    if (m_gamepadCmdFd < 0) return;
    const int BTN_COUNT = 16;
    const int PKT_SIZE = 35;
    uint8_t buf[PKT_SIZE];
    std::memset(buf, 0, PKT_SIZE);

    if (m_gamepad) {
        SDL_Joystick* joy = SDL_GameControllerGetJoystick(m_gamepad);
        if (joy) {
            for (int i = 0; i < BTN_COUNT; ++i) {
                buf[i] = SDL_JoystickGetButton(joy, i) ? 1 : 0;
            }
        }
    }

    buf[BTN_COUNT] = dribble ? 1 : 0;
    buf[BTN_COUNT + 1] = static_cast<uint8_t>(m_robotId);

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
        pollGamepad();
    }

    auto& maintain = GlobalData::instance()->maintain[0];

    int robotIdx = -1;
    for (int j = 0; j < maintain.robotSize[m_team]; j++) {
        if (maintain.robot[m_team][j].id == static_cast<unsigned short>(m_robotId)) {
            robotIdx = j;
            break;
        }
    }

    if (robotIdx < 0) return;

    auto& robot = maintain.robot[m_team][robotIdx];
    double robotAngle = robot.angle;
    double actualRotVel = robot.rotateVel;

    if (m_emergencyStop) {
        m_cmdGlobalVx = 0;
        m_cmdGlobalVy = 0;
        m_currentVx = m_currentVy = m_currentVr = 0;
        emit velocityChanged();
        sendGamepadCmd(0, 0, 0, false, 0, false);
        return;
    }

    bool skillActive = m_useGamepad && (m_gpBtnA || m_gpBtnB || m_gpBtnX || m_gpBtnY);
    if (skillActive) {
        m_cmdGlobalVx = 0;
        m_cmdGlobalVy = 0;
        m_currentVx = m_currentVy = m_currentVr = 0;
        emit velocityChanged();
        sendGamepadCmd(0, 0, 0, false, 0, false);
        return;
    }

    double targetVx = 0, targetVy = 0;
    double speed = m_maxSpeed;

    if (m_useGamepad) {
        targetVx = m_gpLeftX * speed;
        targetVy = m_gpLeftY * speed;
    } else {
        if (m_keyState.value(Qt::Key_Control, false)) speed = m_slowSpeed;
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
    if (m_useGamepad) {
        double rightMag = qSqrt(m_gpRightX * m_gpRightX + m_gpRightY * m_gpRightY);
        if (rightMag > 0.15) {
            double targetAngle = qAtan2(m_gpRightY, m_gpRightX);
            double angleDiff = targetAngle - robotAngle;
            while (angleDiff > M_PI) angleDiff -= 2 * M_PI;
            while (angleDiff < -M_PI) angleDiff += 2 * M_PI;

            cmdVr = m_rotKp * angleDiff - m_rotKd * actualRotVel;
            cmdVr = clamp(cmdVr, -m_maxRotSpeed, m_maxRotSpeed);

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

        cmdVr = m_rotKp * angleDiff - m_rotKd * actualRotVel;
        cmdVr = clamp(cmdVr, -m_maxRotSpeed, m_maxRotSpeed);

        if (qAbs(angleDiff) < qDegreesToRadians(0.5)) cmdVr = 0;
    }

    if (targetMag < 0.01) {
        m_cmdGlobalVx = moveTowards(m_cmdGlobalVx, 0, m_deceleration * DT);
        m_cmdGlobalVy = moveTowards(m_cmdGlobalVy, 0, m_deceleration * DT);
    } else {
        bool sameDirX = (m_cmdGlobalVx == 0) || (m_cmdGlobalVx > 0) == (targetVx > 0);
        bool sameDirY = (m_cmdGlobalVy == 0) || (m_cmdGlobalVy > 0) == (targetVy > 0);
        if (sameDirX) {
            m_cmdGlobalVx = moveTowards(m_cmdGlobalVx, targetVx, m_acceleration * DT);
        } else {
            m_cmdGlobalVx = moveTowards(m_cmdGlobalVx, 0, m_deceleration * 2 * DT);
        }
        if (sameDirY) {
            m_cmdGlobalVy = moveTowards(m_cmdGlobalVy, targetVy, m_acceleration * DT);
        } else {
            m_cmdGlobalVy = moveTowards(m_cmdGlobalVy, 0, m_deceleration * 2 * DT);
        }
    }

    double cmdMag = qSqrt(m_cmdGlobalVx * m_cmdGlobalVx + m_cmdGlobalVy * m_cmdGlobalVy);
    if (cmdMag > m_maxSpeed * 1.5) {
        m_cmdGlobalVx *= m_maxSpeed * 1.5 / cmdMag;
        m_cmdGlobalVy *= m_maxSpeed * 1.5 / cmdMag;
    }

    double cosA = qCos(robotAngle);
    double sinA = qSin(robotAngle);
    double cmdLocalVx = m_cmdGlobalVx * cosA + m_cmdGlobalVy * sinA;
    double cmdLocalVy = -m_cmdGlobalVx * sinA + m_cmdGlobalVy * cosA;

    bool doKick = m_kick;
    double kickPwr = m_kickPower;
    bool doDribble = m_dribble;

    if (m_useGamepad) {
        if (m_gpBtnLB) {
            doKick = true;
            double rightMag = qSqrt(m_gpRightX * m_gpRightX + m_gpRightY * m_gpRightY);
            kickPwr = qMin(rightMag, 1.0) * m_kickPower;
            if (kickPwr < 0.1) kickPwr = m_kickPower * 0.3;
        }
        if (m_gpBtnRB && !m_gpBtnRBPrev) {
            m_dribble = !m_dribble;
            emit dribbleChanged();
        }
        doDribble = m_dribble;
    }

    m_currentVx = m_cmdGlobalVx;
    m_currentVy = m_cmdGlobalVy;
    m_currentVr = cmdVr;
    emit velocityChanged();

    double sendVx = cmdLocalVx;
    double sendVy = cmdLocalVy;
    double sendMag = qSqrt(sendVx * sendVx + sendVy * sendVy);
    if (sendMag < 0.15) {
        sendVx = 0;
        sendVy = 0;
    }

    sendGamepadCmd(static_cast<float>(sendVx * 1000.0), static_cast<float>(sendVy * 1000.0),
                   static_cast<float>(cmdVr), doKick, static_cast<float>(kickPwr * 1000.0),
                   doDribble);
}

void ManualController::initSDL() {
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
    SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, "1");
    if (SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) == 0) {
        m_sdlInitialized = true;
    }
}

void ManualController::openGamepad(int deviceIndex) {
    closeGamepad();
    m_gamepad = SDL_GameControllerOpen(deviceIndex);
    if (m_gamepad) {
        emit gamepadConnectedChanged();
    }
}

void ManualController::closeGamepad() {
    if (m_gamepad) {
        SDL_GameControllerClose(m_gamepad);
        m_gamepad = nullptr;
        emit gamepadConnectedChanged();
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

void ManualController::pollGamepad() {
    if (!m_sdlInitialized) return;

    SDL_GameControllerUpdate();

    if (!m_gamepad && m_useGamepad) {
        for (int i = 0; i < SDL_NumJoysticks(); ++i) {
            if (SDL_IsGameController(i)) {
                openGamepad(i);
                break;
            }
        }
    }
    if (m_gamepad && !SDL_GameControllerGetAttached(m_gamepad)) {
        closeGamepad();
    }

    if (!m_gamepad) return;

    SDL_Joystick* joy = SDL_GameControllerGetJoystick(m_gamepad);

    double leftX = applyDeadzone(SDL_GameControllerGetAxis(m_gamepad, SDL_CONTROLLER_AXIS_LEFTX));
    double leftY = applyDeadzone(SDL_GameControllerGetAxis(m_gamepad, SDL_CONTROLLER_AXIS_LEFTY));

    short rawRX = joy ? SDL_JoystickGetAxis(joy, 2) : 0;
    short rawRY = joy ? SDL_JoystickGetAxis(joy, 3) : 0;
    double rightX = applyDeadzone(rawRX);
    double rightY = applyDeadzone(rawRY);

    m_gpBtnA = SDL_GameControllerGetButton(m_gamepad, SDL_CONTROLLER_BUTTON_A);
    m_gpBtnB = SDL_GameControllerGetButton(m_gamepad, SDL_CONTROLLER_BUTTON_B);
    m_gpBtnX = SDL_GameControllerGetButton(m_gamepad, SDL_CONTROLLER_BUTTON_X);
    m_gpBtnY = SDL_GameControllerGetButton(m_gamepad, SDL_CONTROLLER_BUTTON_Y);
    bool btnLB = joy ? SDL_JoystickGetButton(joy, 6) : false;
    bool btnRB = joy ? SDL_JoystickGetButton(joy, 7) : false;
    bool btnBack = joy ? SDL_JoystickGetButton(joy, 4) : false;
    bool btnStart = joy ? SDL_JoystickGetButton(joy, 5) : false;

    bool btnLStick = joy ? SDL_JoystickGetButton(joy, 13) : false;
    if (btnLStick && !m_gpBtnLStick) {
        m_savedMaxSpeed = m_maxSpeed;
        m_savedAcceleration = m_acceleration;
        setMaxSpeed(3.0);
        setAcceleration(6.0);
    } else if (!btnLStick && m_gpBtnLStick) {
        setMaxSpeed(m_savedMaxSpeed);
        setAcceleration(m_savedAcceleration);
    }
    m_gpBtnLStick = btnLStick;

    m_gpBtnLB = btnLB;
    m_gpBtnRBPrev = m_gpBtnRB;
    m_gpBtnRB = btnRB;
    m_gpBtnBack = btnBack;
    m_gpBtnStart = btnStart;
    m_gpLeftX = leftX;
    m_gpLeftY = -leftY;
    m_gpRightX = rightX;
    m_gpRightY = -rightY;
}

void ManualController::updateStatus() {
    if (!m_active) {
        m_statusText = QStringLiteral("Manual: OFF");
    } else {
        QString mode = m_useGamepad ? "Gamepad" : "Keyboard";
        m_statusText = QStringLiteral("Manual: %1 #%2 [%3] ACTIVE")
            .arg(m_team == 0 ? "Blue" : "Yellow")
            .arg(m_robotId)
            .arg(mode);
    }
    emit statusChanged();
}
