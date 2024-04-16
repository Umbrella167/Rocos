local start_pos = CGeoPoint(0,0)
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
        print("in __init__ func : ",name, args)
    end,
    firstState = "init",
    ["init"] = {
        switch = function()
            if bufcnt(true,10) then 
                if not subScript then
                    gSubPlay.new("testDefender", "defender")
                    -- gSubPlay.new("kickTask", "TestPassAndKick")
                end
                return "run"
            end
        end,
        Tier = task.stop(),
        Defender = task.stop(),
        Goalie = task.stop(),
        match = "[GTD]"
    },
    ["run"] = {
        switch = function()
            -- print("markdebug : ",gSubPlayFiles)
            -- for key, value in pairs(gSubPlayFiles) do
            --     print("printFileTable: ", key, value)
            -- end
        end,
        Tier = gSubPlay.roleTask("testDefender", "Tier"),
        Defender = gSubPlay.roleTask("testDefender", "Defender"),
        Goalie = gSubPlay.roleTask("testDefender", "Goalie"),
        match = "(GTD)"
    },

    name = "mytest2",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
