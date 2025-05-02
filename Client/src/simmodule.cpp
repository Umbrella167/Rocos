#include "simmodule.h"
#include "parammanager.h"
#include "globaldata.h"
#include "zss_cmd.pb.h"
#include "grSim_Packet.pb.h"
#include "messageinfo.h"
#include "staticparams.h"
#include <chrono>
#include <thread>
#include <cmath>
#include <geometry.h>
#include <qdebug.h>
#include "sim/sslworld.h"
#include "setthreadname.h"
#include "networkinterfaces.h"
namespace ZSS {
namespace {
bool NoVelY = false;
bool trans_dribble(double dribble) {
    return dribble>0.5;
}
double trans_length(double v) {
    return v / 1000.0;
}
double trans_vr(double v) {
    return v;/// 40.0; from angel to 1/40 rad
}
std::thread* blueReceiveThread = nullptr;
std::thread* yellowReceiveThread = nullptr;

grSim_Packet grsim_packet;
grSim_Commands* grsim_commands;
grSim_Robot_Command* grsim_robots[PARAM::ROBOTNUM];
}
SimModule::SimModule(QObject *parent) : QObject(parent){
    grsim_commands = grsim_packet.mutable_commands();
    for (int i = 0; i < PARAM::ROBOTNUM; i++) {
        grsim_robots[i] = grsim_commands->add_robot_commands();
    }
    for (int i = 0; i < PARAM::ROBOTNUM; i++) {
        grsim_robots[i]->set_id(i);
        grsim_robots[i]->set_kickspeedx(0);
        grsim_robots[i]->set_kickspeedz(0);
        grsim_robots[i]->set_velnormal(0);
        grsim_robots[i]->set_veltangent(0);
        grsim_robots[i]->set_velangular(0);
        grsim_robots[i]->set_spinner(false);
        grsim_robots[i]->set_wheelsspeed(false);
    }
    for(int i = 0; i < PARAM::TEAMS; i++) {
        if(connectSim(i)){
            auto& socket = i==PARAM::YELLOW ? yellowReceiveSocket : blueReceiveSocket;
            auto& _thread = i==PARAM::YELLOW ? yellowReceiveThread : blueReceiveThread;
            _thread = new std::thread([&,i]{readTeamData(i,socket);});
            _thread->detach();
        }
    }
}

SimModule::~SimModule() {
    delete blueReceiveThread;
    delete yellowReceiveThread;
    yellowReceiveSocket.abort();
    blueReceiveSocket.abort();
}

bool SimModule::connectSim(bool color) {
    if(color) {
        if(yellowReceiveSocket.bind(QHostAddress::AnyIPv4, ZSS::Sim::YELLOW_STATUS_PORT, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
            qDebug() << "Yellow connect successfully!!!";
            return true;
        }
        return false;
    }
    if(blueReceiveSocket.bind(QHostAddress::AnyIPv4, ZSS::Sim::BLUE_STATUS_PORT, QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
        qDebug() << "Blue connect successfully!!!";
        return true;
    }
    return false;
}

bool SimModule::disconnectSim(bool color) {
    if(color) {
        yellowReceiveSocket.disconnectFromHost();
    } else {
        blueReceiveSocket.disconnectFromHost();
    }
    return true;
}

// void SimModule::readBlueData() {
//     SetThreadName("readBlueData");
//     qDebug() << "Reading Blue Data!";
//     ZSData datagram;
//     while(true){
//         std::this_thread::sleep_for(std::chrono::microseconds(500));
//         ZSS::Protocol::Robots_Status robotsPacket;
//         // receive("blue_status",datagram);
//         robotsPacket.ParseFromArray(datagram.ptr(), datagram.size());

//         for (int i = 0; i < robotsPacket.robots_status_size(); ++i) {
//             int id = robotsPacket.robots_status(i).robot_id();
//             bool infrared = robotsPacket.robots_status(i).infrared();
//             bool isFlatKick = robotsPacket.robots_status(i).flat_kick();
//             bool isChipKick = robotsPacket.robots_status(i).chip_kick();
//             robotInfoMutex.lock();
//             GlobalData::instance()->robotInformation[PARAM::BLUE][id].infrared = infrared;
//             GlobalData::instance()->robotInformation[PARAM::BLUE][id].flat = isFlatKick;
//             GlobalData::instance()->robotInformation[PARAM::BLUE][id].chip = isChipKick;
//             robotInfoMutex.unlock();
//             qDebug() << "Blue id: " << id << "  infrared: " << infrared << "  flat: " << isFlatKick << "  chip: " << isChipKick;
//             emit receiveSimInfo(PARAM::BLUE, id);
//         }
//     }
// }

// void SimModule::readYellowData() {
//     // SetThreadName("readYellowData");
//     qDebug() << "Reading Yellow Data!";
//     ZSData datagram;
//     while(true){
//         std::this_thread::sleep_for(std::chrono::microseconds(500));
//         ZSS::Protocol::Robots_Status robotsPacket;
//         // receive("yellow_status",datagram);
//         robotsPacket.ParseFromArray(datagram.ptr(), datagram.size());
//         for (int i = 0; i < robotsPacket.robots_status_size(); ++i) {
//             int id = robotsPacket.robots_status(i).robot_id();
//             bool infrared = robotsPacket.robots_status(i).infrared();
//             bool isFlatKick = robotsPacket.robots_status(i).flat_kick();
//             bool isChipKick = robotsPacket.robots_status(i).chip_kick();
//             robotInfoMutex.lock();
//             GlobalData::instance()->robotInformation[PARAM::YELLOW][id].infrared = infrared;
//             GlobalData::instance()->robotInformation[PARAM::YELLOW][id].flat = isFlatKick;
//             GlobalData::instance()->robotInformation[PARAM::YELLOW][id].chip = isChipKick;
//             robotInfoMutex.unlock();
//             qDebug() << "Yellow id: " << id << "  infrared: " << infrared << "  flat: " << isFlatKick << "  chip: " << isChipKick;
//             emit receiveSimInfo(PARAM::YELLOW, id);
//         }
//     }
// }

void SimModule::readTeamData(int _TEAM, QUdpSocket& _socket) {
    qDebug() << "Reading Data! " << (_TEAM==0?"BLUE":"YELLOW");
    QByteArray datagram;
    ZSS::Protocol::Robots_Status robotsPacket;
    while(true){
        std::this_thread::sleep_for(std::chrono::microseconds(500));
        while(_socket.state() == QUdpSocket::BoundState && _socket.hasPendingDatagrams()) {
            datagram.resize(_socket.pendingDatagramSize());
            _socket.readDatagram(datagram.data(), datagram.size());
            robotsPacket.ParseFromArray(datagram, datagram.size());
            for (int i = 0; i < robotsPacket.robots_status_size(); ++i) {
                int id = robotsPacket.robots_status(i).robot_id();
                bool infrared = robotsPacket.robots_status(i).infrared();
                bool isFlatKick = robotsPacket.robots_status(i).flat_kick();
                bool isChipKick = robotsPacket.robots_status(i).chip_kick();
                robotInfoMutex.lock();
                GlobalData::instance()->robotInformation[PARAM::YELLOW][id].infrared = infrared;
                GlobalData::instance()->robotInformation[PARAM::YELLOW][id].flat = isFlatKick;
                GlobalData::instance()->robotInformation[PARAM::YELLOW][id].chip = isChipKick;
                robotInfoMutex.unlock();
                qDebug() << "Yellow id: " << id << "  infrared: " << infrared << "  flat: " << isFlatKick << "  chip: " << isChipKick;
                emit receiveSimInfo(_TEAM, id);
            }
        }
    }
}

void SimModule::sendSim(int t, ZSS::Protocol::Robots_Command& command) {
    static ZSData data;
    std::scoped_lock<std::mutex> lock(command_mutex_);
    grsim_commands->set_timestamp(0);
    if (t == 0) {
        grsim_commands->set_isteamyellow(false);
    } else if (t == 1) {
        grsim_commands->set_isteamyellow(true);
    } else {
        qDebug() << "Team ERROR in Simmodule !";
    }
    int command_size = command.command_size();
    for (int i = 0; i < command_size; i++) {
        auto commands = command.command(i);
        auto id = commands.robot_id();
        grsim_robots[id]->set_id(id);
        grsim_robots[id]->set_wheelsspeed(false);
        //set flatkick or chipk    ick
        if (!commands.kick()) {
            grsim_robots[id]->set_kickspeedz(0);
            grsim_robots[id]->set_kickspeedx(trans_length(commands.power()));
        } else {
            double radian = ZSS::Sim::CHIP_ANGLE * ZSS::Sim::PI / 180.0;
            double vx = sqrt(trans_length(commands.power()) * ZSS::Sim::G / 2.0 / tan(radian));
            double vz = vx * tan(radian);
            grsim_robots[id]->set_kickspeedz(vx);
            grsim_robots[id]->set_kickspeedx(vz);
        }
        //set velocity and dribble
        double vx = commands.velocity_x();
        double vy = NoVelY ? 0.0f : commands.velocity_y();
        double vr = commands.velocity_r();
        double dt = 1. / Athena::FRAME_RATE;
        double theta = - vr * dt;
        CVector v(vx, vy);
        v = v.rotate(theta);
        if (fabs(theta) > 0.00001) {
            v = v * theta / (2 * sin(theta / 2));
            vx = v.x();
            vy = v.y();
        }

        grsim_robots[id]->set_veltangent(trans_length(vx));
        grsim_robots[id]->set_velnormal(trans_length(vy));
        grsim_robots[id]->set_velangular(trans_vr(vr));
        grsim_robots[id]->set_spinner(trans_dribble(commands.dribbler_spin()));
    }
    int size = grsim_packet.ByteSizeLong();
    data.resize(size);
    grsim_packet.SerializeToArray(data.ptr(), size);
    sendSocket.writeDatagram((const char*)data.data(), size, QHostAddress(ZNetworkInterfaces::instance()->getIP("grSim")),ZSS::Athena::SIM_SEND);
    for (int i = 0; i < PARAM::ROBOTNUM; i++) {
        grsim_robots[i]->set_id(i);
        grsim_robots[i]->set_kickspeedx(0);
        grsim_robots[i]->set_kickspeedz(0);
        grsim_robots[i]->set_velnormal(0);
        grsim_robots[i]->set_veltangent(0);
        grsim_robots[i]->set_velangular(0);
        grsim_robots[i]->set_spinner(false);
        grsim_robots[i]->set_wheelsspeed(false);
    }
}

}

