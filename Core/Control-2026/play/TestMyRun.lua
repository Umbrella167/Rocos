
function refmsg()
    local refMsg = vision:getCurrentRefereeMsg()
    local msg = ""
    local color = 1
    local ready = vision:gameState():canEitherKickBall() and not vision:gameState():gameOn()
    if refMsg == "GameHalt" then
        msg = "HALT 暂停"; color = 8
    elseif refMsg == "GameStop" then
        msg = "STOP 停球"; color = 8
    elseif refMsg == "GameOver" then
        msg = "比赛结束"; color = 8
    elseif refMsg == "OurTimeout" then
        msg = "暂停计时"; color = 4
    elseif refMsg == "OurKickOff" then
        msg = ready and "我方开球 [Ready]" or "我方开球 [Wait]"; color = ready and 3 or 4
    elseif refMsg == "TheirKickOff" then
        msg = ready and "对方开球 [Ready]" or "对方开球 [Wait]"; color = ready and 3 or 1
    elseif refMsg == "OurPenaltyKick" then
        msg = ready and "我方点球 [Ready]" or "我方点球 [Wait]"; color = ready and 3 or 4
    elseif refMsg == "TheirPenaltyKick" then
        msg = ready and "对方点球 [Ready]" or "对方点球 [Wait]"; color = ready and 3 or 1
    elseif refMsg == "OurIndirectKick" then
        msg = ready and "我方间接任意球 [Ready]" or "我方间接任意球 [Wait]"; color = ready and 3 or 4
    elseif refMsg == "TheirIndirectKick" then
        msg = ready and "对方间接任意球 [Ready]" or "对方间接任意球 [Wait]"; color = ready and 3 or 1
    elseif refMsg == "OurBallPlacement" then
        msg = "我方放球"; color = 4
    elseif refMsg == "TheirBallPlacement" then
        msg = "对方放球"; color = 1
    elseif refMsg == "" then
        msg = ""; color = 4
    else
        msg = "Unknown: " .. tostring(refMsg); color = 8
    end
    debugEngine:gui_debug_msg(CGeoPoint(-2500, 0), msg, color, 0, 500)
    if refMsg == "OurBallPlacement" or refMsg == "TheirBallPlacement" then
        local p1 = ball.pos()
        local p2 = ball.placementPos()
        local r = 680
        local dx = p2:x() - p1:x()
        local dy = p2:y() - p1:y()
        local segDir = math.atan2(dy, dx)
        local perpDir = segDir + math.pi / 2
        local capsuleColor = refMsg == "OurBallPlacement" and 4 or 1
        debugEngine:gui_debug_line(p1 + Utils.Polar2Vector(r, perpDir), p2 + Utils.Polar2Vector(r, perpDir), capsuleColor)
        debugEngine:gui_debug_line(p1 + Utils.Polar2Vector(r, perpDir + math.pi), p2 + Utils.Polar2Vector(r, perpDir + math.pi), capsuleColor)
        debugEngine:gui_debug_arc(p1, r, 0, 360, capsuleColor)
        debugEngine:gui_debug_arc(p2, r, 0, 360, capsuleColor)
        debugEngine:gui_debug_arc(p2, 130, 0, 360, capsuleColor)
    end
end

return {
    firstState = "init",
    ["init"] = {
        switch = function()
            gSubPlay.new("ShootPoint", "Nor_Shoot",{pos = function() return param.shootPos end})
            gSubPlay.new("Goalie", "Nor_Goalie")
            if bufcnt(true,1) then 
                return "skill"
            end
        end,
        Fronter = task.stop(),
        Middle = task.stop(),
        Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
        match = "{FMG}"
    },

    ["skill"] = {
        switch = function()
            local k1 = gamepad.pressedForRobot(1)
            local k2 = gamepad.pressedForRobot(2)
            refmsg()
            if(task.playerDirToPointDirSub("Fronter",param.shootPos) > param.shootError) then 
                debugEngine:gui_debug_line(player.pos("Fronter"),player.pos("Fronter") + Utils.Polar2Vector(9999,player.dir("Fronter")),5)
            else
                debugEngine:gui_debug_line(player.pos("Fronter"),player.pos("Fronter") + Utils.Polar2Vector(9999,player.dir("Fronter")),1)
            end
            if(task.playerDirToPointDirSub("Middle",param.shootPos) > param.shootError) then 
                debugEngine:gui_debug_line(player.pos("Middle"),player.pos("Middle") + Utils.Polar2Vector(9999,player.dir("Middle")),3)
            else
                debugEngine:gui_debug_line(player.pos("Middle"),player.pos("Middle") + Utils.Polar2Vector(9999,player.dir("Middle")),1)
            end
            -- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),"GP1:"..tostring(k1).." GP2:"..tostring(k2))
        end,
        Fronter = gamepad.skill(1),
        Middle = gamepad.skill(2),
        Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
        match = "{FMG}"

    },
    name = "TestMyRun",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
