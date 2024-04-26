return {
    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,
    firstState = "defend_norm",
    ["defend_norm"] = {
        switch = function()

            local ballToCloestEnemyDist = ball.rawPos():dist(enemy.pos(enemy.closestBall()))
            for i=0, param.maxPlayer-1 do
                if enemy.valid(i) then
                    -- debugEngine:gui_debug_msg(CGeoPoint(-1000, 1000+(i*150)), i.."   "..enemy.toOurGoalDist(i).."    "..param.defenderRadius*5/3)
                    if enemy.toOurGoalDist(i) < param.defenderRadius*5/3 then
                        return "defend_front"
                    end
                end
            end
            
            if player.toBallDist(player.closestBall()) > param.playerRadius * 6 then
                for i=0, task.defenderCount-1 do
                    local rolePos = CGeoPoint:new_local(player.rawPos(task.defenderNums[i]):x(), player.rawPos(task.defenderNums[i]):y())
                    local getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 2)
                    if player.toPointDist(task.defenderNums[i], getBallPos) < 1000 then
                        return "defend_kick"
                    end
                end
            end
        end,
        Tier = function() return task.defend_norm("Tier", 0) end,
        Defender = function() return task.defend_norm("Defender", 1) end,
        Goalie = task.goalie("Goalie"),
        match = "(GTD)"
    },
    ["defend_front"] = {
        switch = function()
            if bufcnt(true, 20) then
            end
            if player.toBallDist(player.closestBall()) > param.playerRadius * 6 then
                for i=0, task.defenderCount-1 do
                    local rolePos = CGeoPoint:new_local(player.rawPos(task.defenderNums[i]):x(), player.rawPos(task.defenderNums[i]):y())
                    local getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 2)
                    if player.toPointDist(task.defenderNums[i], getBallPos) < 300 then
                        return "defend_kick"
                    end
                end
            end
            if enemy.toOurGoalDist(enemy.closestGoal()) > param.defenderRadius*5/3 then
                return "defend_norm"
            end
        end,
        Tier = function() return task.defend_front("Tier") end,
        Defender = function() return task.defend_front("Defender") end,
        Goalie = task.goalie("Goalie"),
        match = "(GTD)"
    },
    ["defend_kick"] = {
        switch = function()
            if bufcnt(true, 20) then
                return "defend_norm"
            end
        end,
        Tier = function() return task.defend_kick("Tier") end,
        Defender = function() return task.defend_kick("Defender") end,
        Goalie = task.goalie("Goalie"),
        match = "(GTD)"
    },

    name = "Nor_Defend",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
