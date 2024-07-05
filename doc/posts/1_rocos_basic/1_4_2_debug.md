# 调试 - `debugEngine`

> 在之前的章节中，你可能已经注意到了Client界面上，存在很多用于调试的信息。包括了各色的文字/线条/圆弧等。这一节我们将详细介绍调试系统以及如何使用它快速的调试代码。

## 调试系统的通讯以及接口定义

调试系统可以简单分为`Core`的发送以及`Client`的绘制两部分组成，我们直接从`Core`的发送协议来研究调试系统的接口定义：
:::{card} zss_debug.proto 部分代码
```{code-block} protobuf
:linenos:

message Debug_Msg {
	enum Debug_Type {
        ...
	}
	enum Color {
        ...
	}
	Debug_Type type = 1;
	Color color = 2;                 // 颜色的enum值
	Debug_Robot robot = 3;           // 机器人
	Debug_Line line = 4;             // 线段
	Debug_Arc arc = 5;               // 圆弧
	Debug_Polygon polygon = 6;       // 多边形
	Debug_Text text = 7;             // 文字
	Debug_CubicBezier bezier = 8;    // 贝塞尔曲线
	Debug_Points points = 9;         // 多个点
	int32 RGB_value = 10;            // custom颜色时的RGB值
}
message Debug_Msgs{
	repeated Debug_Msg msgs = 1;
}
```
:::

上述代码来自于`zss_debug.proto`，这是`Core`与`Client`之间的通讯协议，我们可以看到`Debug_Msg`中包含了很多绘制的信息，包括了`线段`/`圆弧`/`多边形`/`文字`/`贝塞尔曲线`/`点集`等。这些信息会打包成一个`Debug_Msgs`发送给`Client`解析并绘制到界面上。

## 在c++中使用debugEngine

在rocos-Core中，调试系统的调用均需要通过全局单例来调用，例如在已有的Skill中，添加如下代码：
```{code-block} cpp
:linenos:
#include "GDebugEngine.h"

// in skill plan function
void Skill_XXX::plan(...){
    ...
    GDebugEngine::Instance()->gui_debug_x(CGeoPoint(0,0));
    GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(0,0), "Hello World");
    ...
}
```
编译运行代码，你将在Client上看到如下效果：
```{thumbnail} ../../img/1_4_2_debug_hello.png
    :width: 70%
    :align: center
```

c++中的调试系统接口在`GDebugEngine.h`中定义，简化过后的接口如下：

:::{card} GDebugEngine.h 部分代码
```{code-block} cpp
:linenos:

    // 在指定点绘制叉
    void gui_debug_x(
        const CGeoPoint& p,           // x符号的位置
        int debug_color = 1,          // 颜色enum值（10为自定义颜色）
        int RGB_value=0,              // 自定义颜色的RGB值
        const int size = 60 /*mm*/    // x符号的大小
    );

    // 在指定的多个点绘制叉
    void gui_debug_points(
        const std::vector<CGeoPoint> points, // 点集
        int debug_color = 1,                 // 颜色enum值（10为自定义颜色）
        int RGB_value=0                      // 自定义颜色的RGB值
    );

    // 绘制一个线段
    void gui_debug_line(
        const CGeoPoint& p1,          // 线段的起点
        const CGeoPoint& p2,          // 线段的终点
        int debug_color = 1,          // 颜色enum值（10为自定义颜色）
        int RGB_value=0               // 自定义颜色的RGB值
    );

    // 绘制一个圆弧
    void gui_debug_arc(
        const CGeoPoint& p,           // 圆弧的圆心
        double r,                     // 圆弧的半径
        double start_angle,           // 圆弧的起始角度
        double span_angle,            // 圆弧的角度范围
        int debug_color = 1,          // 颜色enum值（10为自定义颜色）
        int RGB_value=0               // 自定义颜色的RGB值
    );

    // 绘制一个机器人形状
    void gui_debug_robot(
        const CGeoPoint& p,           // 机器人的位置
        double robot_dir,             // 机器人的朝向
        int debug_color = 1,          // 颜色enum值（10为自定义颜色）
        int RGB_value=0               // 自定义颜色的RGB值
    );

    // 绘制一段text
    void gui_debug_msg(
        const CGeoPoint& p,           // text的位置
        const char* msgstr,           // text的内容
        int debug_color = 1,          // 颜色enum值（10为自定义颜色）
        int RGB_value=0,              // 自定义颜色的RGB值
        const double size=120 /*mm*/, // text的大小
        const int weight=50/*0-100*/  // text的粗细
    );
```
:::
## 在lua中使用debugEngine

