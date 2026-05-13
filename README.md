# 赛前调试与调参指南

## 目录

- [赛前必检项](#赛前必检项)
- [Step 1: Nor_Shoot 单车调试](#step-1-nor_shoot-单车调试)
  - [1.1 能否快速拿到球](#11-能否快速拿到球)
  - [1.2 能否正确转向目标点](#12-能否正确转向目标点)
  - [1.3 能否踢到目标点](#13-能否踢到目标点)
- [Step 2: Nor_Goalie 守门员调试](#step-2-nor_goalie-守门员调试)
  - [守门员选车建议](#守门员选车建议)
  - [守门员调试检查项](#守门员调试检查项)
- [参数速查表](#参数速查表)
- [常见问题排查](#常见问题排查)

---

## 赛前必检项

### `isReality` 参数 (最重要)

**文件**: `ZBin/lua_scripts/worldmodel/param.lua:45`

```lua
isReality = false   -- 仿真环境
isReality = true    -- 真实场地
```

**Important notice**: 
revise ZJHU' defend_num2 to a number which is not assigned to any a attacker, for example : 8 
which should not be assigned to Assiter, kicker, special, or center 



这个参数控制了大量行为差异，**赛前一定要确认**：

| 参数 | 仿真 (`false`) | 实物 (`true`) |
|---|---|---|
| `V_DECAY_RATE` (球摩擦) | 2100 | 900 |
| `rotCompensate` (旋转补偿) | 固定 0.05 | 按 `playerConfig` 读取 |
| `shootError` (射门误差容忍) | 8° | 5° |

**忘记切换会导致**：实物比赛时旋转补偿为仿真值、射门精度要求不同，行为异常。

### 其他全局参数确认

**文件**: `ZBin/lua_scripts/worldmodel/param.lua`

| 参数 | 位置 | 说明 |
|---|---|---|
| `our_goalie_num` | 第15行 | 守门员车号，从配置文件读取 |
| `defend_num1` | 第16行 | 后卫1车号 |
| `defend_num2` | 第17行 | 后卫2车号 |
| `playerVel` | 第53行 | 抢球速度上限，默认 1.88 |
| `getballMode` | 第54行 | 0=激进, 1=保守, 2=middle |
| `playerRadius` | 第75行 | 机器人半径，碰撞检测用 |
| `enemy_buffer` | 第69行 | 两点间有无敌人距离阈值 |

---

## Step 1: Nor_Shoot 单车调试

**目标**: 逐台机器人跑 Nor_Shoot 脚本，确认拿球 → 转向 → 射门全流程正常。

**测试方法**: 让每台机器人轮流以 Assister 角色执行 Nor_Shoot，观察三个阶段的输出。

### 1.1 能否快速拿到球

**观察指标**: 机器人从起步到吸住球耗时是否合理，是否追不上球、冲过头。

**相关参数**:

#### `playerConfig[num].isNewRobot`

| 值 | 行为 |
|---|---|
| `false` (默认) | 抢球时**始终开启** dribble 电机，适合吸球能力弱的老机器人 |
| `true` | 抢球时**红外检测到球后**才开 dribble，适合吸球强的新机器人 |

- 如果机器人吸球过猛导致球弹开 → 设为 `true`
- 如果机器人总是吸不住球 → 保持 `false`

#### `playerConfig[num].endVel`

机器人冲向球时的到达速度基准值，默认 500。

| 症状 | 调整方向 |
|---|---|
| 冲过头，球弹开 | 降低 endVel |
| 追不上球 | 提高 endVel |

#### `playerConfig[num].ballVelRate`

末端速度跟随球速的比例，实际末端速度 = `球速 × ballVelRate + endVel`。

| 症状 | 调整方向 |
|---|---|
| 球速快时接不住（相对速度过大） | 提高 ballVelRate，如 1.2 |
| 接球时冲太猛 | 降低 ballVelRate，如 0.5 |

#### `getballMode` (全局)

- `0` 激进模式：更快但容易失误
- `1` 保守模式：稳定但稍慢（默认）
- `2` middle：折中

---

### 1.2 能否正确转向目标点

**观察指标**: 拿到球后，机器人能否平稳地转向 `param.shootPos` 方向。

**调试界面**: 界面上会显示两条线：
- **绿色线**: 角度误差在容忍范围内，即将射门
- **红色线**: 角度误差过大，仍在调整

以及两个标记点：
- **rotCompensatePos**: 补偿后的预瞄点
- **ShootPos**: 实际目标点

**相关参数**:

#### `playerConfig[num].rotPos`

类型: `CGeoPoint(x, y)`

旋转参考偏移坐标，影响 TurnToPointV2 时机器人的旋转行为。

| 机器人类型 | 建议值 |
|---|---|
| 对称底盘 | `CGeoPoint(60, 60)` |
| 前置吸球器 / 偏心底盘 | `CGeoPoint(120, 0)` |

**调试**: 如果转向时球掉出，尝试调整 rotPos 使旋转中心更靠近球的保持区域。

#### `playerConfig[num].rotVel`

类型: 角速度 (rad/s)，默认 4.5

转向目标点的角速度上限。射向球门时会自动 +0.2。

| 症状 | 调整方向 |
|---|---|
| 转向太慢，错失射门时机 | 提高 rotVel |
| 转向太快，球甩掉 | 降低 rotVel |

#### `playerConfig[num].rotCompensate`

类型: 补偿系数，默认 -0.045

旋转预瞄补偿。实际补偿距离 = `角速度 × 到目标距离 × rotCompensate`。

- 仅 `isReality = true` 时使用此值
- 仿真模式固定使用 0.05

| 症状 | 调整方向 |
|---|---|
| 转完之后角度偏左/右 | 调整 rotCompensate |
| 转向到位后还在摆动 | 降低绝对值 |

**调试方法**: 观察界面上 `rotCompensatePos` 点相对于 `ShootPos` 的偏移，如果偏移方向不对，取反系数符号；偏移过大则减小绝对值。

#### `shootError` (全局)

射门角度误差容忍度（度）：
- 实物 (`isReality=true`): `5°`
- 仿真 (`isReality=false`): `8°`

只有角度误差小于此值才会触发射门。如果机器人总是转不到射门角度就卡住，可适当放大。

---

### 1.3 能否踢到目标点

**观察指标**: 踢出后球是否朝目标点飞去，力度是否合适。

**相关参数**:

#### `playerConfig[num].power`

```lua
power = {minDist, maxDist, minPower, maxPower, shootPower, chipPower}
-- 例:  {0,       6000,    135,      330,      500,        7000}
```

| 索引 | 名称 | 说明 |
|---|---|---|
| [1] | minDist | 最小踢球距离 |
| [2] | maxDist | 最大踢球距离 |
| [3] | minPower | 最小踢球力度 |
| [4] | maxPower | 最大踢球力度 |
| [5] | shootPower | 射门力度 (朝球门 flat 踢) |
| [6] | chipPower | 挑球力度 (chip 踢) |

**力度计算**:
```
普通踢: 力度 = Utils.map(到球距离, minDist, maxDist, minPower, maxPower)
射门:   力度 = shootPower
挑球:   力度 = chipPower
```

**调试建议**:

| 症状 | 调整方向 |
|---|---|
| 踢球无力 / 球滚不到目标 | 提高 minPower / maxPower / shootPower |
| 踢球过猛 / 球飞出界 | 降低对应力度 |
| 近距离踢太猛 | 降低 minPower |
| 远距离踢不到 | 提高 maxPower 或增大 maxDist |
| 挑球过低 / 不过人墙 | 提高 chipPower |
| 挑球过高 / 不受控 | 降低 chipPower |

> **注意**: `shootPower` 是射向球门时使用的固定力度（flat 踢），不在距离映射范围内。一般设为比 maxPower 大一点的值。

---

## Step 2: Nor_Goalie 守门员调试

### 守门员选车建议

守门员是最关键的角色，**优先分配能力最强的机器人**。

**硬性要求**:

1. **能够挑球 (chip)** — 守门员清除球时使用 `kick.chip()`，该机器人必须挑球机构正常
2. **能够正常吸球** — 守门员需要稳定吸住球后再转向踢出，吸球不稳定的机器人不适合

**选车优先级**: 吸球稳定 + 挑球正常 > 踢球力度大 > 转向快

**配置守门员车号**: 在配置文件中修改 `ZJHU/our_goalie_num`，或修改 `param.lua:15`：
```lua
our_goalie_num = CGetSettings("ZJHU/our_goalie_num", "Int")
```

### 守门员调试检查项

**脚本**: `Core/HuRocos-2024/play/Nor_Goalie.lua`

守门员有四个状态：

| 状态 | 行为 | 检查项 |
|---|---|---|
| `goalie_norm` | 守门移动 | 是否在球门前合理移动，是否能拦截射门 |
| `goalie_getBall` | 抢球 | 是否能快速吸住球 |
| `turnToPoint` | 转向 | 拿到球后能否转向 `goalieTargetPos` |
| `goalie_kick` | 踢球 | 挑球力度是否合适，球是否清出危险区 |

**守门员相关全局参数**:

| 参数 | 默认值 | 说明 |
|---|---|---|
| `goalieTargetPos` | CGeoPoint(2000, 0) | 守门员踢球目标点 |
| `goalieDribblingFrame` | 200 | 拿到球后带球最大帧数 |
| `goalieReadyFrame` | 20 | 吸球后准备时间 |
| `goalieStablePoint` | 禁区中心偏前 | 吸球后缓慢移动的稳定点 |
| `goalieCatchBuf` | playerRadius × 2 | 截球距离阈值 |
| `goalieBuf` | 0 | 守门员缓冲距离 |

**调试要点**:

- 守门员的踢球力度同样由 `playerConfig[守门员车号].power` 控制，主要看 `chipPower`
- 如果守门员挑球力度不够，提高 `chipPower`
- 如果守门员转向太慢，提高 `rotVel`
- 守门员的 `rotCompensate` 同样影响转向精度

---

## 参数速查表

### playerConfig 完整字段 (按车号配置)

**文件**: `ZBin/lua_scripts/worldmodel/param.lua`

```
playerConfig[车号] = {
    power         = {minDist, maxDist, minPower, maxPower, shootPower, chipPower},
    rotPos        = CGeoPoint(x, y),
    rotVel        = 4.5,
    rotCompensate = -0.045,
    endVel        = 500,
    ballVelRate   = 1,
    isNewRobot    = false,
}
```

| 字段 | 类型 | 默认值 | 一句话说明 |
|---|---|---|---|
| `power` | {6项数组} | {0,6000,135,330,500,7000} | 踢球力度参数 |
| `rotPos` | CGeoPoint | (60,60) | 旋转参考偏移 |
| `rotVel` | number | 4.5 | 转向角速度上限 |
| `rotCompensate` | number | -0.045 | 旋转预瞄补偿系数 (仅实物) |
| `endVel` | number | 500 | 接球到达速度基准 |
| `ballVelRate` | number | 1 | 球速跟随比例 |
| `isNewRobot` | boolean | false | 新机器人: 红外后才开dribble |

> 未配置的车号自动使用 `_defaultConfig` 兜底，不会报错。

### 全局参数速查

| 分类 | 参数 | 文件位置 | 说明 |
|---|---|---|---|
| **环境** | `isReality` | param.lua:45 | **必检!** false=仿真, true=实物 |
| **场地** | `pitchLength` | param.lua:22 | 场地长度 (从配置读取) |
| **场地** | `pitchWidth` | param.lua:23 | 场地宽度 (从配置读取) |
| **抢球** | `playerVel` | param.lua:53 | 抢球速度上限 |
| **抢球** | `getballMode` | param.lua:54 | 0=激进, 1=保守, 2=middle |
| **射门** | `shootError` | param.lua:264 | 射门角度容忍 (实物5°/仿真8°) |
| **射门** | `shootPos` | param.lua:82 | 射门目标点 |
| **红外** | `playerInfraredCountBuffer` | param.lua:65 | 红外判断缓冲值 |
| **球权** | `playerBallRightsBuffer` | param.lua:64 | 球权判断缓冲值 |
| **敌人** | `enemy_buffer` | param.lua:69 | 两点间敌人检测距离 |
| **角色** | `our_goalie_num` | param.lua:15 | 守门员车号 |
| **角色** | `defend_num1` | param.lua:16 | 后卫1车号 |
| **角色** | `defend_num2` | param.lua:17 | 后卫2车号 |

---

## 常见问题排查

### 抢球阶段

| 症状 | 可能原因 | 排查方向 |
|---|---|---|
| 机器人追不上球 | 速度太低 | 提高 `endVel` 或 `playerVel` |
| 冲过头，球弹开 | dribble 开太早 | 设 `isNewRobot = true`，或降低 `endVel` / `ballVelRate` |
| 吸不住球，球漏出 | dribble 未开 | 确认 `isNewRobot = false`（旧机器人默认开dribble） |
| 绕球跑圈不靠近 | getballMode 太保守 | 改 `getballMode = 0` 激进模式 |

### 转向阶段

| 症状 | 可能原因 | 排查方向 |
|---|---|---|
| 转向慢，迟迟不射门 | rotVel 太低 | 提高 `rotVel` |
| 转向时球甩掉 | rotVel 太高 或 rotPos 不对 | 降低 `rotVel`，调整 `rotPos` |
| 转到位后角度偏 | rotCompensate 不对 | 调整 `rotCompensate` 系数 |
| 一直在转不停 | shootError 太小 | 适当放大 `shootError` |

### 射门阶段

| 症状 | 可能原因 | 排查方向 |
|---|---|---|
| 球力度不足 | power 参数过低 | 提高 `shootPower` / `minPower` / `maxPower` |
| 球飞出界 | 力度过大 | 降低对应力度参数 |
| 近距离踢飞 | minPower 过高 | 降低 `power[3]` |
| 不射门 | 角度始终不达标 | 检查 `shootError` 是否过小，检查红外是否丢失 |

### 守门员

| 症状 | 可能原因 | 排查方向 |
|---|---|---|
| 不上前扑球 | goalieBuf 过小 | 增大 `goalieBuf` |
| 拿到球踢不出去 | chipPower 不足 | 提高 `power[6]` |
| 挑球撞人墙 | chipPower 过大或方向不对 | 降低 `chipPower`，检查 `goalieTargetPos` |
| 拿到球后球掉了 | 吸球不稳 | 换一台吸球稳定的机器人 |

---

## 调参流程总结

```
1. 确认 isReality (仿真=false, 实物=true)
   ↓
2. 确认场地配置 (pitchLength, pitchWidth)
   ↓
3. 逐台机器人跑 Nor_Shoot:
   ├── 拿球测试  → endVel, ballVelRate, isNewRobot
   ├── 转向测试  → rotPos, rotVel, rotCompensate
   └── 射门测试  → power[1~6]
   ↓
4. 选最优机器人当守门员 (吸球稳+能挑球)
   ↓
5. 跑 Nor_Goalie 测试守门员
   ├── 拦截是否到位
   ├── 吸球是否稳定
   └── 挑球是否清出危险区
   ↓
6. 全队跑 NORMALPLAYV2 综合测试
```
