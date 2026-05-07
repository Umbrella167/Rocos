module(..., package.seeall)
pressed_map_xpad = {
    [-1] = "",
    [0] = "A",
    [1] = "B",
    [3] = "X",
    [4] = "Y",
    [6] = "LB",
    [7] = "RB",
}
pressed_map_xone = {
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
    if param.gamepad_layout == 0 then
        key = pressed_map_xpad[pressed_id]
    else
        key = pressed_map_xone[pressed_id]
    end

    if key then 
        return key
    else
        return pressed_id
    end
end

skill_map = { 
    ["X"] = task.getball(ball.pos, param.playerVel, param.getballMode),
    ["Y"] = function()
        param.shootPos = Utils.GetShootPoint(vision,param.manual_robot_id)
        local gpRobotId = gamepadCmd:getRobotId()
        if gpRobotId < 0 then return task.stop() end
        gRoleNum["Assister"] = gpRobotId
        local rt = gSubPlay.roleTask("ShootPoint", "Assister")
        if rt and rt.task then
            gSubPlay.register("", "Assister", rt.args)
            return rt.task()
        end
        return task.stop()
    end,
    ["B"] = function()
        if param.manual_robot_id == 1 then
            if player.valid(2) then  
                param.shootPos = player.pos(2)
            else
                param.shootPos = Utils.GetShootPoint(vision,param.manual_robot_id)
            end
        elseif param.manual_robot_id == 1 then 
            if player.valid(1) then
                param.shootPos = player.pos(1)
            else
                param.shootPos = Utils.GetShootPoint(vision,param.manual_robot_id)
            end
        end
        local gpRobotId = gamepadCmd:getRobotId()
        if gpRobotId < 0 then return task.stop() end
        gRoleNum["Assister"] = gpRobotId
        local rt = gSubPlay.roleTask("ShootPoint", "Assister")
        if rt and rt.task then
            gSubPlay.register("", "Assister", rt.args)
            return rt.task()
        end
        return task.stop()
    end,
}

function skill()
    return function()
        local key = pressed()
        local fn = skill_map[key]
        if fn then
            return fn()
        elseif last_skill then
            return task.stop()
        end
    end 
end
