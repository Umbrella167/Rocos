# Xbox Series S|X 手柄 Linux 有线连接修复教程

## 适用环境

- **手柄型号**: Xbox Series S|X Controller (USB ID: 045e:0b12)
- **系统**: Ubuntu 22.04 / Linux 内核 6.8+
- **连接方式**: USB 有线

## 问题描述

手柄通过 USB 连接电脑后，系统能识别设备（`/dev/input/js0` 存在），但按键和摇杆无响应或部分无响应。默认的 `xpad` 驱动对该手柄支持不完整。

## 解决方案：安装 xone 驱动（fork 版本）

### 第一步：卸载冲突驱动

```bash
sudo modprobe -r xpad hid_xpadneo xboxdrv 2>/dev/null
```

如果之前安装过旧版 xone，先卸载：

```bash
cd /tmp/xone && sudo ./uninstall.sh
```

### 第二步：安装依赖

```bash
sudo apt install dkms linux-headers-$(uname -r) git curl cabextract -y
```

### 第三步：安装 xone fork 版本

> 注意：不要用原版 `medusalix/xone`（v0.3），它有认证握手 bug。使用活跃维护的 fork 版本。

```bash
git clone https://github.com/dlundqvist/xone.git /tmp/xone-fork
cd /tmp/xone-fork
sudo ./install.sh --release
```

### 第四步：下载无线适配器固件

原版 xone 的固件脚本可以用：

```bash
git clone https://github.com/medusalix/xone /tmp/xone
sudo /tmp/xone/xone-get-firmware.sh --skip-disclaimer
```

### 第五步：重启电脑

```bash
sudo reboot
```

### 第六步：插入手柄并测试

```bash
jstest /dev/input/js0
```

按手柄按钮和摇杆，观察数值变化。如果数值有变化，说明修复成功。

## 验证

确认驱动加载正确：

```bash
lsmod | grep xone
```

应看到以下模块：

```
xone_gip_gamepad
xone_wired
xone_gip
```

查看内核日志确认认证成功：

```bash
sudo dmesg | grep "gip_auth_complete_handshake"
```

## 注意事项

1. **不要再加载 xpad 驱动**。xone 安装时会自动禁用 xpad，手动加载会导致冲突。
2. **不要再加载 hid_xpadneo**。xone 不兼容 xpadneo，两者不能同时使用。
3. 如果更换 USB 口后手柄无响应，重新插拔即可。


## 故障排查

### 手柄识别但无输入

```bash
sudo dmesg | grep -i "gip\|xone" | tail -15
```

检查是否有 `gip_auth_complete_handshake`。如果没有，说明认证未完成，尝试重启电脑。

### 完全不识别

```bash
lsusb | grep -i microsoft
```

确认 USB 层面能检测到手柄。如果检测不到，检查 USB 线缆和接口。

### js0 设备不存在

```bash
cat /proc/bus/input/devices | grep -i "xbox\|xone"
```

查看手柄是否使用 evdev 接口（eventX 而非 jsX）。
