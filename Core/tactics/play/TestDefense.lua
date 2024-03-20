local initPos = {
    -- 后卫北，后卫南
    CGeoPoint:new_local(-3500, 500),
    CGeoPoint:new_local(-3500, -500)
}

gPlayTable.CreatePlay {
    firstState = "init",

    -- 初始状态 回到自己的位置上等待防御
    ["init"] = {
        switch = function()
            if bufcnt(player.toTargetDist(('Defender')) < 10, 10) then
                return "await"
            end
        end,

        -- FIXME: 不知道这里名字，之后要写
        Defender = task.goCmuRush(initPos[1], 0),
        Defender2 = task.goCmuRush(initPos[2], 0),

        -- match = "{D}{D}" -- FIXME: 同步改这里
        match = "{D}"
    },

    -- 后卫，检测到球靠近，去扑球
    ["defense"] = {
        switch = function()
            Utils.GlobalComputingPos(vision, player.pos("Defender"))

            if Utils.DefenderTryToCatchBall() > -1 then -- -1为未搜索
                return "get"
            end
        end,

        -- match = "[D][D]" -- FIXME: 同步改这里
        match = "[D]"
    },

    -- 试图夺球
    ["get"] = {
        switch = function()

        end,
    },

    --夺球后传递
    -- TODO:重写
    ["pass"] = {
        switch = function()
            Utils.GlobalComputingPos(vision, player.pos(""))
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
