local defendpos = {
  CGeoPoint(-4350,0),
  CGeoPoint(-3300,850),
  CGeoPoint(-3300,-850),

}
local ballPlacementPos = function()
    return function()
        return ball.placementPos()
    end
end
local inBallPlacementPos = function(role)
    local ballPlacementLine = CGeoSegment(ball.pos(),ball.placementPos())
    local playerPrj = ballPlacementLine:projection(player.pos(role))
    local inLine = ballPlacementLine:IsPointOnLineOnSegment(playerPrj)
    local toPrjDist = player.pos(role):dist(playerPrj)
    if (inLine and toPrjDist < 680) or player.toBallDist(role) < 680 or player.pos(role):dist(ball.placementPos()) < 680 then
        return true
    else
        return false
    end
end
local avoidPlacementPos = function(role,WitePos)
    return function()
        local iWitePos = WitePos or player.pos(role)
        local p
        if type(iWitePos) == "function" then
            p = iWitePos()
        else
            p = iWitePos
        end
        local ballPlacementLine = CGeoSegment(ball.pos(),ball.placementPos())
        local playerPrj = ballPlacementLine:projection(player.pos(role))
        if inBallPlacementPos(role) then
            local runPos = playerPrj + Utils.Polar2Vector(3000,(player.pos(role) - playerPrj):dir())
            -- local runPos = CGeoPoint(0,0)
            if not Utils.InField(runPos) then
                runPos = CGeoPoint(0,0)
            end
            return runPos
        else
            return p
        end
    end
end


local waitPosKicker = function()
    return function()
        local startPos
        local endPos
        local KickerShootPos = Utils.PosGetShootPoint(vision, player.posX("Kicker"),player.posY("Kicker"))
        -- 角球
        if ball.placementPos():x() > 3000 then
            if ball.posY() > 0 then
                startPos = CGeoPoint(2600,-1250)
                endPos = CGeoPoint(3000,-850)
            else
                startPos = CGeoPoint(2600,1250)
                endPos = CGeoPoint(3000,850)
            end
        -- 中场球
        elseif ball.placementPos():x() < 3000 and ball.placementPos():x() > 0 then
            if ball.posY() < 0 then 
                startPos = CGeoPoint(4050,1500)
                endPos = CGeoPoint(4400,800)
            else
                startPos = CGeoPoint(4050,-1500)
                endPos = CGeoPoint(4400,-800)
            end
        else
        -- 前场球
            startPos = CGeoPoint(ball.placementPos():x()+3000,1000)
            endPos = CGeoPoint(ball.placementPos():x()+4000,-1000)
        end
        local attackPos = Utils.GetAttackPos(vision, player.num("Kicker"),KickerShootPos,startPos,endPos,130,500)
        if attackPos:x() == 0 and attackPos:y() == 0 then
            if ball.placementPos():x() > 1000 then
                if ball.posY() < 0 then
                    attackPos = CGeoPoint(3000,850)
                else
                    attackPos = CGeoPoint(3000,-850)
                end
            else
                attackPos = player.pos("Kicker")
            end
        end
        return attackPos
    end
end
local waitPosSpecial = function()
    return function()
        local startPos
        local endPos
        local SpecialShootPos = Utils.PosGetShootPoint(vision, player.posX("Special"),player.posY("Special"))
        if ball.placementPos():x() > 3000 then
            if ball.posY() < 0 then
                startPos = CGeoPoint(2400,-1100)
                endPos = CGeoPoint(2900,-700)
            else
                startPos = CGeoPoint(2400,1100)
                endPos = CGeoPoint(2900,700)
            end
        elseif ball.placementPos():x() < 3000 and ball.placementPos():x() > 0 then
            if ball.posY() < 0 then 
                startPos = CGeoPoint(3000,-750)
                endPos = CGeoPoint(3500,-1300)
            else
                startPos = CGeoPoint(3000,750)
                endPos = CGeoPoint(3500,1300)
            end
        else
            startPos = CGeoPoint(ball.placementPos():x()+1000,0)
            endPos = CGeoPoint(ball.placementPos():x()+2500,-1700)
        end
        local attackPos = Utils.GetAttackPos(vision, player.num("Special"),SpecialShootPos,startPos,endPos,130,500)
        if attackPos:x() == 0 and attackPos:y() == 0 then
            attackPos = player.pos("Special") 
        end
        return attackPos
    end
