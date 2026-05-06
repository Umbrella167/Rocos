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
            if player.infraredCount("Goalie") > 10 then
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
            if player.infraredCount("Goalie") < 10 and not Utils.InExclusionZone(getBallPos, param.goalieBuf, "our") then
                return "goalie_norm"
            end

            if player.infraredCount("Goalie") > param.goalieDribblingFrame then
            -- if bufcnt(player.infraredCount("Goalie") > param.goalieDribblingFrame or param.goalieStablePoint:dist(rolePos) < param.playerRadius, 60) then
                return "turnToPoint"
            end

            if 10 <= player.infraredCount("Goalie") and bufcnt(param.goalieStablePoint:dist(rolePos) < param.playerRadius, 20) then
                return "turnToPoint"
            end

        end,
        -- Goalie = task.goalie("Goalie"),
        Goalie = function() return task.goalie_getBall("Goalie") end,
        match = "{G}"
    },
    ["turnToPoint"] = {
        switch = function()
            --  
            -- if(not bufcnt(player.infraredOn("Assister"),1)) then
            -- 	return "ready1"
            -- end
            -- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),player.rotVel("Assister"))
            if(bufcnt(player.myinfraredCount("Goalie") < 1,4)) then
                return "goalie_getBall"
            end
            local Vy = player.rotVel("Goalie")
            local ToTargetDist = player.toPointDist("Goalie",param.goalieTargetPos)
            resShootPos = task.compensateAngle("Goalie",Vy,param.goalieTargetPos,ToTargetDist * param.rotCompensate(player.num("Goalie")))

            if(task.playerDirToPointDirSub("Goalie",resShootPos) < param.shootError) then 
                return "goalie_kick"
            end

        end,
        Goalie = function() return task.TurnToPointV2("Goalie", function() return param.goalieTargetPos end,param.rotVel(player.num("Goalie"))) end,
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
        Goalie = task.ShootdotV2(function() return param.goalieTargetPos end, param.shootError, kick.chip ),
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