在lua中使用debugEngine时，接口定义与c++完全一致，定义文件在`gdebugengine.pkg`中。由于lua的Play中，不存在像skill的plan函数一样的，我们可以封装成函数放进switch函数中，例如：
```{code-block} lua
local drawDebug = function()
    debugEngine:gui_debug_msg(CGeoPoint(0,0),"Hello from lua",param.BLUE)
    debugEngine:gui_debug_x(CGeoPoint(0,0),param.GREEN)
    debugEngine:gui_debug_arc(ball.pos(), 100, 0, 360, param.ORANGE)
    debugEngine:gui_debug_msg(ball.pos(), "ball is here!", param.GREEN)
end

return {
    firstState = "ready",

    ["ready"] = {
        switch = function()
            drawDebug()
        end,
        match = ""
    },
    name = "TestScript",
}

```
在任意脚本中添加上述代码（需要注意name部分配置正确），运行后你将在Client上看到如下效果：
```{thumbnail} ../../img/1_4_2_debug_hello2.png
    :width: 70%
    :align: center
```
## 一些框架中已有的调试信息
或许你已经注意到了，运行代码时，即使你没有书写任何与调试系统有关的代码，在Client界面中也会有一些调试信息。这些信息是由框架中的调试系统自动生成的，例如：
- 当前运行的脚本信息/状态信息
- 是否为Test模式
- 当前收到的裁判盒指令

这些信息都作为框架的一部分，会在运行时自动显示在Client界面上，方便你快速的了解当前的运行状态。除了这些，你还可以通过更改参数系统的一些选项，来增加调试休息。你甚至可以结合参数系统和调试系统，自己配置自己的调试信息，并在平时训练/比赛中用到他们。

### 已有的部分调试参数

| 参数 | 用途 | 输出 |
| --- | --- | --- |
| `Debug/A_LuaDebug` | 当`lua`运行出错时是否显示错误信息 | 具体报错信息 |
| `Debug/DeviceCmd` | 显示`Core`下发给机器人的指令信息 | 速度/吸球/平挑射/踢球力度 |
| `Debug/DeviceMsg` | 显示由机器人的反馈信息 | 红外信息/踢球信息 |
| `Debug/DrawObst` | 显示障碍物信息 | 所有机器人用于规划的障碍物的位置/形状 |
| `Debug/RoleMatch` | 显示角色匹配信息 | N个机器人匹配M个任务的代价矩阵 |
| `Debug/SmartTargetPos` | 显示路径规划的下一个中间目标点 | 以`✕`显示 |
| `Debug/TargetPos` | 显示最终目标点 | 以`✕`显示 |
| `Debug/Touch` | 与`Skill-Touch`有关的调试信息 | 截球点/计算中间值 |

### 配合参数系统的调试流程

你可以像当前Rocos系统自带的一些调试参数一样，在书写一个新的脚本或者技能时，通过增加参数来控制调试信息的输出。流程如下：
* 在你要调试的地方，增加一个参数，例如`Debug/MyDebug`，默认为`false`
* 在你的代码中，增加一个判断，当`Debug/MyDebug`为`true`时，输出调试信息
* 在运行时，通过参数系统，将`Debug/MyDebug`设置为`true`，即可看到调试信息

这样的调试，可以用在lua/c++的任意地方，方便你在调试时快速的开启/关闭调试信息。