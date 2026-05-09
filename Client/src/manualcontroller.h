#ifndef MANUALCONTROLLER_H
#define MANUALCONTROLLER_H

#include <QObject>
#include <QMap>
#include <QVector2D>
#include <QTimer>
#include <QElapsedTimer>
#include "staticparams.h"

struct _SDL_Joystick;
typedef struct _SDL_Joystick SDL_Joystick;

struct _SDL_GameController;
typedef struct _SDL_GameController SDL_GameController;

struct GamepadSlot {
    SDL_GameController* gamepad = nullptr;
    bool connected = false;

    int robotId = 1;
    int gamepadLayout = 0;

    qreal maxSpeed = 1.2;
    qreal slowSpeed = 1.0;
    qreal maxRotSpeed = 10.0;
    qreal kickPower = 5.0;
    qreal acceleration = 1.6;
    qreal deceleration = 12.0;
    qreal rotKp = 6.5;
    qreal rotKd = 0;

    qreal dgRotSpeed = 4.5;
    qreal dgAngleThresh = 20.0;
    qreal dgRotCenterX = 120.0;
    qreal dgRotCenterY = 0.0;
    bool autoFace = false;
    qreal brakeRatio = 0.5;
    qreal brakeThresh = 0.4;
    bool dgPullBall = true;

    double gpLeftX = 0, gpLeftY = 0;
    double gpRightX = 0, gpRightY = 0;
    bool gpBtnA = false, gpBtnB = false, gpBtnX = false, gpBtnY = false;
    bool gpBtnLB = false, gpBtnRB = false, gpBtnRBPrev = false;
    bool gpBtnBack = false, gpBtnStart = false, gpBtnLStick = false, gpBtnLStickPrev = false;
    double gpRightTrigger = 0;

    bool braking = false;
    double brakeVx = 0, brakeVy = 0;
    double prevTargetMag = 0;

    double cmdGlobalVx = 0, cmdGlobalVy = 0;
    qreal currentVx = 0, currentVy = 0, currentVr = 0;
    bool dribble = false;
    qreal savedMaxSpeed = 3.0;
    qreal savedAcceleration = 6.0;
};

class ManualController : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(int team READ team WRITE setTeam NOTIFY teamChanged)
    Q_PROPERTY(bool useGamepad READ useGamepad WRITE setUseGamepad NOTIFY useGamepadChanged)
    Q_PROPERTY(int selectedSlot READ selectedSlot WRITE setSelectedSlot NOTIFY selectedSlotChanged)
    Q_PROPERTY(bool gamepadConnected READ gamepadConnected NOTIFY gamepadConnectedChanged)

    Q_PROPERTY(int robotId READ robotId WRITE setRobotId NOTIFY robotIdChanged)
    Q_PROPERTY(qreal maxSpeed READ maxSpeed WRITE setMaxSpeed NOTIFY maxSpeedChanged)
    Q_PROPERTY(qreal slowSpeed READ slowSpeed WRITE setSlowSpeed NOTIFY slowSpeedChanged)
    Q_PROPERTY(qreal maxRotSpeed READ maxRotSpeed WRITE setMaxRotSpeed NOTIFY maxRotSpeedChanged)
    Q_PROPERTY(qreal kickPower READ kickPower WRITE setKickPower NOTIFY kickPowerChanged)
    Q_PROPERTY(qreal acceleration READ acceleration WRITE setAcceleration NOTIFY accelerationChanged)
    Q_PROPERTY(qreal deceleration READ deceleration WRITE setDeceleration NOTIFY decelerationChanged)
    Q_PROPERTY(qreal rotKp READ rotKp WRITE setRotKp NOTIFY rotKpChanged)
    Q_PROPERTY(qreal rotKd READ rotKd WRITE setRotKd NOTIFY rotKdChanged)
    Q_PROPERTY(qreal dgRotSpeed READ dgRotSpeed WRITE setDgRotSpeed NOTIFY dgRotSpeedChanged)
    Q_PROPERTY(qreal dgAngleThresh READ dgAngleThresh WRITE setDgAngleThresh NOTIFY dgAngleThreshChanged)
    Q_PROPERTY(qreal dgRotCenterX READ dgRotCenterX WRITE setDgRotCenterX NOTIFY dgRotCenterXChanged)
    Q_PROPERTY(qreal dgRotCenterY READ dgRotCenterY WRITE setDgRotCenterY NOTIFY dgRotCenterYChanged)
    Q_PROPERTY(bool autoFace READ autoFace WRITE setAutoFace NOTIFY autoFaceChanged)
    Q_PROPERTY(bool dgPullBall READ dgPullBall WRITE setDgPullBall NOTIFY dgPullBallChanged)
    Q_PROPERTY(int gamepadLayout READ gamepadLayout WRITE setGamepadLayout NOTIFY gamepadLayoutChanged)
    Q_PROPERTY(qreal brakeRatio READ brakeRatio WRITE setBrakeRatio NOTIFY brakeRatioChanged)
    Q_PROPERTY(qreal brakeThresh READ brakeThresh WRITE setBrakeThresh NOTIFY brakeThreshChanged)
    Q_PROPERTY(qreal currentVx READ currentVx NOTIFY velocityChanged)
    Q_PROPERTY(qreal currentVy READ currentVy NOTIFY velocityChanged)
    Q_PROPERTY(qreal currentVr READ currentVr NOTIFY velocityChanged)
    Q_PROPERTY(bool dribbleActive READ dribbleActive NOTIFY dribbleChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)

