local testPos = {
    CGeoPoint:new_local(800, 800), 
    CGeoPoint:new_local(-800, 800),
    CGeoPoint:new_local(800,-800),
    CGeoPoint:new_local(-800,-800)
}
local tPos = {
    CGeoPoint:new_local(2000, 1500), 
    CGeoPoint:new_local(-2000, 1500),
    CGeoPoint:new_local(2000,-1500),
    CGeoPoint:new_local(-2000,-1500)
}
local vel = CVector:new_local(0, 0)
local maxvel = 0
local time = 1
local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)

local DIR = function()
    return (player.pos('Assister') - ball.pos()):dir()
end

local localMatch = "[ALDM]" -- ①
-- local localMatch = "[A][LDM]" -- ②
-- local localMatch = "[AL][DM]" -- ③
-- local localMatch = "[ALD][M]" -- ④

local drawDebug = function()
    for i = 1, 4 do
        local pos = testPos[i]
        debugEngine:gui_debug_msg(pos+Utils.Polar2Vector(40,math.pi/4), string.format("(%3d,%3d)", pos:x(), pos:y()),0,0,50)
        debugEngine:gui_debug_x(pos,param.GREEN,0,30)
        local pos2 = tPos[i]
        debugEngine:gui_debug_msg(pos2+Utils.Polar2Vector(40,math.pi/4), string.format("(%3d,%3d)", pos2:x(), pos2:y()),0,0,50)
        debugEngine:gui_debug_x(pos2,param.GREEN,0,30)

        -- debugEngine:gui_debug_line(pos, pos2,param.GREEN)
    end
    debugEngine:gui_debug_msg(CGeoPoint:new_local(-300,900), localMatch,0)
end

return {
    firstState = "ready",

    ["ready"] = {
        switch = function()
            if bufcnt(true,180) then
                return "run"
            end
        end,
        Assister = task.goSimplePos(tPos[1],0),
        Leader   = task.goSimplePos(tPos[2],0),
        Defender = task.goSimplePos(tPos[3],0),
        Middle   = task.goSimplePos(tPos[4],0),
        match = "[ALDM]"
    },
    
    ["run"] = {
        switch = function()
            -- drawDebug()
        end,
        Assister = task.goSimplePos(testPos[1],0),
        Leader   = task.goSimplePos(testPos[2],0),
        Defender = task.goSimplePos(testPos[3],0),
        Middle   = task.goSimplePos(testPos[4],0),
        match = localMatch
    },
    ["run2"] = {
        switch = function()
            if bufcnt(player.toTargetDist("a")<5,time) then
                return "run"..3
            end
        end,
        a = task.goCmuRush(testPos[2],0, _, DSS_FLAG),
        b = task.goCmuRush(testPos[2]+Utils.Polar2Vector(1000,-math.pi/2),0, _, DSS_FLAG),
        match = "{ab}"
    },
    ["run3"] = {
        switch = function()
            if bufcnt(player.toTargetDist("a")<5,time) then
                return "run"..4
            end
        end,
        a = task.goCmuRush(testPos[3],0, _, DSS_FLAG),
        b = task.goCmuRush(testPos[3]+Utils.Polar2Vector(1000,-math.pi/2),0, _, DSS_FLAG),
        match = "{ab}"
    },
    ["run4"] = {
        switch = function()
            if bufcnt(player.toTargetDist("a")<5,time) then
                return "run"..1
            end
        end,
        a = task.goCmuRush(testPos[4],0, _, DSS_FLAG),
        b = task.goCmuRush(testPos[4]+Utils.Polar2Vector(1000,-math.pi/2),0, _, DSS_FLAG),
        match = "{ab}"
    },

    name = "TestMyRun",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
