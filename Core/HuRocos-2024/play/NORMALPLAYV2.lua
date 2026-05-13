local DSS_FLAG = flag.allow_dss + flag.dodge_ball

local halfL = param.pitchLength / 2
local halfW = param.pitchWidth / 2

local playerPos = function(role) 
    return function()
        return CGeoPoint:new_local(player.posX(role),player.posY(role))
    end
end
-- dir:pos1  ->  pos2
local closures_dir = function(pos1,pos2)
    return function()
        return (pos2 - pos1):dir()
    end
end
local closures_dir_ball = function(role)
    return function()
        return player.toBallDir(role)
    end
end
local ballPos = function()
    return function()
        return CGeoPoint:new_local(ball.pos():x(),ball.pos():y())
    end
end
-- 带球车初始化
local dribbling_player_num = 1
-- 球权初始化
local ballRights = -1
-- 射门坐标初始化
local shoot_pos = CGeoPoint:new_local(param.pitchLength / 2,0)
-- 守门员号码
local our_goalie_num = param.our_goalie_num
-- 后卫号码
local defend_num1 = param.defend_num1
local defend_num2 = param.defend_num2
-- 传球角度
local pass_pos = CGeoPoint:new_local(param.pitchLength / 2,-999)
-- getball参数
local playerVel = param.playerVel
local getballMode = param.getballMode

-- dribblingPos 带球目标坐标
local dribbling_target_pos = CGeoPoint:new_local(0,0)
local show_dribbling_pos = CGeoPoint:new_local(0,0)
local KickerRUNPos = CGeoPoint:new_local(0,0)
local SpecialRUNPos = CGeoPoint:new_local(0,0)
local CenterRUNPos = CGeoPoint:new_local(0,0)
local ShowDribblingPos = function ()
    return function()
        return CGeoPoint:new_local(show_dribbling_pos:x(),show_dribbling_pos:y())
    end
end
local dribblingDir = function(role)
    return function()
        local playerPos = CGeoPoint(player.posX(role),player.posY(role))
        return  (playerPos - show_dribbling_pos):dir()
    end
end
local debugStatus = function()
    for num,i in pairs(GlobalMessage.attackPlayerRunPos) do
        debugEngine:gui_debug_msg(CGeoPoint:new_local(-halfL - 700,num * 200),
            tostring(GlobalMessage.attackPlayerRunPos[num].num)     ..
            " "                                                     ..
            "("                                                     .. 
            tostring(GlobalMessage.attackPlayerRunPos[num].pos:x()) .. 
            ","                                                     ..
            tostring(GlobalMessage.attackPlayerRunPos[num].pos:y()) ..
            ")"
        ,6)
    end
    for num,i in pairs(GlobalMessage.attackPlayerStatus) do 
        debugEngine:gui_debug_msg(CGeoPoint:new_local(-halfL - 700,num * -200), 
        tostring(i.num)         ..
        "  "                    .. 
        tostring(i.status),3)
    end
end


local function isLuaCGeoPointValid(p)
    if p ~= nil and type(p) == "userdata" and type(p.x) == "function" and type(p.y) == "function" then
        local x_val, y_val
        local success_x = pcall(function() x_val = p:x() end)
        local success_y = pcall(function() y_val = p:y() end)
        if success_x and success_y and type(x_val) == "number" and type(y_val) == "number" and
           x_val == x_val and y_val == y_val and math.abs(x_val) < math.huge and math.abs(y_val) < math.huge then
            return true
        end
    end
    return false
end

local function roleNum(role)
    if type(role) == "string" then
        local n = gRoleNum[role]
        return n ~= nil and n or -1
    elseif type(role) == "number" then
        return role
    end
    return -1
end

local function point(x, y)
    return CGeoPoint:new_local(x, y)
end

local function clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

local nearestEnemyInfo

nearestEnemyInfo = function(pos)
    local best_dist = 99999
    local best_pos = nil
    for i = 0, param.maxPlayer - 1 do
        if enemy.valid(i) then
            local enemy_pos = enemy.pos(i)
            local dist = enemy_pos:dist(pos)
            if dist < best_dist then
                best_dist = dist
                best_pos = enemy_pos
            end
        end
    end
    return best_pos, best_dist