public:
    explicit ManualController(QObject *parent = nullptr);
    ~ManualController();

    bool active() const { return m_active; }
    int team() const { return m_team; }
    bool useGamepad() const { return m_useGamepad; }
    int selectedSlot() const { return m_selectedSlot; }
    bool gamepadConnected() const;
    QString statusText() const { return m_statusText; }

    int robotId() const { return m_slots[m_selectedSlot].robotId; }
    qreal maxSpeed() const { return m_slots[m_selectedSlot].maxSpeed; }
    qreal slowSpeed() const { return m_slots[m_selectedSlot].slowSpeed; }
    qreal maxRotSpeed() const { return m_slots[m_selectedSlot].maxRotSpeed; }
    qreal kickPower() const { return m_slots[m_selectedSlot].kickPower; }
    qreal acceleration() const { return m_slots[m_selectedSlot].acceleration; }
    qreal deceleration() const { return m_slots[m_selectedSlot].deceleration; }
    qreal rotKp() const { return m_slots[m_selectedSlot].rotKp; }
    qreal rotKd() const { return m_slots[m_selectedSlot].rotKd; }
    qreal dgRotSpeed() const { return m_slots[m_selectedSlot].dgRotSpeed; }
    qreal dgAngleThresh() const { return m_slots[m_selectedSlot].dgAngleThresh; }
    qreal dgRotCenterX() const { return m_slots[m_selectedSlot].dgRotCenterX; }
    qreal dgRotCenterY() const { return m_slots[m_selectedSlot].dgRotCenterY; }
    bool autoFace() const { return m_slots[m_selectedSlot].autoFace; }
    qreal brakeRatio() const { return m_slots[m_selectedSlot].brakeRatio; }
    qreal brakeThresh() const { return m_slots[m_selectedSlot].brakeThresh; }
    bool dgPullBall() const { return m_slots[m_selectedSlot].dgPullBall; }
    int gamepadLayout() const { return m_slots[m_selectedSlot].gamepadLayout; }
    qreal currentVx() const { return m_slots[m_selectedSlot].currentVx; }
    qreal currentVy() const { return m_slots[m_selectedSlot].currentVy; }
    qreal currentVr() const { return m_slots[m_selectedSlot].currentVr; }
    bool dribbleActive() const { return m_slots[m_selectedSlot].dribble; }

    static bool isManualControlActive() { return s_instance && s_instance->m_active; }

    Q_INVOKABLE void setMouseFieldPos(qreal x, qreal y);
    Q_INVOKABLE void setMouseActive(bool active);
    Q_INVOKABLE void setKickActive(bool active);
    Q_INVOKABLE void setDribbleActive(bool active);
    Q_INVOKABLE void setUseGamepad(bool use);

    Q_INVOKABLE bool slotConnected(int slot) const;
    Q_INVOKABLE int slotRobotId(int slot) const;
    Q_INVOKABLE int slotLayout(int slot) const;
    Q_INVOKABLE int slotCount() const;

