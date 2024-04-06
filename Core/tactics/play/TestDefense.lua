local initPos = {
    -- 守门，后卫北，后卫南
    CGeoPoint:new_local(),
    CGeoPoint:new_local(),
    CGeoPoint:new_local()
}

gPlayTable.CreatePlay {
    firstState = "init",

    -- 初始状态守点
    ["init"] = {
        switch = function()
            --TODO: 回到初始位置
        end,

        match = "[TODO:]"
    },

    -- 后卫，检测到球靠近，去扑球
    ["defense1"] = {
        switch = function()
            Utils.GlobalComputingPos(vision, player.pos("Defender"))


            if player.toTargetDist("Assister") < 1000 then
                return "pass"
            end
        end,

        match = "[GD]"
    },

    -- 试图夺球
    ["get"] = {
        switch = function()

        end,
    },

    -- 试图夺球
    ["get"] = {
        switch = function()

        end,
    },


    --夺球后传递
    ["pass"] = {
        switch = function()
            Utils.GlobalComputingPos(vision, player.pos("TODO:传给谁来着？")) --
            if player.kickBall("TODO:") then
                return "init"
            end
        end
    },

    name = "TestDefense",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "defense",
    timeout = 99999
}