end

local function rolePos(role)
    local n = roleNum(role)
    if n == -1 then
        return nil
    end
    return player.pos(n)
end

local function roleHasBallControl(role)
    if role == nil then
        return false
    end
    local role_num = roleNum(role)
    if role_num == -1 then
        return false
    end
    if player.myinfraredCount(role) >= 8 then
        return true
    end
    return predicted_ball_rights == 1 and player.toBallDist(role) < 180 and ball.velMod() < 700
end

local function defenderClearTarget()
    local ball_pos = ball.pos()
    local defender_pos = rolePos("Defender")
    if not isLuaCGeoPointValid(ball_pos) then
        ball_pos = isLuaCGeoPointValid(defender_pos) and defender_pos or point(0, 0)
    end
    local pressure_enemy_pos = nearestEnemyInfo(ball_pos)
    local side_sign = ball_pos:y() >= 0 and -1 or 1
    if isLuaCGeoPointValid(pressure_enemy_pos) then
        side_sign = pressure_enemy_pos:y() >= ball_pos:y() and -1 or 1
    end
    local target = point(
        clamp(math.max(ball_pos:x() + 2600, param.pitchLength / 10), 150, param.pitchLength / 2 - 320),
        clamp(ball_pos:y() * 0.2 + side_sign * 900, -param.pitchWidth / 2 + 280, param.pitchWidth / 2 - 280)
    )
    if Utils.MakeInField ~= nil then
        target = Utils.MakeInField(target, 150)
    end
    if Utils.InOurPenaltyArea ~= nil and Utils.InOurPenaltyArea(target, 180) and Utils.MakeOutOfOurPenaltyArea ~= nil then
        target = Utils.MakeOutOfOurPenaltyArea(target, 180)
    end
    return target
end

local function defendToBall(role, mode)
    local ball_pos = ball.pos()
    local role_pos = player.pos(role)
    local basePos = param.ourGoalPos
    if mode == 0 then
        basePos = param.ourTopGoalPos
    elseif mode == 1 then
        basePos = param.ourButtomGoalPos
    elseif mode == 2 then
        basePos = param.ourGoalPos
    end
    local defendPoint = task.getLineCrossDefenderPos(ball_pos, basePos)
    if defendPoint == CGeoPoint(9999, 9999) then
        defendPoint = role_pos
    end
    local idir = player.toPointDir(ball_pos, role)
    local mexe, mpos = GoCmuRush { pos = defendPoint, dir = idir, acc = a, flag = 0x00000000, rec = r, vel = v }
    return { mexe, mpos }
end

local function kickBallForward()
    local clear_target = CGeoPoint:new_local(param.pitchLength / 2, 0)
    local kick_mode = kick.flat
    local ball_pos = ball.pos()
    local bt = clear_target - ball_pos
    local btLen = bt:mod()
    if btLen > 100 then
        for i = 0, 15 do
            local robotPos = nil
            if player.valid(i) then
                robotPos = player.pos(i)
            elseif enemy.valid(i) then
                robotPos = enemy.pos(i)
            end
            if robotPos ~= nil then
                local br = robotPos - ball_pos
                local projection = (br:x() * bt:x() + br:y() * bt:y()) / btLen
                if projection > 0 and projection < btLen then
                    local perpDist = math.abs(bt:x() * br:y() - bt:y() * br:x()) / btLen
                    if perpDist < 500 then
                        kick_mode = kick.chip
                        break
                    end
                end
            end
        end
    end
    defender_clear_target = nil
    return task.pass_2026("Defender", function() return clear_target end, kick_mode, 5.0, 180, 100)()
end

