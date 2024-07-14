# 调试 - 参数系统

> 在调试机器人系统时，经常会遇到需要频繁调整的参数。Rocos针对这样的场景提供了参数系统，参数系统存储在本地ini文件中，可以通过Client的界面进行修改。

```{thumbnail} ../../img/1_4_1_settings.png
    :width: 70%
    :alt: 参数系统
    :align: center
```

想要修改参数，首先打开Client并切换到“Settings”选项卡（第四栏）。支持的参数类型有：`Bool` (布尔值)、`Int` (整数)、`Float` (浮点数)、`String` (字符串)。在界面中，可以看到当前所有的参数。想要修改参数，除`Bool`可以直接点击修改外，其他类型的参数在点击对应的值后会出现修改框，在修改完成后需要按回车键确认修改。

## 使用参数

我们以`CircleRun`中的代码为例，来讲解如何在c++中使用参数。

```cpp
// 1. 引入头文件
#include "parammanager.h"

// 2. 创建对应的参数
namespace {
    double MAX_ACC = 6000; // 最大加速度
    double MAX_ROT_ACC = 50; // 最大旋转加速度
    bool DEBUG = false; // 是否开启调试信息可视化
}

// 3. 在构造函数中读取并初始化参数
CCircleRun::CCircleRun(){
    ZSS::ZParamManager::instance()->loadParam(MAX_ACC,"CircleRun/MAX_ACC",6000);
    ZSS::ZParamManager::instance()->loadParam(MAX_ROT_ACC,"CircleRun/MAX_ROT_ACC",50);
    ZSS::ZParamManager::instance()->loadParam(DEBUG,"CircleRun/DEBUG",false);
}
```

通过上述代码，我们可以在c++中使用参数。其中`loadParam`函数的参数依次为：参数变量、参数名、默认值。在构造函数中，我们通过`loadParam`函数读取参数的值，如果参数不存在，则使用默认值。

类似的接口也可以在lua中使用，我们以`config.lua`中的代码为例：
    
```lua
IS_YELLOW = CGetSettings("ZAlert/IsYellow","Bool")
local team = IS_YELLOW and "Yellow" or "Blue"
IS_TEST_MODE = CGetSettings("ZAlert/"..team.."_IsTest","Bool")
```

`config.lua`是rocos的lua框架中最先解析的模块，所以存储了所有需要初始化的参数。在上述代码中，我们通过`CGetSettings`函数读取参数的值，第一个参数为参数名，第二个参数为参数类型。上述代码读取了`ZAlert/IsYellow`和`ZAlert/xxx_IsTest`两个参数的值以确定当前启动队伍的颜色，以及是否使用测试脚本。

## 参数文件

参数文件存储在`rocos/ZBin/zss.ini`中，如果想要重新初始化，可以直接删除文件。

::: tip
参数文件被添加到了gitignore中，所以git不会追踪参数的修改。如果需要同步参数，可以手动添加到git中或直接同步文件。
:::

## 其他接口

上述的`loadParam`完整接口如下：
    
```cpp
    bool loadParam(QChar&, const QString&, QChar d = 0);
    bool loadParam(int&, const QString&, int d = 0);
    bool loadParam(double&, const QString&, double d = 0);
    bool loadParam(QString&, const QString&, QString d = "");
    bool loadParam(bool&, const QString&, bool d = false);
```

除了上面使用的`loadParam`，`parammanager`还有其他接口可以使用：

```cpp
    // 使用参数名直接修改参数
    bool changeParam(const QString&, const QVariant&);
    bool changeParam(const QString&, const QString&, const QVariant&);
    
    // 直接获取value作为返回值，如果参数不存在则返回默认值，一般会配合Qvariant的toXXX函数用作const变量的初始化
    QVariant value(const QString&, const QVariant& defaultValue = QVariant());
    QVariant value(const QString&, const QString&, const QVariant& defaultValue = QVariant());
```

在下一节中，我们会介绍调试系统，并讲解如何使用参数系统来简化调试过程。