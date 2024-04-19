local start_pos = CGeoPoint(0, 0)
local dist = 1000
local rotateSpeed = 1 -- rad/s

local runPos = function()
    local angle = rotateSpeed * vision:getCycle() / param.frameRate
    return start_pos + Utils.Polar2Vector(dist, angle)
end
local subScript = false
local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)

local PLAY_NAME = ""
return {

    __init__ = function(name, args)
        print("in __init__ func : ", name, args)
    end,
    firstState = "init",
    ["init"] = {
        switch = function()
            return "run"
        end

    },
    ["run"] = {
        switch = function()
        end,
    },

    name = "test",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
