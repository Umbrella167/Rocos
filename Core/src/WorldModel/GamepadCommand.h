#ifndef _GAMEPAD_COMMAND_H_
#define _GAMEPAD_COMMAND_H_

#include "staticparams.h"
#include <singleton.hpp>
#include <QUdpSocket>
#include <cstring>
#include <thread>

class CGamepadCommand {
public:
    static constexpr int BTN_COUNT = 16;
    // Packet layout:
    //   [0..15]  buttons (uint8 each)
    //   [16]     dribble toggle (uint8)
    //   [17]     robotId (uint8)
    //   [18..21] velocity_x (float, 4 bytes)
    //   [22..25] velocity_y (float, 4 bytes)
    //   [26..29] velocity_r (float, 4 bytes)
    //   [30..33] kick_power (float, 4 bytes)
    //   [34]     kick_active (uint8)
    static constexpr int PKT_SIZE = 35;

    CGamepadCommand() { std::memset(_buttons, 0, sizeof(_buttons)); }
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

    bool getButton(int idx) const {
        if (idx < 0 || idx >= BTN_COUNT) return false;
        return _buttons[idx] != 0;
    }

    bool getDribble() const { return _dribble; }
    int getRobotId() const { return _robotId; }
    bool isActive() const { return _active; }
    float getVelX() const { return _velX; }
    float getVelY() const { return _velY; }
    float getVelR() const { return _velR; }
    float getKickPower() const { return _kickPower; }
    bool getKickActive() const { return _kickActive; }

    int getFirstPressed() const {
        for (int i = 0; i < BTN_COUNT; ++i) {
            if (_buttons[i]) return i;
        }
        return -1;
    }

    void clearAll() { std::memset(_buttons, 0, sizeof(_buttons)); }

private:
    void receiveLoop() {
        QByteArray datagram;
        while (_running) {
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
            while (_socket.state() == QUdpSocket::BoundState && _socket.hasPendingDatagrams()) {
                datagram.resize(_socket.pendingDatagramSize());
                _socket.readDatagram(datagram.data(), datagram.size());
                const uint8_t* data = reinterpret_cast<const uint8_t*>(datagram.constData());
                int n = qMin(datagram.size(), BTN_COUNT);
                for (int i = 0; i < n; ++i) {
                    _buttons[i] = data[i] ? 1 : 0;
                }
                if (datagram.size() > BTN_COUNT) {
                    _dribble = data[BTN_COUNT] != 0;
                }
                if (datagram.size() > BTN_COUNT + 1) {
                    _robotId = data[BTN_COUNT + 1];
                }
                if (datagram.size() >= PKT_SIZE) {
                    float vx, vy, vr, kp;
                    std::memcpy(&vx, &data[18], 4);
                    std::memcpy(&vy, &data[22], 4);
                    std::memcpy(&vr, &data[26], 4);
                    std::memcpy(&kp, &data[30], 4);
                    _velX = vx;
                    _velY = vy;
                    _velR = vr;
                    _kickPower = kp;
                    _kickActive = data[34] != 0;
                    _active = (_robotId >= 0 && _robotId < PARAM::Field::MAX_PLAYER);
                } else {
                    _velX = _velY = _velR = _kickPower = 0;
                    _kickActive = false;
                    _active = (_robotId >= 0 && _robotId < PARAM::Field::MAX_PLAYER);
                }
            }
        }
    }

    mutable QUdpSocket _socket;
    std::thread _thread;
    bool _running = false;
    int _team = 0;
    uint8_t _buttons[BTN_COUNT];
    bool _dribble = false;
    int _robotId = -1;
    bool _active = false;
    float _velX = 0;
    float _velY = 0;
    float _velR = 0;
    float _kickPower = 0;
    bool _kickActive = false;
};

typedef Singleton<CGamepadCommand> GamepadCommand;

#endif
