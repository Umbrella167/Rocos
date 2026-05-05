#include <QProcess>
#include "networkinterfaces.h"
NetworkInterfaces::NetworkInterfaces(){
    this->pingIPs.clear();
    pingIPs.append(QString("127.0.0.1"));
    QString local = getLocalAddress();
    QStringList ip_list = local.split('.');
    QString ip_head = ip_list[0];
    for (int i=1; i< ip_list.size()-1; i++){
        ip_head += QString(".");
        ip_head += ip_list[i];
    }
    for (int i=1; i<=255; i++) {
        QString test_ip = ip_head+QString(".%1").arg(i);
        if (Ping(test_ip))
            pingIPs.append(test_ip);
    }
    pingIPs.append(QString("192.168.31.190"));
}
QString NetworkInterfaces::getLocalAddress()
{
    QString ip_address;
    for(auto interface : QNetworkInterface::allAddresses()){
//        qDebug() << interface.toString() << (interface != QHostAddress::LocalHost) << (interface.toIPv4Address());
        if (interface != QHostAddress::LocalHost && interface.toIPv4Address()){
            ip_address = interface.toString();
        }
    }
    if (ip_address.isEmpty()){
        return QHostAddress(QHostAddress::LocalHost).toString();
    }
    return ip_address;
}

bool NetworkInterfaces::Ping(const QString ip)
{
    QString cmdstr =QString("ping -s 1 -c 1 %1").arg(ip);
    QProcess cmd;
    cmd.start(cmdstr);
    cmd.waitForReadyRead(1);
    cmd.waitForFinished(1);

    QString response = cmd.readAll();
    cmd.close();
    if(response.indexOf("ttl") == -1){
        return false;
    }
    return true;
}
void NetworkInterfaces::updateInterfaces(){
    this->interfaces.clear();
    for(auto interface : QNetworkInterface::allInterfaces()){
        interfaces.append(interface.humanReadableName());
    }
}
