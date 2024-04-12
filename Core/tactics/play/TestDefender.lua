--[[ =============== Define ================ ]]
DEFENDER_NUM1 = 1
DEFENDER_NUM2 = 2

DEFENDER_SAFEDISTANCE = 2000 -- 安全区域
DEFENDER_DEFAULT_DISTANCE_MAX = param.penaltyWidth
DEFENDER_DEFAULT_DISTANCE_MIN = param.penaltyWidth / 4

--[[ =============== local ================ ]]
local PENALTY_X = -param.pitchLength / 2 + param.penaltyDepth -- 禁区X
local TIME_TICK_SECON = 70

DEFENDER_INITPOS_DEFENDER = CGeoPoint:new_local(PENALTY_X, param.penaltyDepth * 0.9) -- DEFENDER 初始站位
DEFENDER_INITPOS_TIER = CGeoPoint:new_local(PENALTY_X, -param.penaltyDepth * 0.9)    -- TIER 初始站位

--[[ =============== DEFENDER_DEBUG_MODE ================ ]]
DEFENDER_DEBUG_MODE = true
-- DEFENDER_DEBUG_MODE = false

if DEFENDER_DEBUG_MODE then
    -- 调试窗口位置
    DEFENDER_DEBUG_POSITION_X = 0
    DEFENDER_DEBUG_POSITION_Y = param.pitchWidth / 2 * 1.05
end

gPlayTable.CreatePlay {
    -- firstState = "defenderTestmode",
    firstState = "init",

    ["init"] = {
        switch = function()
            return "defenderTestmode"
        end,
        Defender = task.stop(),
        Tier = task.stop(),

        match = "{DT}"
    },

    ["defenderTestmode"] = {
        switch = function()
        end,

        Defender = task.defender_defence("Defender"),
        Tier = task.defender_defence("Tier"),

        match = "{DT}"
    },

    name = "TestDefender",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "defender",
    timeout = 99999
}
