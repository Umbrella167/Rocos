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
                int n = qMin(datagram.size(), BTN_COUNT);
                for (int i = 0; i < n; ++i) {
                    _buttons[i] = (reinterpret_cast<const uint8_t*>(datagram.constData())[i] != 0) ? 1 : 0;
                }
                if (datagram.size() > BTN_COUNT) {
                    _dribble = reinterpret_cast<const uint8_t*>(datagram.constData())[BTN_COUNT] != 0;
                }
                if (datagram.size() > BTN_COUNT + 1) {
                    _robotId = reinterpret_cast<const uint8_t*>(datagram.constData())[BTN_COUNT + 1];
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
};

typedef Singleton<CGamepadCommand> GamepadCommand;

#endif
