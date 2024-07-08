# Play - 框架：创建与选择Play

> 本节目标：了解Play的运行框架

## Play的运行框架

让我们尝试梳理一下lua的总体结构，以及Play的运行框架。
从c++到lua是使用了`LuaModule`中的一个封装函数`RunScript`，该函数使用`luaL_loadfile`这样一个lua的标准库函数来加载lua文件，然后使用`lua_pcall`来执行lua文件。在执行过程中，如果lua文件中有报错，c++层会捕获报错信息并输出到控制台和调试系统中，最终显示在`Client`界面上。

在c++的`DecisionModule`中，共出现了两次对`LuaModule`的`RunScript`函数的调用来执行脚本，一次是在`DecisionModule`的构造函数中，调用了`StartZeus.lua`用于初始化整个lua框架，另一次是在`DecisionModule`的`DoDecision`函数中，调用了`SelectPlay.lua`用于每帧的具体策略执行。

###### lua框架的初始化

:::{card} StartZeus.lua
```{code-block} lua
:linenos:
-- 设置随机数种子，保证后续的随机数是不同的
math.randomseed(os.time())
-- 设置模块的索引路径
package.path = package.path .. ";./lua_scripts/?.lua"

-- 加载模块
require("Config")
require("RoleMatch")
require("Zeus")
```
:::

以`StartZeus.lua`作为入口，分别加载了`Config/RoleMatch/Zeus`三个模块。在旧版本中，`Config.lua`中使用table完成所有的脚本/cskill的设置工作并在`Zeus.lua`中完成初始化。在新版本中，脚本/cskill的设置工作被自动扫描的方式替代（战术包），`Config.lua`中只保留了一些全局变量的设置。`RoleMatch.lua`中完成了角色匹配的工作，`Zeus.lua`中完成了整个lua框架的初始化工作，这其中值的一提的是对于所有play脚本的初始化。

针对某个脚本的初始化工作，是通过lua的`dofile`函数完成的。`dofile`函数会加载并执行一个lua文件，这个文件中的代码会被执行。我们来分析一个play脚本的初始化工作：

:::{card} TestScript.lua
```{code-block} lua
:linenos:
local xxx = 1 -- 局部变量
gPlayTable.CreatePlay{
firstState = "...",
-- 多个状态
["stateName"] = {
	switch = ...,
    ..., -- 多个需要执行的task
	match = ""
},
...
name = "TestRun",
}
```
:::

在脚本的开始，会定义一些在接下来的脚本中用到的局部变量。然后上述代码的第2行到最末行，是一个`gPlayTable.CreatePlay`函数的调用，这个函数会在`gPlayTable`中创建一个play存储在全局的表中。调用函数时会传入一个table，这个table中包含了play的所有信息，例如`firstState`、`state`、`switch`、`match`等。这个函数会返回一个play的名字，这个名字会被用于后续的调用。

:::{admonition} 提示
调用`dofile`函数是为了将一个play脚本的信息存储在`gPlayTable`中，在后续的运行中，我们不会再直接运行这个脚本文件本身了，这也是为什么在`task.xxx()`中我们需要通过闭包的方式传递动态参数。
:::

###### 每帧的具体策略执行

:::{card} SelectPlay.lua 简化版
```{code-block} lua
:linenos:

-- 扫描战术包配置，选择裁判指令对应的脚本
function chooseRefConfigScript(choice)
    ...
    return playName -- 返回的是脚本的name
end

-- 选择裁判指令脚本
function RunRefScript(name)
    if USE_CUSTOM_REF_CONFIG then
        -- 有战术包配置时的处理
        gCurrentPlay = chooseRefConfigScript(name)
    else
        -- 无战术包配置（兼容旧版本）
        dofile(...)
    end
end

-- 判定是否需要进入裁判指令脚本
function SelectRefPlay()
    ...
    RunRefScript(curRefMsg)
    ...
end

-- 主函数
if SelectRefPlay() then
    ...
else
    if IS_TEST_MODE then
        gCurrentPlay = gTestPlay
    else
        gCurrentPlay = gNormalPlay
    end
end

RunPlay(gCurrentPlay)
```
:::
上述代码有部分简化，但足以表达整体逻辑。每帧调用`SelectPlay.lua`核心目的就是选择一个play作为当前执行的脚本，即`gCurrentPlay`。需要考虑的因素有：
- 当前裁判指令
- 是否使用战术包配置
- 是否为测试模式

---
在选择完当前play后，调用`RunPlay`函数执行当前play的逻辑，在`RunPlay`函数中，会依次执行以下几个步骤：
- 获取当前脚本的状态
- 获取当前状态中的`switch`函数/`match`值/所有task的集合
- 执行`switch`函数维护脚本状态
- 执行`match`函数匹配task
- 执行task对应的cskill

下面是`RunPlay`函数的简化版，你可以在`Play.lua`中找到完整代码：

:::{card} RunPlay函数 简化版
```{code-block} lua
:linenos:
function RunPlay(name)
    -- 获取当前脚本
    local curPlay = gPlayTable(name)
    -- 更新当前脚本状态
    local curState = _RunPlaySwitch(curPlay, gCurrentState)
    -- 根据状态跳转进行相应的更新和维护（例如bufcnt等）
    ...
    -- 执行角色匹配
    DoRolePosMatch(curPlay)
    -- 执行task
    for rolename, task in pairs(curPlay[gCurrentState]) do
        ...
        -- 执行task对应的cskill
        task()
    end
end
```
:::
希望上面的解释能帮助你理解Play的运行框架。如何你阅读了rocos中的相关代码，会发现实际的代码与上述流程保持一致但还有更多的细节。这是由于lua本身作为一个只有部分支持OOP（面向对象编程）特性的语言，想要实现流程控制和状态维护，需要一些额外的工作。

我们将在之后章节更细致的解释`RunPlay`中与task解析相关的逻辑，以及lua中的常见报错信息。
