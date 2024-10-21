# Play - 框架：解析task

> 本节目标：了解task的执行流程

在上一节，我们简要分析了`SelectPlay.lua`的代码来理解Play的运行流程。在这一节，我们将继续深入，分析task的解析。
我们之前简化了`RunPlay`中的代码，现在让我们再深入一些：
::::{tab-set}
:::{tab-item} RunPlay in Play.lua
```{code-block} lua
:linenos:
function RunPlay(name)
    ...
    DoRolePosMatch(curPlay)
    ...
    for rolename, task in pairs(curPlay[gCurrentState]) do
        -- 排除非task的情况（例如switch函数，match匹配规则）
        if rolename ~= "switch" and rolename ~= "match" then
            -- 如果存在闭包，对task进行解包
            if type(task) == "function" then
                task = task(gRoleNum[rolename])
            end
            -- 解析当前执行的机器人号码
            local roleNum = gRoleNum[rolename]
            -- 执行task对应的cskill
            if roleNum ~= -1 then
                -- 执行除运动以外的task参数
                if task[3] ~= nil then
                    -- 包括踢球模式、目标朝向、踢球精度、踢球力度、以及特殊flag配置
                    local mkick = task[3](roleNum)
                    local mdir = task[4](roleNum)
                    local mpre = task[5](roleNum)
                    local mkp  = task[6](roleNum)
                    local mcp  = task[7](roleNum)
                    local mflag = task[8]

                    ... -- 判断并配置是否吸球
                    ... -- 判断并配置是否踢球

                end
            end

            -- 从lua端调用到c++-skill层
            task[1](roleNum)
        end
    end
end
```
:::
:::{tab-item} Task.lua
```{code-block} lua
:linenos:
function goSimplePos(p, d, f)
    ...
    local mexe, mpos = SimpleGoto{pos = p, dir = idir, flag = iflag}
    return {mexe, mpos}
end
```
:::
:::{tab-item} TestScript.lua
```{code-block} lua
:linenos:
...
{
    switch = ...,
    Leader = task.goSimplePos(CGeoPoint(0,0)),
    -- 结合task.lua，上述代码等效于Leader = {mexe, mpos}
    match = "(L)"
},
...
```
:::
:::{tab-item} SimpleGoto.lua
```{code-block} lua
function SimpleGoto(task)
    ...
    execute = function(runner)
        mpos = _c(task.pos,runner)
        mdir = _c(task.dir,runner)

        task_param = TaskT:new_local()
        ...
        return skillapi:run("Goto", task_param)
    end

    matchPos = function()
        return _c(task.pos)
    end

    return execute, matchPos
end
::::

我们观察`task.lua`中的`goSimplePos`函数，这个函数返回一个table，包含了两个元素，`mexe`和`mpos`。在`TestScript.lua`中，我们调用了`goSimplePos`函数，返回的table被赋值给了`Leader`，这个table中的两个元素被分别赋值给了`mexe`和`mpos`。在`RunPlay`函数中，我们通过`task[1](roleNum)`调用了`mexe`，这个函数会返回一个`execute`函数，这个函数会在`RunPlay`中被调用，执行`SimpleGoto`中的`execute`函数。在`execute`函数中，我们调用了`skillapi:run`函数，这个函数会调用`c++`层的`Goto`技能。

除此之外，`SimpleGoto.lua`中的`matchPos`函数即`task[2]`会返回一个目标点，这个目标点会在`RunPlay`的`DoRolePosMatch`中被调用，用于动态匹配。

你可以看到，从上述的`Play.lua`的第17行开始，有关于task列表参数的第3-第8项，这些项是用于配置踢球模式、目标朝向、踢球精度、踢球力度、以及特殊flag配置。所以你可以在`task.lua`中的某个函数返回8个参数，这样做的好处是可以直接将非运动的简单指令交给`lua`层处理实现与运动本身的**解耦**，在`c++`层只需要负责移动即可，这可以在类似于动态射门的skill中实现更出色的效果。