return {
    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,
    firstState = "defend_norm",
    ["defend_norm"] = {
        switch = function()
            -- local tierPos = CGeoPoint:new_local(player.rawPos("Tier"):x(), player.rawPos("Tier"):y())
            -- local defenderPos = CGeoPoint:new_local(player.rawPos("Defender"):x(), player.rawPos("Defender"):y())
            -- local getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE)

        end,
        Breaker = function() return task.defend_normV2("Tier", 0, param.defenderMode) end,
        Fronter = function() return task.defend_normV2("Defender", 1, param.defenderMode) end,
        match = "[BF]"
    },
    ["defend_front"] = {
        switch = function()
            if bufcnt(true, 20) then
            end
            if player.toBallDist(player.closestBall()) > param.playerRadius * 6 then
                for i=0, task.FronterCount-1 do
                    local rolePos = CGeoPoint:new_local(player.rawPos(task.FronterNums[i]):x(), player.rawPos(task.FronterNums[i]):y())
                    local getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 2,0,param.V_DECAY_RATE)
                    if player.toPointDist(task.FronterNums[i], getBallPos) < 300 then
                        return "defend_kick"
                    end
                end
            end
            if enemy.toOurGoalDist(enemy.closestGoal()) > param.FronterRadius*5/3 then
                return "defend_norm"
            end
        end,
        Breaker = function() return task.defend_front("Tier") end,
        Fronter = function() return task.defend_front("Defender") end,
        match = "[TD]"
    },
    ["defend_kick"] = {
        switch = function()
            if bufcnt(true, 20) then
                return "defend_norm"
            end
        end,
        Breaker = function() return task.defend_kick("Tier") end,
        Fronter = function() return task.defend_kick("Defender") end,
        match = "[TD]"
    },

    name = "Nor_DefendV2",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
