function isShooting()
    -- 判断是否踢向球门
    local ballPos = ball.rawPos()
    local ballVelDir = ball.velDir()
    local ballLine = CGeoSegment(ballPos, ballPos+Utils.Polar2Vector(param.INF, ballVelDir))
    local tPos = param.ourGoalLine:segmentsIntersectPoint(ballLine)
    return -param.goalRadius-100<tPos:y() and tPos:y()<param.goalRadius+100
end

return {
    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,
    firstState = "goalie_norm",
    ["goalie_norm"] = {
        switch = function()
            local rolePos = CGeoPoint:new_local(player.rawPos("Goalie"):x(), player.rawPos("Goalie"):y())
            local getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE)
            if player.myinfraredCount("Goalie") > 10 then
                return "goalie_getBall"
            end
            if isShooting() and Utils.InExclusionZone(getBallPos, param.goalieBuf, "our") then
                return "goalie_getBall"
            end
            if ball.velMod() < 1000 and Utils.InExclusionZone(getBallPos, param.goalieBuf, "our") then
                return "goalie_getBall"
            end
            if rolePos:dist(getBallPos)<param.goalieCatchBuf and Utils.InExclusionZone(getBallPos, param.goalieBuf, "our") then
                return "goalie_getBall"
            end
        end,
        -- Goalie = task.goalie("Goalie"),
        Goalie = function() return task.goalie_norm("Goalie") end,
        match = "{G}"
    },
    ["goalie_getBall"] = {
        switch = function()
            local rolePos = CGeoPoint:new_local(player.rawPos("Goalie"):x(), player.rawPos("Goalie"):y())
            local getBallPos = task.stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE))
            if player.myinfraredCount("Goalie") < 10 and not Utils.InExclusionZone(getBallPos, param.goalieBuf, "our") then
                return "goalie_norm"
            end

            if player.myinfraredCount("Goalie") > param.goalieDribblingFrame then
            -- if bufcnt(player.myinfraredCount("Goalie") > param.goalieDribblingFrame or param.goalieStablePoint:dist(rolePos) < param.playerRadius, 60) then
                return "goalie_kick"
            end

            if 10 <= player.myinfraredCount("Goalie") and bufcnt(param.goalieStablePoint:dist(rolePos) < param.playerRadius, 20) then
                return "goalie_kick"
            end

        end,
        -- Goalie = task.goalie("Goalie"),
        Goalie = function() return task.goalie_getBall("Goalie") end,
        match = "{G}"
    },
    ["goalie_kick"] = {
        switch = function()
            local rolePos = CGeoPoint:new_local(player.rawPos("Goalie"):x(), player.rawPos("Goalie"):y())
            local getBallPos = task.stabilizePoint(Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE))
            if not Utils.InExclusionZone(getBallPos, param.goalieBuf, "our") then
                return "goalie_norm"
            end

            if player.kickBall("Goalie") then
                return "goalie_norm"
            end
        end,
        Goalie = function() return task.goalie_kick("Goalie") end,
        match = "{G}"
    },

    name = "Nor_Goalie",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
