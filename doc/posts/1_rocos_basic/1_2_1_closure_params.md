# Play - 让机器人动态响应

> 在上一节中，我们了解了如何创建一个基本的play让机器人两点运动，你发现了吗？在这个play中，机器人的行为是固定的，很难做出一些高动态的行为，例如绕球转。在这一节中，我们学习如何添加动态参数让task变得更灵活，也会学习到在书写play时至关重要的概念 - **闭包**。

## 闭包

在学习闭包之前，我们先来看一个例子：


```{code-block} lua
:linenos:
function f(num)
    local i = 0
    return function()
        i = i + num
        return i
    end
end

local g,h = f(2),f(3)
print(g(),h()) -- 2 3
print(g())     -- 4
print(g(),h()) -- 6 6
```

在这个例子中，我们定义了一个函数`f`，它接受一个参数`num`，返回一个函数。这个函数内部定义了一个局部变量`i`，并返回一个匿名函数。这个匿名函数每次调用时，`i`的值会增加`num`。我们可以看到，`g`和`h`是两个不同的闭包，局部变量之间不会相互影响。

闭包是一种函数，它可以访问其词法范围内的变量。闭包是一种非常强大的工具，可以用来实现许多功能，例如：函数工厂、延迟计算、状态保持等。

## 动态参数
我们截取上节代码中的一行来观察：

```{code-block} lua
Leader = task.goCmuRush(CGeoPoint(0,0)),
```

在这行代码中，我们调用了`task.goCmuRush`函数，传入了一个`CGeoPoint`类型的参数。这个参数是固定的，我们无法在运行时改变它。如果我们想要让机器人在运行时动态地改变目标点，我们可以使用闭包来实现。

我们可以将上面的代码改写为：

```{code-block} lua
local target = function
    return CGeoPoint(0,0)
end
Leader = task.goCmuRush(target),
```

在这个例子中，我们将`CGeoPoint`类型的参数改为了一个函数，这个函数返回了一个`CGeoPoint`类型的值。这样，我们就可以在运行时动态地改变目标点。例如：

```{code-block} lua
local targetMoveSpeed = 1000 -- mm/s
local target = function()
    return CGeoPoint(0,0) + Utils.Polar2Vector(targetMoveSpeed, 0) / param.frameRate * vision:getCycle()
end
...
{
    ...
    Leader = task.goCmuRush(target),
    ...
},
```

在这个例子中，我们定义了一个`targetMoveSpeed`变量，表示机器人的移动速度。我们在`target`函数中，每次调用时，返回一个新的目标点，这个目标点是当前位置加上一个位移向量。这样，我们就可以实现机器人的动态移动。

对上述代码稍作修改，我们就可以实现机器人的绕球转：

```{code-block} lua
local rotSpeed = math.pi / 2 -- rad/s
local rotRadius = 500 -- mm
local target = function()
    return ball.pos() + Utils.Polar2Vector(rotRadius, rotSpeed / param.frameRate * vision:getCycle())
end
...
```
实现的效果如下：

```{thumbnail} ../../img/1_2_1_run_circle.gif
    :width: 70%
    :align: center
```

完整的脚本代码如下：

```{code-block} lua
:linenos:
local rotSpeed = math.pi / 2 -- rad/s
local rotRadius = 500 -- mm
local target = function()
    return ball.pos() + Utils.Polar2Vector(rotRadius, rotSpeed / param.frameRate * vision:getCycle())
end

return {
    firstState = "ready",

    ["ready"] = {
        switch = function()
        end,
        Leader = task.goCmuRush(target),
        match = "[L]"
    },
    name = "TestMyRun",
}
```

:::{note}
对于`task.goCmuRush`函数，可以做到传入值或传入闭包，是因为在`task.goCmuRush`函数内在运行时会根据传入参数类型动态解包，这是一种常见的设计模式。这样的方式在rocos的lua框架中被大量运用以应对更多的动态性需求。在你编写自己的函数时，也可以考虑这种设计模式使其变得更加灵活。