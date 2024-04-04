local initPos = {
    -- 守门，后卫北，后卫南
    CGeoPoint:new_local(-4500, 0),
    CGeoPoint:new_local(-3500, 500),
    CGeoPoint:new_local(-3500, -500)
}

gPlayTable.CreatePlay {
    firstState = "init",

    ["init"] = { -- 初始状态 回到自己的位置上等待防御
        switch = function()
            if bufcnt(player.toTargetDist(('Defender')) < 10, 10) then
                return "await"
            end
        end,

        Goalie = task.goCmuRush(initPos[1], 0),
        Defender = task.goCmuRush(initPos[2], 0),
        Defender2 = task.goCmuRush(initPos[3], 0),

        match = "{GDD}" -- FIXME: 俩后卫
    },

    -- 待命状态
    ["await"] = {
        switch = function()
            Utils.GlobalComputingPos(vision, player.pos("Defender"))
            if player.toTargetDist("Assister") < 1000 then
                return "pass"
            end
        end,

        match = "[GD]"
    },


    --夺球后传递
    ["pass"] = {
        switch = function()
            Utils.GlobalComputingPos(vision, player.pos("Defender"))
            if player.kickBall("Leader") then
                return "shoot"
            end
        end,
        -- Defender = task.goCmuRush(initPos[1]),
        -- TODO:补全传递
        match = "[GD]"
    },

    name = "TestDefense",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "defense",
    timeout = 99999
}