local function defenderDirectTask()
    local ball_pos = ball.pos()
    local defender_pos = rolePos("Defender")
    if not isLuaCGeoPointValid(ball_pos) then
        return defendToBall("Defender", 1)
    end

    if player.toBallDist("Assister") < param.defenderAssisterDist then
        return defendToBall("Defender", 1)
    end

    if isLuaCGeoPointValid(defender_pos) then
        local defend_limit_x = -param.pitchLength / 2 + param.penaltyDepth + param.defenderBuf
        if defender_pos:x() > defend_limit_x + param.defenderMaxChaseDist then
            return defendToBall("Defender", 1)
        end
    end

    if Utils.InExclusionZone(ball_pos, 120, "our") then
        defender_clear_target = nil
        return defendToBall("Defender", 1)
    end

    local has_ball = roleHasBallControl("Defender") or player.toBallDist("Defender") < (param.playerRadius * 2.6)
    if has_ball then
        return kickBallForward()
    end

    defender_clear_target = nil

    if isLuaCGeoPointValid(defender_pos) and isLuaCGeoPointValid(ball_pos) then
        local distToBall = defender_pos:dist(ball_pos)
        local ballVel = ball.velMod()
        if distToBall < param.defenderActiveDist and ballVel < param.defenderActiveVel then
            local canActive = true
            for i = 0, 15 do
                local robotPos = nil
                if player.valid(i) and i ~= player.num("Defender") then
                    robotPos = player.pos(i)
                elseif enemy.valid(i) then
                    robotPos = enemy.pos(i)
                end
                if robotPos ~= nil and robotPos:dist(ball_pos) < param.defenderActiveDist then
                    canActive = false
                    break
                end
            end
            if canActive then
                return kickBallForward()
            end
        end
    end

    if isLuaCGeoPointValid(defender_pos) then
        local intercept_pos = Utils.GetBestInterPos(vision, defender_pos, param.playerVel, 2,0,param.V_DECAY_RATE)
        if isLuaCGeoPointValid(intercept_pos) then
            local target = intercept_pos
            if Utils.MakeInField ~= nil then
                target = Utils.MakeInField(target, 120)
            end
            if Utils.InOurPenaltyArea ~= nil and Utils.InOurPenaltyArea(target, 160) and Utils.MakeOutOfOurPenaltyArea ~= nil then
                target = Utils.MakeOutOfOurPenaltyArea(target, 160)
            end
            if defender_pos:dist(target) < 460 then
                return task.defend_kick("Defender")
            end
        end
    end
    return defendToBall("Defender", 1)
end

