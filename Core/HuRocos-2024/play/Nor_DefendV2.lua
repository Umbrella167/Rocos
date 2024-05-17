local getTargetPos = function()
    return param.goalieTargetPos
end

local getBestInterBallPos = function(role)
    local getBallPos = Utils.GetBestInterPos(vision, player.pos(role), param.playerVel, 1, 0,param.V_DECAY_RATE)
    if getBallPos == CGeoPoint(param.INF, param.INF) then
        return player.pos(role)
    end
    return getBallPos
end

return {
    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,
    firstState = "defend_norm",
    ["defend_norm"] = {
        switch = function()
            local rolePos = player.pos("Defender")
            local enemyNum = enemy.closestBall()
            local enemyPos = enemy.pos(enemyNum)

            if getBestInterBallPos("Defender"):dist(rolePos) < param.playerRadius*3 and enemyPos:dist(rolePos) > 1500 then
                return "defend_getBall"
            end

            if player.infraredCount("Fronter") > 5 or rolePos:dist(ball.pos())<param.playerFrontToCenter then
                return "defend_kick"
            end

        end,
        Breaker = function() return task.defend_normV2("Tier", 0, param.defenderMode) end,
        Fronter = function() return task.defend_normV2("Defender", 1, param.defenderMode) end,
        match = "{BF}"
    },
    ["defend_getBall"] = {
        switch = function()
            local rolePos = player.pos("Defender")
            local enemyNum = enemy.closestBall()
            local enemyPos = enemy.pos(enemyNum)
            if getBestInterBallPos("Defender"):dist(rolePos) > param.playerRadius*4 or enemyPos:dist(rolePos) < 800 then
                return "defend_norm"
            end

            if player.infraredCount("Fronter") > 5 or rolePos:dist(ball.pos())<param.playerFrontToCenter then
                return "defend_kick"
            end

        end,
        Breaker = function() return task.defend_normV2("Tier", 0, param.defenderMode) end,
        Fronter = function() return task.goCmuRush(getBestInterBallPos("Defender"), player.toBallDir("Defender"), a, flag.not_avoid_their_vehicle) end,
        match = "{BF}"
    },
    ["defend_kick"] = {
        switch = function()
            local rolePos = player.pos("Defender")
            local enemyNum = enemy.closestBall()
            local enemyPos = enemy.pos(enemyNum)
            if player.kickBall("Defender") or player.toBallDist("Defender") > param.playerRadius or rolePos:dist(enemyPos) < 800 then
                return "defend_norm"
            end
        end,
        Breaker = function() return task.defend_normV2("Tier", 0, param.defenderMode) end,
        Fronter = task.ShootdotV3("Defender", getTargetPos, 20, kick.flat),
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
