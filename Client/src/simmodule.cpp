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

grSim_Packet grsim_packet_yellow;
grSim_Packet grsim_packet_blue;
}
SimModule::SimModule(QObject *parent) : QObject(parent){
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
    ZSS::New::Robots_Status robotsPacket;
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
                GlobalData::instance()->robotInformation[_TEAM][id].infrared = infrared;
                GlobalData::instance()->robotInformation[_TEAM][id].flat = isFlatKick;
                GlobalData::instance()->robotInformation[_TEAM][id].chip = isChipKick;
                robotInfoMutex.unlock();
                qDebug() << "Yellow id: " << id << "  infrared: " << infrared << "  flat: " << isFlatKick << "  chip: " << isChipKick;
                emit receiveSimInfo(_TEAM, id);
            }
        }
    }
}

void SimModule::sendSim(int t, ZSS::New::Robots_Command& command) {
    if(t != 0 && t != 1) {
        qDebug() << "Team ERROR in Simmodule !";
        return;
    }
    grSim_Packet& grsim_packet = (t == PARAM::BLUE ? grsim_packet_blue : grsim_packet_yellow);
    grSim_Commands * grsim_commands = grsim_packet.mutable_commands();
    grsim_commands->set_isteamyellow(t == PARAM::BLUE ? false : true);
    grsim_commands->set_timestamp(0);
    grsim_commands->set_allocated_robot_commands(&command);

    int size = grsim_packet.ByteSize();
    QByteArray data(size, 0);
    grsim_packet.SerializeToArray(data.data(), data.size());
    command_socket.writeDatagram(data, size, QHostAddress(ZNetworkInterfaces::instance()->getIP("grSim")), ZSS::Athena::SIM_SEND);
    grsim_commands->release_robot_commands();
}

}

