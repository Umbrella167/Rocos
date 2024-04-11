--[[ =============== 对外提供 ================ ]]
DEFENDER_NUM1 = 1
DEFENDER_NUM2 = 2

DEFENDER_INITPOS_DEFENDER = CGeoPoint:new_local(PENALTY_X, PENALTY_Y) -- DEFENDER 初始站位
DEFENDER_INITPOS_TIER = CGeoPoint:new_local(PENALTY_X, -PENALTY_Y)    -- TIER 初始站位

DEFENDER_SAFEDISTANCE = 2000                                          -- 安全区域
DEFENDER_DEFAULT_DISTANCE_MAX = param.penaltyWidth
DEFENDER_DEFAULT_DISTANCE_MIN = param.penaltyWidth / 4

--[[ =============== 常量 ================ ]]
local PENALTY_X = -3450 -- 禁区X
local PENALTY_Y = 1000  -- 禁区Y （可以正负）
local TIME_TICK_SECON = 70

--[[ =============== DEFENDER_DEBUG_MODE ================ ]]
DEFENDER_DEBUG_MODE = true
-- DEFENDER_DEBUG_MODE = false

if DEFENDER_DEBUG_MODE then
    -- 调试窗口位置
    DEFENDER_DEBUG_POSITION_X = 0
    DEFENDER_DEBUG_POSITION_Y = param.pitchWidth -- * 1.05
    -- DEFENDER_DEBUG_POSITION_Offset = -10
end

gPlayTable.CreatePlay {
    firstState = "defenderTestmode",

    ["defenderTestmode"] = {
        -- switch = function()
        -- end,
        Utils.UpdataTickMessage(vision, DEFENDER_NUM1, DEFENDER_NUM2),

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
