#ifndef _GAMEPAD_COMMAND_H_
#define _GAMEPAD_COMMAND_H_

#include "staticparams.h"
#include <singleton.hpp>
#include <QUdpSocket>
#include <cstring>
#include <thread>
#include <chrono>

struct GamepadSlotState {
    uint8_t buttons[16];
    bool dribble = false;
    bool active = false;
    float velX = 0;
    float velY = 0;
    float velR = 0;
    float kickPower = 0;
    bool kickActive = false;
    std::chrono::steady_clock::time_point lastUpdate = std::chrono::steady_clock::now();

    void reset() {
        std::memset(buttons, 0, sizeof(buttons));
        dribble = false;
        active = false;
        velX = velY = velR = kickPower = 0;
        kickActive = false;
    }
};

class CGamepadCommand {
public:
    static constexpr int BTN_COUNT = 16;
    static constexpr int PKT_SIZE = 35;

    CGamepadCommand() {
        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i) {
            _slots[i].reset();
        }
    }
    ~CGamepadCommand() {
        _running = false;
        if (_thread.joinable()) _thread.join();
    }

    void startReceive(int team) {
        _team = team;
        _running = true;
        _socket.bind(QHostAddress::AnyIPv4,
                     ZSS::Athena::GAMEPAD_CMD_RECEIVE[_team],
                     QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint);
        _thread = std::thread(&CGamepadCommand::receiveLoop, this);
    }

    // Per-robotId getters
    bool isSlotActive(int robotId) const {
        if (robotId < 0 || robotId >= PARAM::Field::MAX_PLAYER) return false;
        return _slots[robotId].active;
    }

    bool getButtonForRobot(int robotId, int idx) const {
        if (robotId < 0 || robotId >= PARAM::Field::MAX_PLAYER) return false;
        if (idx < 0 || idx >= BTN_COUNT) return false;
        return _slots[robotId].buttons[idx] != 0;
    }

    bool getDribble(int robotId) const {
        if (robotId < 0 || robotId >= PARAM::Field::MAX_PLAYER) return false;
        return _slots[robotId].dribble;
    }

    float getVelX(int robotId) const {
        if (robotId < 0 || robotId >= PARAM::Field::MAX_PLAYER) return 0;
        return _slots[robotId].velX;
    }

    float getVelY(int robotId) const {
        if (robotId < 0 || robotId >= PARAM::Field::MAX_PLAYER) return 0;
        return _slots[robotId].velY;
    }

    float getVelR(int robotId) const {
        if (robotId < 0 || robotId >= PARAM::Field::MAX_PLAYER) return 0;
        return _slots[robotId].velR;
    }

    float getKickPower(int robotId) const {
        if (robotId < 0 || robotId >= PARAM::Field::MAX_PLAYER) return 0;
        return _slots[robotId].kickPower;
    }

    bool getKickActive(int robotId) const {
        if (robotId < 0 || robotId >= PARAM::Field::MAX_PLAYER) return false;
        return _slots[robotId].kickActive;
    }

    int getFirstPressedForRobot(int robotId) const {
        if (robotId < 0 || robotId >= PARAM::Field::MAX_PLAYER || !_slots[robotId].active) return -1;
        for (int i = 0; i < BTN_COUNT; ++i) {
            if (_slots[robotId].buttons[i]) return i;
        }
        return -1;
    }

    // Legacy single-gamepad API (scans all slots)
    bool getButton(int idx) const {
        for (int r = 0; r < PARAM::Field::MAX_PLAYER; ++r) {
            if (_slots[r].active && _slots[r].buttons[idx]) return true;
        }
        return false;
    }

    bool getDribble() const {
        for (int r = 0; r < PARAM::Field::MAX_PLAYER; ++r) {
            if (_slots[r].active && _slots[r].dribble) return true;
        }
        return false;
    }

    int getRobotId() const {
        for (int r = 0; r < PARAM::Field::MAX_PLAYER; ++r) {
            if (_slots[r].active) return r;
        }
        return -1;
    }

    bool isActive() const {
        for (int r = 0; r < PARAM::Field::MAX_PLAYER; ++r) {
            if (_slots[r].active) return true;
        }
        return false;
    }

    int getFirstPressed() const {
        for (int r = 0; r < PARAM::Field::MAX_PLAYER; ++r) {
            if (!_slots[r].active) continue;
            for (int i = 0; i < BTN_COUNT; ++i) {
                if (_slots[r].buttons[i]) return i;
            }
        }
        return -1;
    }

    void clearAll() {
        for (int r = 0; r < PARAM::Field::MAX_PLAYER; ++r) {
            std::memset(_slots[r].buttons, 0, sizeof(_slots[r].buttons));
        }
    }

private:
    void receiveLoop() {
        QByteArray datagram;
        while (_running) {
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
            while (_socket.state() == QUdpSocket::BoundState && _socket.hasPendingDatagrams()) {
                datagram.resize(_socket.pendingDatagramSize());
                _socket.readDatagram(datagram.data(), datagram.size());
                const uint8_t* data = reinterpret_cast<const uint8_t*>(datagram.constData());

                int robotId = -1;
                if (datagram.size() > BTN_COUNT + 1) {
                    robotId = data[BTN_COUNT + 1];
                }
                if (robotId < 0 || robotId >= PARAM::Field::MAX_PLAYER) continue;

                auto& slot = _slots[robotId];
                int n = qMin(datagram.size(), BTN_COUNT);
                for (int i = 0; i < n; ++i) {
                    slot.buttons[i] = data[i] ? 1 : 0;
                }
                if (datagram.size() > BTN_COUNT) {
                    slot.dribble = data[BTN_COUNT] != 0;
                }
                if (datagram.size() >= PKT_SIZE) {
                    float vx, vy, vr, kp;
                    std::memcpy(&vx, &data[18], 4);
                    std::memcpy(&vy, &data[22], 4);
                    std::memcpy(&vr, &data[26], 4);
                    std::memcpy(&kp, &data[30], 4);
                    slot.velX = vx;
                    slot.velY = vy;
                    slot.velR = vr;
                    slot.kickPower = kp;
                    slot.kickActive = data[34] != 0;
                }
                slot.active = true;
                slot.lastUpdate = std::chrono::steady_clock::now();
            }

            auto now = std::chrono::steady_clock::now();
            for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i) {
                if (_slots[i].active) {
                    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                        now - _slots[i].lastUpdate).count();
                    if (elapsed > 200) {
                        _slots[i].active = false;
                    }
                }
            }
        }
    }

    mutable QUdpSocket _socket;
    std::thread _thread;
    bool _running = false;
    int _team = 0;
    GamepadSlotState _slots[PARAM::Field::MAX_PLAYER];
};

typedef Singleton<CGamepadCommand> GamepadCommand;

#endif