local runCount = 0
local lastShootPoint = CGeoPoint(0,0)
local UpdataTickMessage = function (our_goalie_num,defend_num1,defend_num2)

    -- 获取全局状态，进攻状态为传统
    status.getGlobalStatus(1)  
    -- 带球机器人初始化
    dribbling_player_num = -1
    -- 获取球权
    ball_rights = GlobalMessage.Tick().ball.rights
    runCount = runCount + 1
    -- 每30帧算一次点
    if runCount > 40 then
        local KickerShootPos = Utils.PosGetShootPoint(vision, player.posX("Kicker"),player.posY("Kicker"))
        local SpecialShootPos = Utils.PosGetShootPoint(vision,player.posX("Special"),player.posY("Special"))
        local CenterShootPos = Utils.PosGetShootPoint(vision,player.posX("Center"),player.posY("Center"))
        -- 9000 * 6000
        -- 分档算点 
        if ball.posX() > -halfL / 3 then
            KickerRUNPos = Utils.GetAttackPos(vision, player.num("Kicker"),KickerShootPos,CGeoPoint(halfL * 0.74,halfW * 0.4),CGeoPoint(halfL,-halfW * 0.4),180);
            SpecialRUNPos = Utils.GetAttackPos(vision, player.num("Special"),SpecialShootPos,CGeoPoint(halfL * 0.33,halfW * 0.47),CGeoPoint(halfL * 0.62,-halfW * 0.47),200);
        else
            KickerRUNPos = Utils.GetAttackPos(vision, player.num("Kicker"),KickerShootPos,CGeoPoint(-halfL * 0.11,halfW * 0.8),CGeoPoint(halfL * 0.49,0),300);
            SpecialRUNPos = Utils.GetAttackPos(vision, player.num("Special"),SpecialShootPos,CGeoPoint(-halfL * 0.42,0),CGeoPoint(halfL * 0.22,-halfW * 0.93),300);
        end
        CenterRUNPos = Utils.GetAttackPos(vision, player.num("Center"),SpecialShootPos,CGeoPoint(halfL * 0.09,halfW * 0.68),CGeoPoint(halfL * 0.67,-halfW * 0.77),300);
        runCount = 0

    end

    -- 处理球权是我方的情况
    if GlobalMessage.Tick().our.dribbling_num ~= -1 and dribbling_player_num ~= our_goalie_num and dribbling_player_num ~= defend_num1 and  dribbling_player_num ~= defend_num2 then
        dribbling_player_num = GlobalMessage.Tick().our.dribbling_num
        runCount = param.INF
        pass_player_num = GlobalMessage.Tick().task[dribbling_player_num].max_confidence_pass_num
        -- pass_pos = GlobalMessage.Tick().task[dribbling_player_num].max_confidence_pass_num

        --  解决传球时算点跳动太远的问题
        --  PassErrorRate 如果要传球的角色距离 目标点太远，那么选择 （X1 + X2) / PassErrorRate 
        local PassErrorRate = 1
        if (player.num("Kicker") == pass_player_num) then
            -- local ballLine = CGeoSegment(ball.rawPos(),KickerRUNPos)
            -- local fixPassFardist = (player.rawPos("Kicker") - ballLine:projection(player.rawPos("Kicker"))):dir()
            local fixPassFardist = player.toPointDist("Kicker",KickerRUNPos)
            if fixPassFardist > 500 then
                local passRate = Utils.NumberNormalize(player.velMod("Kicker"),1600,0)
                pass_pos = player.pos("Kicker") + Utils.Polar2Vector(KickerRUNPos:dist(player.pos("Kicker")) * passRate, (KickerRUNPos - player.pos("Kicker")):dir())
                -- pass_pos =CGeoPoint(player.posX("Kicker"),player.posY("Kicker"))
            else
                pass_pos = KickerRUNPos
            end
        elseif (player.num("Special") == pass_player_num) then
            -- local ballLine = CGeoSegment(ball.rawPos(),KickerRUNPos)
            -- local fixPassFardist = (player.rawPos("Special") - ballLine:projection(player.rawPos("Special"))):mod()
            local fixPassFardist = player.toPointDist("Special",SpecialRUNPos)
            if fixPassFardist > 500 then
                --  pass_pos =CGeoPoint(player.posX("Special"),player.posY("Special"))
                local passRate = 1 - Utils.NumberNormalize(player.velMod("Special"),1600,0)
                pass_pos = player.pos("Special") + Utils.Polar2Vector(SpecialRUNPos:dist(player.pos("Special")) * passRate,(SpecialRUNPos - player.pos("Special")):dir())
            else
                pass_pos = SpecialRUNPos
            end
        
        elseif (player.num("Center") == pass_player_num) then
            local fixPassFardist = player.toPointDist("Center",CenterRUNPos)
            if fixPassFardist > 500 then
                local passRate = 1 - Utils.NumberNormalize(player.velMod("Center"),1600,0)
                pass_pos = player.pos("Center") + Utils.Polar2Vector(CenterRUNPos:dist(player.pos("Center")) * passRate,(CenterRUNPos - player.pos("Center")):dir())
            else
                pass_pos = CenterRUNPos
            end
        end
        shoot_pos = GlobalMessage.Tick().task[dribbling_player_num].shoot_pos
        shoot_pos = CGeoPoint:new_local(shoot_pos:x(),shoot_pos:y())
        dribbling_target_pos = shoot_pos
        dribblingStatus = status.getPlayerStatus(dribbling_player_num)  -- 获取带球机器人状态
        shoot_pos = dribblingStatus == "Shoot" and shoot_pos or pass_pos
        
        if shoot_pos:y() == -999 then
            shoot_pos = lastShootPoint
        else
            lastShootPoint = shoot_pos
        end
        param.shootPos = shoot_pos  
    end
    param.goalieTargetPos = SpecialRUNPos
    debugEngine:gui_debug_x(shoot_pos,0)
    debugEngine:gui_debug_msg(shoot_pos,"resShootPos",0,0,70)
    debugEngine:gui_debug_msg(CGeoPoint(0,param.pitchWidth / 2 - (100 + param.debugSize)),"myInfraredCount: " .. player.myinfraredCount("Assister").. "    InfraredCount: " .. player.infraredCount("Assister") .. "    InfraredOffCount:" .. player.myinfraredOffCount("Assister") ,2,0,param.debugSize)
    debugEngine:gui_debug_msg(CGeoPoint(0,param.pitchWidth / 2 - (250 + param.debugSize)),"Kick:" .. tostring(player.kickBall("Assister")),3,0,param.debugSize)
    debugEngine:gui_debug_msg(CGeoPoint(0,param.pitchWidth / 2 - (400 + param.debugSize)),"DribblingPlayerNum:" .. dribbling_player_num .. "   DribblingStatus:" .. tostring(dribblingStatus) .. "   ToBallDist:" ..tostring(player.toPointDist("Assister",ball.pos())),4,0,param.debugSize)
    debugEngine:gui_debug_msg(CGeoPoint(0,param.pitchWidth / 2 - (550 + param.debugSize)),"ballRights:" .. ball_rights,5,0,param.debugSize)
    debugEngine:gui_debug_msg(CGeoPoint(0,param.pitchWidth / 2 - (700 + param.debugSize)),"targetPos:" .. tostring(param.shootPos:x()) ..  "    " ..  tostring(param.shootPos:y()),4,0,param.debugSize)
    debugEngine:gui_debug_msg(CGeoPoint(0,param.pitchWidth / 2  - (850 + param.debugSize)),"ballVel:" .. ball.velMod(),1,0,param.debugSize)

    -- show_dribbling_pos = Utils.GetShowDribblingPos(vision,CGeoPoint(player.posX("Assister"),player.posY("Assister")),dribbling_target_pos);
    -- debugStatus()
