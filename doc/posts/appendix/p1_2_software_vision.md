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

## 图像采集

### 采集控制

采集由左侧控制面板中`Camera i/Image Capture/Capture Control`中的`Start Capture`和`Stop Capture`按钮控制。在开始采集之前，请确保`Camera i/Image Capture/Capture Control`中的`Capture Module`设置与相机对应。

你可以在运行时通过`-s`参数来使`ssl-vision`立刻开始采集图像而无需单机每个相机的`Start Capture`按钮。

### 使用大恒相机进行图像采集

请确保您的电脑已经安装了大恒相机的驱动以及SDK：

* 驱动链接：[大恒相机驱动](https://www.daheng-imaging.com/downloads/)

在`Capture Module`设置为`Daheng`后，可以在`Camera i/Image Capture/Capture Control/Daheng`选项卡中设置相机的参数。参数包括了相机的曝光时间(exposure time)、增益(gain)、白平衡(Balance xxx)，为了方便，也可以设置自动白平衡(auto balance)、自动增益(auto gain)等。

### 使用海康相机进行图像采集

请确保您的电脑已经安装了海康相机的驱动以及SDK：

* 驱动链接：[海康相机驱动](https://www.hikrobotics.com/cn/machinevision/service/download)

在`Capture Module`设置为`HikMvCam`后，可以在`Camera i/Image Capture/Capture Control/HikMvCam/Camera Parameters`选项卡中设置相机的参数。参数包括了相机的曝光时间(Expose)、增益(Gain)，为了方便，也可以设置自动增益(Auto Gain)等。

## 场地配置与相机标定

### 坐标系与相机设定

小型组的摄像头和坐标系设置如图所示：一个ssl-vision实例可以最多支持四个摄像头，摄像头按照从负坐标到正坐标的顺序编号，编号从0开始。

```{thumbnail} ../../img/p1_2_ssl-vision-cameras.png
```

### 场地标记

场地标记指定为两个列表，分别是线段和圆弧。需要添加/删除标记时，需要更改`Number of Line Segments`或`Number of Arcs`。如果需要简单设置默认的`Division A/B`，可以点击对应的`Apply`按钮后点击`Field Lines/Arcs`右侧的`Update`按钮进行更新。

```{thumbnail} ../../img/p1_2_global-field-config.png
```

## 相机标定

### 更新关键控制点

选择一个有摄像头支持的选项卡。不必担心摄像头的号码分配，也不必使用所有的选项卡。

根据之前提到的编号方案填写正确的相机ID，并将其输入到`Global camera id`中，然后可以点击`Update control points`使控制点的坐标更新为默认设置。也可以手动输入控制点的坐标。你可以在`Camera i / Camera Calibrator / Calibration Parameters / Control point j`中检查并更新(`field x/y`)，也可以在右侧显示界面中切换到第三栏`Camera Calibration`中使用鼠标拖拽改变控制点的像素位置(`image x/y`)。

```{thumbnail} ../../img/p1_2_camera-calibration.png
```

### 标定步骤

1. 确保启用了相机的可视化后检查`camera calibration`和`camera result`选项。
    * `Camera i / Visualization / enable`：启用相机可视化
    * `Camera i / Visualization / image`：显示相机图像
    * `Camera i / Visualization / camera calibration`：显示相机标定的控制点
    * `Camera i / Visualization / calibration result`：显示相机标定的结果
2. 选择右侧可视化的`camera calibration`选项卡，然后点击`Reset`按钮重置相机标定。

```{thumbnail} ../../img/p1_2_calibration_step1.png
```

3. 将控制点拖拽到图像中与指定世界位置相对应的位置。在下图中，控制点包括了球场中心以及禁区与底线的焦点。

4. 点击`Do initial calibration`进行初始化

```{thumbnail} ../../img/p1_2_calibration_step2.png
```

5. 联合改变下述参数，直至标定结果与实际场地线条接近，每次更新后，需要手动点击`Do initial calibration`重新完成初始化：
    * 相机畸变中心(`Camera i / Camera Calibrator / Camera Parameters / principal point x&y`)
    * 右侧`Initial Camera Parameters`中的相机高度(`Camera Height`)以及畸变参数(`Distortion`)

```{thumbnail} ../../img/p1_2_calibration_step3.png
```

6. (可选-微调) 在可视化中，打开`Detected edges`然后拖动右侧下方的`Line Search Corridor Width`后，点击`Detect additional calibration points`。

```{thumbnail} ../../img/p1_2_calibration_step4.png
```

7. (可选-微调) 在检测边缘后，点击`Do full calibration`使用所有检测的边缘点进行完整标定。然后可以不断减小`Line Search Corridor Width`，直至标定结果与实际场地线条接近。

```{thumbnail} ../../img/p1_2_calibration_step5.png
```

## 色彩分割设置

### 颜色阈值调节

ssl-vision的图像处理流程，主要是从图像→颜色阈值→色块检测→机器人/球的模式识别的步骤。

为了实现这个过程，ssl-vision要求用户定义从连续的[YUV颜色空间](https://zh.wikipedia.org/wiki/YUV)到离散的RoboCup颜色标签的映射。该映射使用3D查找表(3D-Lookup-Table)定义，并在GUI右侧的`YUV Calibration`选项卡中设置以及可视化。为了在2D界面中显示3D LUT，三维的颜色方块在`Y`维度上进行了切片形成了多个二为图像，每个图像代表了该特定切片的`U`和`V`分两。要滚动查看多个切片，可以使用鼠标滚轮或使用键盘`a`和`z`按键。

要编辑LUT中的映射，您只需要在右侧选择需要编辑的ssl的颜色标签(例如：`Pink` or `Field Green`)然后直接按鼠标左键即可直接绘制。要加快绘制速度，你可以通过按住`Ctrl`来扩大绘制区域，也可以点击右键实现填充涂色。LUT具有`撤销/重置`功能，要进行对应的删除，可以使用右侧颜色中的`Clear`也可以在绘制时按住`Shift`键。

一般我们需要先从视频输入流中收集一些颜色样本才能知道要具体在哪里建立LUT的颜色映射。所以需要在确保`Visualization / enable & image`启用的情况下，在视频窗口点击需要采集的颜色像素即可。在图像可视化窗口中，可以通过缩放（鼠标滚轮）以及平移（鼠标右键拖动）来查看更多的细节（使用"空格"可以重置为正常视图）。颜色采集样本将在YUV LUT现实中以`x`标记。出了采集单个像素以外，还可以通过选择视频小不见并按`i`来采集图像中的所有像素。要清除颜色采样器，可以使用`c`按键或使用YUV LUT上方的清除按钮。

在编辑后，可以在左侧最上方点击`Save Settings`进行手动保存。

### 色块检测

颜色阈值调节之后，需要进行色块检测，它识别阈值图像的连同分两并计算其边界框和质心。使用时可以通过打开`Visualization / blobs`来查看当前检测到的色块。一旦正确定义了颜色分割和色块查找参数，可以进一步通过`Global / Ball Detection & Robot Detection`来调整球和机器人的检测参数。

## 队伍设置与检测

### 定义队伍的模式图像

ssl-vision提供的图案检测器可以支持小型组的任何基于颜色的多分割的图案模式。队伍的图案通过`ssl-vision/patterns`目录中的`.png`进行定义。对于正式比赛，目前的图案已经标准化，定义文件为`patterns/teams/standard2010_16.png`。该队伍图像包含了一个由各个机器人的图案组成的网络，程序会按照顺序进行解析（ID从0开始递增）。图案检测器将使用该图像中定义的所有标记的面积以及想对角度进行图案检测。为了是图像可以被解析，每个机器人都应该包含一个蓝色标记。此外，如示例图像所示，每个图像都应覆盖一个带有黄色垂直调的单像素，该像素表示机器人的高度，其像素高度与机器人的毫米为单位的高度相对应。

```{thumbnail} ../../img/p1_2_standard2010_16.png
```

### 在数据树中定义队伍

在`Global / Robot Detection`中，可以通过点击`Add Team`增加队伍。这会在`Global / Robot Detection / Teams`中增加一个新条目`New Team n`，打开此分支后，可以根据需求调整队伍名称以及机器人高度。

### 设定机器人图案

要使用png文件，首先打开`Global / Robot Detection / Pattern`并确保`Unique Patterns & Have Angles`被勾选。打开`Global / Robot Detection / Pattern / Marker Image`，设定`Marker Image File`。如果在启动ssl-vision时不是在`ssl-vision`的根目录下启动的，需要特别关注图片路径的设置，每次更改`Marker Image File`的值后，终端会有输出提示是否成功加载图片。

接下来，确保设置中机器人图案的行列数正确，如果有需要，可以取消不希望被识别的机器人ID。

### 配置模式识别器的参数

在不同的场地配置下，如下参数可能根据实际情况有所更改

* 中心标记设定`Robot Detection / Pattern / Center Marker Settings`
    * `Uniform`,`Expected Area Mean`,`Expected StdDev`: 用于根据标记的测量值与预期面积的偏差来计算标记的置信度，置信度计算公式为`conf = gaussian(measured_area_deviation, expected_area_std_deviation) / (gaussian(measured_area_std_deviation, expected_area_std_deviation) + Uniform)`。其中`measured_area_std_deviation`时标记测量面积与面积平均值之间的绝对差值。
    * `Duplicate Merge Distance`: 指两个检测到的色块应该被合并成一个的最大距离。
* 其他标记设定`Robot Detection / Pattern / Other Markers Settings`
* 直方图设定`Robot Detection / Pattern / Histogram Settings`(一般不需要更改)
* 模式适配`Robot Detection / Pattern / Pattern Fitting`
    * `Max Marker Center Dist`是任何周围团的质心与中心标记的质心之间的最大距离。
    * `Weight Area`是"区域匹配"误差的权重。（检测到的区域与模式定义中的区域的匹配程度）
    * `Weight Center-Dist`是"中心标记到周围标记距离"误差的权重。
    * `Weight Next-Dist`是`从一个周围标记到下一个周围标记的距离`误差的权重。
    * `Max Error`是上述三个部分允许的最大总加权误差，超过这个值的匹配将被拒绝。
    * `Expected StdDev`是模式中标记的预期标准偏差。
    * `Uniform`是与误差和偏差进行比较的均匀分量，与`Center Marker Settings`中的`Uniform`类似。

### 选择队伍

在配置好队伍的信息之后，可以在`Global / Blue Team`和`Global / Yellow Team`中选择对应的队伍。

## 通信设置

ssl-vision系统到客户端的所有通信均采用UDP，且都是通过端口10006和多播地址`224.3.23.2`进行的。

在检测完成后，ssl-vision会立刻广播机器人和球的检测结果。请注意，各个摄像头在单独的线程上执行，所以无法保证来自于不同摄像头的信息的顺序。

ssl-vision系统自身不执行任何传感器合并，因此他将独立提供多个摄像头的检测结果。客户端需要自行合并来自两个摄像头观测到的重叠部分的机器人和球。同样的，ssl-vision系统不执行任何物体追踪或滤波处理。这些都留给客户端，方便队伍将自己的预测执行与视觉系统进行融合并完成追踪。

### 通信协议

所有的数据均使用[Google Protocol Buffers](https://github.com/protocolbuffers/protobuf)进行编码。protobuf数据包定义在`src/shared/proto`目录下。通过网络发送的每个数据包都编码在`wrapper`数据包中，该数据包定义在`messages_robocup_ssl_wrapper.proto`文件中。

* 识别数据

`messages_robocup_ssl_detection.proto`中定义了摄像机一帧图像的完整检测结果，包括机器人和球。

* 几何数据

`messages_robocup_ssl_geometry.proto`中定义了场地的几何信息，即场地尺寸和相机校准信息。这像数据默认以3s为间隔发布。可以通过编辑`Publish Geometry / Auto Publish`中的`Interval(seconds)`字段进行设置。

## 开发

欢迎大家为ssl-vision贡献新功能和错误修复。这可以通过github的`pull request`来实现。

在提交PR之前，请清理代码。在PR的审核期间，至少一名组委会成员应使用真实场地设置并测试PR所提供的功能。
