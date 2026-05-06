# Rocos 2026 (ROCOS 省赛分支)

基于 [Robocup-ssl-China/rocos](https://github.com/Robocup-ssl-China/rocos) 的 grSim 仿真控制分支，支持手柄手动控制 + DribbleGo 盘带模式。

## 快速开始

### 1. 连接 grSim

1. 启动 grSim
2. 打开 Client，进入 **Vision** 界面
3. 在网卡下拉框中选择你的网卡
4. 在 **grSim IP** 下拉框中选择 grSim 所在的 IP，点击连接
5. Vision 连接图标点亮即表示连接成功

### 2. 启动脚本

1. 在 **Core** 区域点击启动按钮（蓝色/黄色按钮）
2. 在 Test Script 下拉框中选择 **TestMyRun** 脚本
3. 勾选 TEST 复选框启动脚本

### 3. 启动手柄控制

1. 点击右侧顶部 Tab 栏的**游戏手柄图标**，进入 Manual Control 界面
2. 将开关拨到 **ON**
3. Input 选择 **Gamepad**
4. 设置 **Robot ID**（只能选择 **1** 或 **2**，否则可能出问题）
5. Team 选择对应队伍

## 手柄操作

| 按键 | 功能 |
|------|------|
| 左摇杆 | 控制机器人移动 |
| 右摇杆 | 控制机器人朝向 |
| **X** | 触发 `task.getball`，机器人自动抢球（按住生效，松开失效，此时移动/方向键无效） |
| **Y** | 触发 `Nor_Shoot` 子脚本：抢球 → 转向最佳射门点 → 角度合理后射门 |
| **B** | 同 Y，但射门目标为队友位置（传球） |
| **LB** | 踢球，力度与右摇杆偏移量有关 |
| **LT** | 挑球开关，按住 LT 再按 LB 可挑球（开发中） |
| **RB** | 吸球开关，按一下开启/关闭吸球状态（Client 中机器人会显示绿圈） |
| **RT** | DribbleGo 模式：RB 开启时，按住 RT + 移动方向键，机器人会背对移动方向拉球，使盘带更平滑稳定 |

### DribbleGo 说明

省赛 grSim 的吸球力度较小，只有沿机器人-球正方向或反方向移动时才不易掉球。DribbleGo 通过 CircleRun 旋转算法让机器人自动面朝移动反方向，实现更稳定的盘带。

## 参数说明

Manual Control 界面中的可调参数：

| 参数 | 范围 | 默认值 | 说明 |
|------|------|--------|------|
| Robot ID | 0-15 | 1 | 控制的机器人编号（建议选 1 或 2） |
| Team | Blue/Yellow | Blue | 队伍选择 |
| Max Speed | 0.5-6.0 m/s | 1.2 | 最大移动速度 |
| Kick Pwr | 0-10.0 | 5.0 | 踢球力度 |
| Slow Spd | 0.1-3.0 m/s | 1.0 | 缓速移动速度（精确控制） |
| Accel | 0.1-30.0 | 1.6 | 加速度 |
| Decel | 0.1-30.0 | 12.0 | 减速度 |
| Rot Kp | 0.1-20.0 | 6.5 | 朝向控制比例增益 |
| Rot Kd | 0-10.0 | 0 | 朝向控制微分增益 |
| DG CX | 0-300 mm | 120 | DribbleGo 旋转中心 X（局部坐标系） |
| DG CY | -300-300 mm | 0 | DribbleGo 旋转中心 Y（局部坐标系） |
| DG Speed | 1.0-20.0 rad/s | 4.5 | DribbleGo 旋转速度 |
| DG Angle | 5-90° | 20 | DribbleGo 角度阈值（小于此值切换为 PD 控制） |
| Auto Face | ON/OFF | OFF | 开启后，右摇杆无输入时机器人自动朝向移动方向 |
| Brake | 0.0-10.0 | 0.5 | 松手时反向制动速度比例（0 = 纯减速，越大刹车越猛） |

> 所有参数会自动保存到 `zss.ini` 的 `[Manual]` 节，重启后保留。

## 脚本说明

### gamepad.lua (`ZBin/lua_scripts/worldmodel/gamepad.lua`)

手柄按键映射和技能系统：

- `pressed_map`：SDL 按键 ID → 按键名称的映射
- `skill_map`：按键名称 → 技能任务的映射
  - **X** → `task.getball` 抢球
  - **Y** → `Nor_Shoot` 射门（计算最佳射门点）
  - **B** → `Nor_Shoot` 传球（目标为队友位置）

### TestMyRun.lua (`Core/tactics/play/TestMyRun.lua`)

主测试脚本，分两个状态：

1. `init`：初始化 `Nor_Shoot` 和 `Nor_Goalie` 子脚本
2. `skill`：Leader 角色由手柄 `gamepad.skill()` 控制，Goalie 执行守门逻辑

### param.lua (`ZBin/lua_scripts/worldmodel/param.lua`)

全局参数配置，关键参数：

| 参数 | 说明 |
|------|------|
| `playerVel` | 机器人速度（用于 getball 预判） |
| `getballMode` | 抢球模式：0-激进，1-保守，2-中等 |
| `shootKp` | 射门力度系数 |
| `shootPos` | 默认射门目标点 |
| `powerPowerSim` | 模拟器踢球力度参数 `{minDist, maxDist, minPower, maxPower, shootPower, chipPower}` |
| `rotVel` / `rotPos` | CircleRun 旋转速度和旋转参考点 |

## 编译

```bash
mkdir build && cd build
cmake ..
make -j$(nproc)
```

运行：`./ZBin/Client` 和 `./ZBin/Core`

## 常见问题

- Linux 串口权限不足：

  ```bash
  sudo usermod -a -G dialout $USER
  ```

  执行后 Log Out 重新登录即可。

- 手柄连接后显示 "Not found"：确认手柄已连接，检查 SDL 是否识别到设备。

## 致谢

基于 [Robocup-ssl-China/rocos](https://github.com/Robocup-ssl-China/rocos) 开发。

