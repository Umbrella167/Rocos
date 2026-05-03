module(..., package.seeall)
pressed_map = {
    [-1] = "",
    [0] = "A",
    [1] = "B",
    [3] = "X",
    [4] = "Y",
    [6] = "LB",
    [7] = "RB",
    [10] = "W",
    [15] = "S",
    [11] = "M",
}

function pressed()
    local pressed_id = gamepadCmd:getFirstPressed()
    return pressed_map[pressed_id]
end


skill_map = { 
    ["X"] = task.getball(ball.pos,param.playerVel,param.getballMode),
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