end
local lastState = "GetGlobalMessage"
local dribbleCount = 0
local getState = function ()
        local resultState = "GetGlobalMessage"
        if ball_rights == 1 then   -- 我方球权的情况 获取进攻状态
            -- 防止为定义状态转跳
            if dribblingStatus == "NOTHING"  or dribblingStatus == "Run" or  dribblingStatus == "Getball" then
            else
                -- 如果状态是射门或者传球、 那么就返回ShootPoint
                if (dribblingStatus == "passToPlayer" or dribblingStatus == "Shoot") then
                    shoot_pos = dribblingStatus == "Shoot" and shoot_pos or pass_pos
                    resultState =  "ShootPoint"
                else
                    -- 否则一定是带球状态
                    resultState =  "dribbling"
                end
            end
        -- 如果球权是敌方的 [一抢球、二盯防]
        elseif (ball_rights == -1 and ball.pos():x() < param.markingThreshold) or (ball.pos():x() < param.markingThreshold and ball_rights == -1 and ball_rights == 2) or ball.pos():x() < -halfL / 3 then
            resultState =  "defendNormalState"
        -- 如果是顶牛状态 [一带球、二跑位]
        elseif ball_rights == 2 then
            resultState =  "dribbling"
        -- 如果是球在滚动过程、或在传球过程 [一接球、二跑位]
        else
            resultState =  "Getball"
        end

        if Utils.InExclusionZone(ball.pos(), param.dribblingExclusionDist, "all") and ball_rights ~= 0  then
            resultState =  "dribbling"
        end

        debugEngine:gui_debug_msg(CGeoPoint(0,param.pitchWidth / 2 - (1000 + param.debugSize)),"NextState:" .. resultState,3,0,param.debugSize)
        lastState = resultState
        return resultState
end
    ------------------------------------------------------------------------------------------------------------------------------------------------
local subScript = false

return {

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)

    end,
firstState = "Init",
["Init"] = {
    switch = function()
        if not subScript then
            gSubPlay.new("ShootPoint", "Nor_Shoot",{})
            gSubPlay.new("ShowDribbling", "Nor_Dribbling",{})
            gSubPlay.new("Defender", "Nor_DefendV2")
            gSubPlay.new("Goalie", "Nor_Goalie")
        end
        return "GetGlobalMessage"
    end,
    Assister = task.stop(),
    Kicker = task.stop(),
    Special = task.stop(),
    Center = task.stop(),
    Defender = task.stop(),
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[AKSC]{DG}"
},

["GetGlobalMessage"] = {
    switch = function()
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)    -- 更新帧信息
        local State = getState()
        -- getState()
        return State
        
    end,
    Assister = task.getball(function() return shoot_pos end,playerVel,getballMode),
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end ,closures_dir_ball("Special"),_,DSS_FLAG),
    Center = task.goCmuRush(function() return CenterRUNPos end ,closures_dir_ball("Center"),_,DSS_FLAG),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "{AKSCDG}"
},

