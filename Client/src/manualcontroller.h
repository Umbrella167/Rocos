#ifndef MANUALCONTROLLER_H
#define MANUALCONTROLLER_H

#include <QObject>
#include <QMap>
#include <QVector2D>
#include <QTimer>
#include <QElapsedTimer>
#include "staticparams.h"

struct _SDL_GameController;
typedef struct _SDL_GameController SDL_GameController;

class ManualController : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(int robotId READ robotId WRITE setRobotId NOTIFY robotIdChanged)
    Q_PROPERTY(int team READ team WRITE setTeam NOTIFY teamChanged)
    Q_PROPERTY(qreal maxSpeed READ maxSpeed WRITE setMaxSpeed NOTIFY maxSpeedChanged)
    Q_PROPERTY(qreal slowSpeed READ slowSpeed WRITE setSlowSpeed NOTIFY slowSpeedChanged)
    Q_PROPERTY(qreal maxRotSpeed READ maxRotSpeed WRITE setMaxRotSpeed NOTIFY maxRotSpeedChanged)
    Q_PROPERTY(qreal kickPower READ kickPower WRITE setKickPower NOTIFY kickPowerChanged)
    Q_PROPERTY(qreal acceleration READ acceleration WRITE setAcceleration NOTIFY accelerationChanged)
    Q_PROPERTY(qreal deceleration READ deceleration WRITE setDeceleration NOTIFY decelerationChanged)
    Q_PROPERTY(qreal rotKp READ rotKp WRITE setRotKp NOTIFY rotKpChanged)
    Q_PROPERTY(qreal rotKd READ rotKd WRITE setRotKd NOTIFY rotKdChanged)
    Q_PROPERTY(qreal currentVx READ currentVx NOTIFY velocityChanged)
    Q_PROPERTY(qreal currentVy READ currentVy NOTIFY velocityChanged)
    Q_PROPERTY(qreal currentVr READ currentVr NOTIFY velocityChanged)
    Q_PROPERTY(bool dribbleActive READ dribbleActive NOTIFY dribbleChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
    Q_PROPERTY(bool useGamepad READ useGamepad WRITE setUseGamepad NOTIFY useGamepadChanged)
    Q_PROPERTY(bool gamepadConnected READ gamepadConnected NOTIFY gamepadConnectedChanged)

public:
    explicit ManualController(QObject *parent = nullptr);
    ~ManualController();

    bool active() const { return m_active; }
    int robotId() const { return m_robotId; }
    int team() const { return m_team; }
    qreal maxSpeed() const { return m_maxSpeed; }
    qreal slowSpeed() const { return m_slowSpeed; }
    qreal maxRotSpeed() const { return m_maxRotSpeed; }
    qreal kickPower() const { return m_kickPower; }
    qreal acceleration() const { return m_acceleration; }
    qreal deceleration() const { return m_deceleration; }
    qreal rotKp() const { return m_rotKp; }
    qreal rotKd() const { return m_rotKd; }
    qreal currentVx() const { return m_currentVx; }
    qreal currentVy() const { return m_currentVy; }
    qreal currentVr() const { return m_currentVr; }
    bool dribbleActive() const { return m_dribble; }
    QString statusText() const { return m_statusText; }
    bool useGamepad() const { return m_useGamepad; }
    bool gamepadConnected() const { return m_gamepad != nullptr; }

    static bool isManualControlActive() { return s_instance && s_instance->m_active; }

    Q_INVOKABLE void setMouseFieldPos(qreal x, qreal y);
    Q_INVOKABLE void setMouseActive(bool active);
    Q_INVOKABLE void setKickActive(bool active);
    Q_INVOKABLE void setDribbleActive(bool active);
    Q_INVOKABLE void setUseGamepad(bool use);

public slots:
    void setActive(bool active);
    void setRobotId(int id);
    void setTeam(int team);
    void setMaxSpeed(qreal speed);
    void setSlowSpeed(qreal speed);
    void setMaxRotSpeed(qreal speed);
    void setKickPower(qreal power);
    void setAcceleration(qreal v);
    void setDeceleration(qreal v);
    void setRotKp(qreal v);
    void setRotKd(qreal v);

signals:
    void activeChanged();
    void robotIdChanged();
    void teamChanged();
    void maxSpeedChanged();
    void slowSpeedChanged();
    void maxRotSpeedChanged();
    void kickPowerChanged();
    void accelerationChanged();
    void decelerationChanged();
    void rotKpChanged();
    void rotKdChanged();
    void velocityChanged();
    void dribbleChanged();
    void statusChanged();
    void useGamepadChanged();
    void gamepadConnectedChanged();

protected:
    bool eventFilter(QObject *obj, QEvent *event) override;

private:
    void processKey(int key, bool pressed);
    void tick();
    void updateStatus();
    void sendGamepadCmd(float vx, float vy, float vr, bool kick, float kickPower, bool dribble);
    void initSDL();
    void pollGamepad();
    void openGamepad(int deviceIndex);
    void closeGamepad();
    static double applyDeadzone(short raw, short deadzone = 3200);
    static double clamp(double val, double lo, double hi) {
        return val < lo ? lo : (val > hi ? hi : val);
    }
    static double moveTowards(double current, double target, double maxDelta) {
        if (qAbs(target - current) <= maxDelta) return target;
        return current + (target > current ? maxDelta : -maxDelta);
    }

    bool m_active = false;
    int m_robotId = 0;
    int m_team = 0;
    qreal m_maxSpeed = 3.0;
    qreal m_slowSpeed = 1.0;
    qreal m_maxRotSpeed = 10.0;
    qreal m_kickPower = 5.0;

    qreal m_acceleration = 6.0;
    qreal m_deceleration = 12.0;
    qreal m_rotKp = 8.0;
    qreal m_rotKd = 1.5;

    QMap<int, bool> m_keyState;
    QVector2D m_mouseFieldPos;
    bool m_mouseActive = false;

    double m_cmdGlobalVx = 0;
    double m_cmdGlobalVy = 0;

    qreal m_currentVx = 0;
    qreal m_currentVy = 0;
    qreal m_currentVr = 0;

    bool m_dribble = false;
    bool m_kick = false;
    bool m_emergencyStop = false;

    bool m_useGamepad = false;
    bool m_sdlInitialized = false;
    SDL_GameController* m_gamepad = nullptr;

    double m_gpLeftX = 0;
    double m_gpLeftY = 0;
    double m_gpRightX = 0;
    double m_gpRightY = 0;
    bool m_gpBtnA = false;
    bool m_gpBtnB = false;
    bool m_gpBtnX = false;
    bool m_gpBtnY = false;
    bool m_gpBtnLB = false;
    bool m_gpBtnRB = false;
    bool m_gpBtnRBPrev = false;
    bool m_gpBtnBack = false;
    bool m_gpBtnStart = false;
    bool m_gpBtnLStick = false;
    qreal m_savedMaxSpeed = 3.0;
    qreal m_savedAcceleration = 6.0;
    int m_gamepadCmdFd = -1;

    QTimer *m_timer;
    QElapsedTimer m_lastMouseTime;
    QString m_statusText;

    static ManualController* s_instance;

    friend class Field;

    static constexpr int TICK_INTERVAL = 16;
    static constexpr double DT = TICK_INTERVAL / 1000.0;
};

#endif // MANUALCONTROLLER_H
