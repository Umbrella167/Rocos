local initPos = {
    -- 后卫北，后卫南
    CGeoPoint:new_local(-3500, 500),
    CGeoPoint:new_local(-3500, -500)
}

gPlayTable.CreatePlay {
    firstState = "init",

    -- 初始状态
    ["init"] = {
        switch = function()
            UpdataTickMessage(1, 2) -- 更新帧信息
            if bufcnt(player.toTargetDist('Defender') < 10, 10) then
                return "await"
            end
        end,

        Defender = task.goCmuRush(initPos[1], 0),
        Tier = task.goCmuRush(initPos[2], 0),

        match = "{DT}"
    },

    -- 后卫，检测到球靠近，去扑球
    ["defense"] = {
        switch = function()
            UpdataTickMessage(1, 2) -- 更新帧信息
            if bufcut(player.toBallDist('Defender') < 500, 1000) then
                return "init"
            end
        end,

        Defender = task.trackingDefenderPos("m"),

        match = "[D]"
    },

    name = "TestDefense",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "defense",
    timeout = 99999
}
