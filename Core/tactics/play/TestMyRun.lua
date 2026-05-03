local testPos = {
    CGeoPoint:new_local(3000, 3100), 
    CGeoPoint:new_local(-3000, 3100),
    CGeoPoint:new_local(-3000,-3100),
    CGeoPoint:new_local(3000,-3100)
}
local vel = CVector:new_local(0, 0)
local maxvel = 0
local time = 1
local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)

local DIR = function()
    return (player.pos('Assister') - ball.pos()):dir()
end

return {
    firstState = "init",
    ["init"] = {
        switch = function()
            if bufcnt(true,50) then 
                return "skill"
            end
        end,
        Leader = task.stop(),
        match = "{L}"
    },
    ["skill"] = {
        switch = function()
            local key = gamepad.pressed()
            debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),key)
        end,
        Leader = gamepad.skill(),
        -- Leader = task.touch(CGeoPoint:new_local(0,0))
        match = "{L}"
    },
    name = "TestMyRun",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