-- 射球
["ShootPoint"] = {
    switch = function()
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)    -- 更新帧信息
        local State = getState()
        -- getState()

        if (Utils.InExclusionZone(CGeoPoint( ball.posX(),ball.posY()),50)) then
            return "dribbling"
        end 
        return State
    end,
    Assister = gSubPlay.roleTask("ShootPoint", "Assister"),
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end,closures_dir_ball("Special"),_,DSS_FLAG),
    Center = task.goCmuRush(function() return CenterRUNPos end ,closures_dir_ball("Center"),_,DSS_FLAG),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "{AKSCDG}"
},

["Touch"] = {
    switch = function()
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)    -- 更新帧信息
        local State = getState()
        if(GlobalMessage.Tick().ball.rights == -1 or not player.canTouch(player.pos("Assister"),shoot_pos,param.canTouchAngle)) and State ~= "dribbling" then
            
            return State
        end
    end,
    Assister = task.touchKick(function() return shoot_pos end, false, kick.flat),
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end,closures_dir_ball("Special"),_,DSS_FLAG),
    Center = task.goCmuRush(function() return CenterRUNPos end ,closures_dir_ball("Center"),_,DSS_FLAG),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[A][KSC]{DG}"
},
-- 接球
["Getball"] = {
    switch = function()
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)    -- 更新帧信息
        local State = getState()
        -- getState()
        if State ~= "Getball" then
            return State
        end
        local AssisterPos = CGeoPoint(player.posX("Assister"),player.posY("Assister"))
        local ballLine = CGeoSegment(ball.pos(),ball.pos() + Utils.Polar2Vector(9999,ball.velDir()))
        local playerPrjPos = ballLine:projection(player.pos("Assister"))
        local onBallLine = ballLine:IsPointOnLineOnSegment(playerPrjPos)
        if param.allowTouch and Utils.isValidPass(vision,AssisterPos,shoot_pos,param.enemy_buffer) and player.canTouch(AssisterPos,shoot_pos,param.canTouchAngle)  and Utils.isValidPass(vision,AssisterPos,CGeoPoint(ball.posX(),ball.posY()),param.enemy_buffer)then
            return "Touch"
        end
    end,
    Assister = task.getball(function() return shoot_pos end,playerVel,getballMode),
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end,closures_dir_ball("Special"),_,DSS_FLAG),
    Center = task.goCmuRush(function() return CenterRUNPos end ,closures_dir_ball("Center"),_,DSS_FLAG),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[A][KSC]{DG}"

},

-- 带球
["dribbling"] = {
    switch = function()
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)
        local State = getState()
        if bufcnt(true,35)then -- or State == "Getball" 
            return State
        end

    end,
    --dribbling_target_pos
    Assister = gSubPlay.roleTask("ShowDribbling", "Assister"),
    Kicker = task.goCmuRush(function() return KickerRUNPos end,closures_dir_ball("Kicker"),_,DSS_FLAG),
    Special = task.goCmuRush(function() return SpecialRUNPos end,closures_dir_ball("Special"),_,DSS_FLAG),
    Center = task.goCmuRush(function() return CenterRUNPos end ,closures_dir_ball("Center"),_,DSS_FLAG),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "{AKSCDG}"
},
-- 防守 盯防
["defendNormalState"] = {
    switch = function()
        UpdataTickMessage(our_goalie_num,defend_num1,defend_num2)    -- 更新帧信息
        local State = getState()
        if bufcnt(true,30) then
            return State
        end
    end,
    Assister = task.getball(function() return shoot_pos end,playerVel,getballMode),
    Kicker = function() return task.defender_marking("Kicker",function() return KickerRUNPos end) end,
    Special = function() return task.defender_marking("Special",function() return SpecialRUNPos end) end ,
    Center = task.goCmuRush(function() return CenterRUNPos end ,closures_dir_ball("Center"),_,DSS_FLAG),
    Defender = defenderDirectTask,
    Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
    match = "[A][KSC]{DG}"
},
name = "NORMALPLAYV2",
applicable ={
    exp = "a",
    a = true
},
attribute = "attack",
timeout = 99999
}
