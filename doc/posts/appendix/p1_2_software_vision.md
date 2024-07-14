# 视觉软件使用

> 以下资料大部分来自于[官方视觉软件ssl-vision wiki](https://github.com/RoboCup-SSL/ssl-vision/wiki)和[论文](https://www.informatik.uni-bremen.de/agebv2/downloads/published/zickler_rs_09.pdf)
> 如何需要使用海康像机或大恒像机，请使用Turing-zero的[fork版本](https://github.com/Turing-zero/ssl-vision)

## 介绍

### 为什么有视觉软件

视觉软件是RoboCup SSL比赛中的一个重要组成部分，它负责从摄像头采集图像，识别场上的机器人和球，然后将这些信息传递给机器人控制软件。从2009年开始，RoboCup SSL比赛使用的视觉软件是ssl-vision，它是一个开源项目，由RoboCup SSL联盟维护。本手册介绍了ssl-vision当前状态和使用方法。

### 标准颜色

RooboCup SSL比赛中，机器人和球的颜色是标准的，这样视觉软件可以通过颜色识别来识别机器人和球。标准颜色如下：

* 粉色/绿色：用于标记机器人编号
* 黄色/蓝色：用于标记机器人队伍
* 橙色：用于标记球
* *深绿色：场地颜色*

在选择卡纸用于机器人色标时，核心原则是尽可能选择容易区分和识别的颜色，同时避免与场地颜色相似。

## 安装与部署

### 操作系统要求

ssl-vision是一款linux应用程序。参考发行版为最新LTS版本的Ubuntu(由于qt的部分bug，目前只能支持到22.04)。

### 软件要求

软件所需依赖如下：
* git
* g++
* QT >= 4.3 with opengl and networking support
* cmake
* Eigen3
* Google protocol buffers (protoc)
* OpenGL
* GLU
* libdc1394 Version >= 2.0
* libjpeg
* libpng
* OpenCV

在Ubuntu上安装依赖，可以直接运行`InstallPackagesUbuntu.sh`脚本。在Arch中获取所有软件包，可以运行`InstallPackagesArch.sh`脚本。

### 硬件要求

ssl-vision已经在x86兼容的计算机上进行开发和测试。从2019年开始，官方对于像机的像素要求为每9m x 6m的场地需要至少500万像素，所以运行ssl-vision的计算机需要有足够的cpu运算性能来处理这些像素。

该系统目前支持 1394B / FireWire 800 以及 1394A / FireWire 400、Video4Linux、Matrix-Vision BlueFox2 (USB)、千兆以太网 (使用 flycap) 、FLIR USB3 (使用 Spinnaker SDK) 、海康（使用Hikrobot MVS - Machine Vision Software）、大恒（使用DAHENG Imaging）等摄像头，具体列表可以参考[这里](https://github.com/turing-zero/ssl-vision?tab=readme-ov-file#supported-cameras)。

#### FLIR USB3 推荐

摄像头：FLIR Blackfly S (BFS-U3-51S5C-C)
镜头：Kowa LM4HC / LM3JC10M

#### 海康推荐

摄像头：海康威视 MV-CH050-10UC
镜头：Kowa LM4HC / LM3JC10M

#### 大恒推荐

摄像头：大恒相机 MER2-502-79U3C

#### 其他可行的摄像头

选择摄像头一般需要注意以下几点：
* 分辨率 (至少 500万像素)
* 帧率 (至少 73fps)
* 数据接口 (USB3.0 / 千兆以太网)
* 镜头接口 (CS / C，一般需要和镜头对应)

选择镜头一般需要注意以下几点：
* 焦距：一般覆盖9m x 6m的场地，镜头高度需要6m，带上边界，至少需要覆盖10m x 7m的区域，原则上镜头焦距**不能大于5mm**，否则会导致视野过窄。
* 分辨率：需要和摄像头对应，一般需要大于摄像头分辨率。
* 接口类型：需要和摄像头对应，一般为CS / C接口。
* 畸变：需要尽量小，否则会影响视觉软件的识别效果。

### 同步时钟

如果ssl-vision在多台计算机上运行，例如A组的12x9m场地需要至少两个摄像头覆盖的情况，需要所有PC间完成时间同步。

对于时间同步，建议在一台PC上设置NTP服务器，在Ubuntu下可以使用Chrony进行时间同步。

1. 安装chrony : `sudo apt install chrony`
2. 编辑配置文件：`sudo nano /etc/chrony/chrony.conf`

服务器PC上：
```
# allow serving time even if unsynchronized
local stratum 10
# allow connections
allow 0/0
```

客户端PC上：
```
# set server (IP/host of the NTP-server)
server ssl-vision-a
```

3. 重启chrony：`sudo systemctl restart chrony`
4. 验证客户端是否已与服务器连接：`chronyc sources`

### 编译ssl-vision
    
```bash
# git clone https://github.com/RoboCup-SSL/ssl-vision.git # 此为官方版本
git clone https://github.com/Turing-zero/ssl-vision # 此为Turing-zero的fork版本
cd ssl-vision
mkdir build
cd build
cmake ..
make
```

### 运行ssl-vision

编译成功后，可以在`bin`目录下找到可执行文件，运行即可。

* vision - SSL-Vision 应用程序
* client - 一个简单的示例客户端
* graphicClient - 图形示例客户端

运行时，会在运行目录下生成配置文件，所以在配置时，确保路径正确。一般推荐在`ssl-vision`下执行`./bin/vision`。