public slots:
    void setActive(bool active);
    void setTeam(int team);
    void setSelectedSlot(int slot);
    void setRobotId(int id);
    void setMaxSpeed(qreal speed);
    void setSlowSpeed(qreal speed);
    void setMaxRotSpeed(qreal speed);
    void setKickPower(qreal power);
    void setAcceleration(qreal v);
    void setDeceleration(qreal v);
    void setRotKp(qreal v);
    void setRotKd(qreal v);
    void setDgRotSpeed(qreal v);
    void setDgAngleThresh(qreal v);
    void setDgRotCenterX(qreal v);
    void setDgRotCenterY(qreal v);
    void setAutoFace(bool v);
    void setBrakeRatio(qreal v);
    void setBrakeThresh(qreal v);
    void setDgPullBall(bool v);
    void setGamepadLayout(int v);

signals:
    void activeChanged();
    void teamChanged();
    void selectedSlotChanged();
    void robotIdChanged();
    void maxSpeedChanged();
    void slowSpeedChanged();
    void maxRotSpeedChanged();
    void kickPowerChanged();
    void accelerationChanged();
    void decelerationChanged();
    void rotKpChanged();
    void rotKdChanged();
    void dgRotSpeedChanged();
    void dgAngleThreshChanged();
    void dgRotCenterXChanged();
    void dgRotCenterYChanged();
    void autoFaceChanged();
    void brakeRatioChanged();
    void brakeThreshChanged();
    void dgPullBallChanged();
    void gamepadLayoutChanged();
    void velocityChanged();
    void dribbleChanged();
    void statusChanged();
    void useGamepadChanged();
    void gamepadConnectedChanged();
    void slotsChanged();

protected:
    bool eventFilter(QObject *obj, QEvent *event) override;

private:
    void processKey(int key, bool pressed);
    void tick();
    void tickSlot(int si);
    void updateStatus();
    void sendSlotCmd(int si, float vx, float vy, float vr, bool kick, float kickPower, bool dribble);
    void initSDL();
    void pollAllGamepads();
    void pollGamepadXpad(int si, SDL_Joystick* joy);
    void pollGamepadXone(int si, SDL_Joystick* joy);
    void openGamepad(int deviceIndex, int slotIndex);
    void closeGamepadSlot(int slotIndex);
    void loadSlotParams(int si);
    static double applyDeadzone(short raw, short deadzone = 3200);
    static double clamp(double val, double lo, double hi) {
        return val < lo ? lo : (val > hi ? hi : val);
    }
    static double moveTowards(double current, double target, double maxDelta) {
        if (qAbs(target - current) <= maxDelta) return target;
        return current + (target > current ? maxDelta : -maxDelta);
    }
    QString slotParamKey(int si, const QString& key) const;

    bool m_active = false;
    int m_team = 0;
    bool m_useGamepad = false;
    bool m_sdlInitialized = false;
    int m_selectedSlot = 0;
    int m_gamepadCmdFd = -1;

    static constexpr int MAX_SLOTS = 8;
    GamepadSlot m_slots[MAX_SLOTS];

    QMap<int, bool> m_keyState;
    QVector2D m_mouseFieldPos;
    bool m_mouseActive = false;
    bool m_kick = false;
    bool m_emergencyStop = false;

    QTimer *m_timer;
    QElapsedTimer m_lastMouseTime;
    QString m_statusText;

    static ManualController* s_instance;

    friend class Field;

    static constexpr int TICK_INTERVAL = 16;
    static constexpr double DT = TICK_INTERVAL / 1000.0;
};

#endif // MANUALCONTROLLER_H
