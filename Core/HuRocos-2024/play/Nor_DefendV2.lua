return {
    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,
    firstState = "defend_norm",
    ["defend_norm"] = {
        switch = function()
            local rolePos = CGeoPoint:new_local(player.rawPos("Goalie"):x(), player.rawPos("Goalie"):y())
            local getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE)

            -- if rolePos:dist(getBallPos)<param.defenderCatchBuf then
            --     return "defend_kick"
            -- end


            -- local ballToCloestEnemyDist = ball.rawPos():dist(enemy.pos(enemy.closestBall()))
            -- for i=0, param.maxPlayer-1 do
            --     if enemy.valid(i) then
            --         -- debugEngine:gui_debug_msg(CGeoPoint(-1000, 1000+(i*150)), i.."   "..enemy.toOurGoalDist(i).."    "..param.FronterRadius*5/3)
            --         if enemy.toOurGoalDist(i) < param.FronterRadius*5/3 then
            --             return "defend_front"
            --         end
            --     end
            -- end
            
            -- if player.toBallDist(player.closestBall()) > param.playerRadius * 6 then
            --     for i=0, task.FronterCount-1 do
            --         local rolePos = CGeoPoint:new_local(player.rawPos(task.FronterNums[i]):x(), player.rawPos(task.FronterNums[i]):y())
            --         local getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 2,0,param.V_DECAY_RATE)
            --         if player.toPointDist(task.FronterNums[i], getBallPos) < 1000 then
            --             return "defend_kick"
            --         end
            --     end
            -- end
        end,
        Breaker = function() return task.defend_normV2("Tier", 0, 1) end,
        Fronter = function() return task.defend_normV2("Defender", 1, 1) end,
        match = "[TD]"
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