end
local AssisterDir = function()
    if player.valid(player.num("Kicker")) then
        return (player.pos("Kicker") - player.pos("Assister")):dir()
    end
    return player.toBallDir("Assister")
end
local DSS_FLAG = flag.allow_dss + flag.dodge_ball + flag.our_ball_placement
gPlayTable.CreatePlay {

firstState = "start",

["start"] = {
  switch = function()
    debugEngine:gui_debug_arc(ball.pos(),500,0,360,1)
    return "getball"
  end,
  Assister = task.stop(),
  Kicker   = task.stop(),
  Special  = task.stop(),
  Tier = task.stop(),
  Defender = task.stop(),
  Goalie = task.stop(),
  match = "(AKS){TDG}"
},

["getball"] = {
  switch = function()
    GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
    debugEngine:gui_debug_msg(CGeoPoint(0,2800),"ballRights: " .. GlobalMessage.Tick.ball.rights,2)
    debugEngine:gui_debug_msg(CGeoPoint(0,2600),"InfraredCount: " .. player.myinfraredCount("Assister"),3)
    if ball.pos():dist(ball.placementPos()) < 200 then
        return "avoid"
    end
  end,
  Assister = task.getBall_BallPlacement("Assister"),
  Kicker   = task.goCmuRush(avoidPlacementPos("Kicker",waitPosKicker()),function() return player.toBallDir("Kicker") end,_,DSS_FLAG),
  Special  = task.goCmuRush(avoidPlacementPos("Special",waitPosSpecial()),function() return player.toBallDir("Special") end,_,DSS_FLAG),
  Tier = task.goCmuRush(avoidPlacementPos("Tier"),function() return player.toBallDir("Tier") end,_,DSS_FLAG),
  Defender = task.goCmuRush(avoidPlacementPos("Defender"),function() return player.toBallDir("Defender") end,_,DSS_FLAG),
  Goalie = task.goCmuRush(avoidPlacementPos("Goalie"),function() return player.toBallDir("Goalie") end,_,DSS_FLAG),
  match = "(AKS){TDG}"
},

["avoid"] = {
  switch = function()
    GlobalMessage.Tick = Utils.UpdataTickMessage(vision,param.our_goalie_num,param.defend_num1,param.defend_num2)
        if ball.pos():dist(ball.placementPos()) > 200 then
        return "getball"
    end
  end,
  Assister = task.goCmuRush(function() return ball.pos() + Utils.Polar2Vector(-220,AssisterDir())end,function() return player.toBallDir("Assister") end,_,DSS_FLAG),
  Kicker   = task.goCmuRush(avoidPlacementPos("Kicker",waitPosKicker()),function() return player.toBallDir("Kicker") end,_,DSS_FLAG),
  Special  = task.goCmuRush(avoidPlacementPos("Special",waitPosSpecial()),function() return player.toBallDir("Special") end,_,DSS_FLAG),
  Tier = task.goCmuRush(avoidPlacementPos("Tier"),function() return player.toBallDir("Tier") end,_,DSS_FLAG),
  Defender = task.goCmuRush(avoidPlacementPos("Defender"),function() return player.toBallDir("Defender") end,_,DSS_FLAG),
  Goalie = task.goCmuRush(avoidPlacementPos("Goalie"),function() return player.toBallDir("Goalie") end,_,DSS_FLAG),
  match = "(AKS){TDG}"
},


name = "our_BallPlacement",
applicable = {
  exp = "a",
  a = true
},
attribute = "attack",
timeout = 99999
}
