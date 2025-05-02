#ifndef NETWORKINTERFACES_H
#define NETWORKINTERFACES_H
#include <QStringList>
#include <QNetworkInterface>
#include <map>
#include "singleton.hpp"
class NetworkInterfaces{
public:
    NetworkInterfaces();
    void updateInterfaces();
    QStringList getInterfaces(){ return interfaces; }
    void setInterface(const std::string& key, const int index){
        interfaceMap[key] = index;
    }
    QNetworkInterface getInterface(const std::string& key){
        auto it = interfaceMap.find(key);
        if (it != interfaceMap.end()) {
            return QNetworkInterface::interfaceFromName(interfaces[it->second]);
        }
        return QNetworkInterface::interfaceFromName(QString());
    }
    QStringList getAvailableIPs(){ return pingIPs; }
    void setIP(const std::string& key, const int index){
        ipMap[key] = index;
    }
    QString getIP(const std::string& key){
        auto it = ipMap.find(key);
        if (it != ipMap.end()) {
            return pingIPs[it->second];
        }
        return QString();
    }
    QString getLocalAddress();
    bool Ping(const QString ip);
    QNetworkInterface getFromIndex(const int index){ return QNetworkInterface::interfaceFromName(interfaces[index]); }
    QString getIPFromIndex(const int index){
        if (index < 0 || index >= pingIPs.size()) {
            return QString();
        }
        return pingIPs[index];
    }
private:
    QStringList interfaces;
    QStringList pingIPs;
    std::map<std::string, int> interfaceMap;
    std::map<std::string, int> ipMap;
};
typedef Singleton<NetworkInterfaces> ZNetworkInterfaces;
#endif // NETWORKINTERFACES_H
