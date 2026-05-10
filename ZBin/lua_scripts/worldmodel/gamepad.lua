module(..., package.seeall)
pressed_map = {
    [-1] = "",
    [0] = "A",
    [1] = "B",
    [3] = "X",
    [4] = "Y",
    [6] = "LB",
    [7] = "RB",
}

function pressed()
    local pressed_id = gamepadCmd:getFirstPressed()
    key = pressed_map[pressed_id]
    if key then 
        return key
    else
        return pressed_id
    end
end

function pressedForRobot(robotId)
    local pressed_id = gamepadCmd:getFirstPressedForRobot(robotId)
    key = pressed_map[pressed_id]
    if key then 
        return key
    else
        return pressed_id
    end
end

function makeSkillMap(myId, passTargetId)
    return { 
        ["X"] = task.getball(ball.pos, param.playerVel, param.getballMode),
        ["Y"] = function()
            param.shootPos = Utils.GetShootPoint(vision, myId)
            gRoleNum["Assister"] = myId
            local rt = gSubPlay.roleTask("ShootPoint", "Assister")
            if rt and rt.task then
                gSubPlay.register("", "Assister", rt.args)
                return rt.task()
            end
            return task.stop()
        end,
        ["B"] = function()
            if player.valid(passTargetId) then  
                param.shootPos = player.pos(passTargetId)
            else
                param.shootPos = Utils.GetShootPoint(vision, myId)
            end
            gRoleNum["Assister"] = myId
            local rt = gSubPlay.roleTask("ShootPoint", "Assister")
            if rt and rt.task then
                gSubPlay.register("", "Assister", rt.args)
                return rt.task()
            end
            return task.stop()
        end,
        
        ["A"] = task.Shootdot_gamepad(myId, function() return ball.pos() + Utils.Polar2Vector(50, (ball.pos() - player.pos(myId)):dir()) end,param.shootError,flag.chip,2000),
    }
end

skill_map_1 = makeSkillMap(1, 2)
skill_map_2 = makeSkillMap(2, 1)

function skill(playerNum)
    local myMap
    if playerNum == 1 then
        myMap = skill_map_1
    else
        myMap = skill_map_2
    end
    return function()
        local key = pressedForRobot(playerNum)
        local fn = myMap[key]
        if fn then
            return fn()
        elseif last_skill then
            return task.stop()
        end
    end 
end
