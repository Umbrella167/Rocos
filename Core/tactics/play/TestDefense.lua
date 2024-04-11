--[[ =============== 对外提供 ================ ]]
Defender_Num1 = 1
Defender_Num2 = 2

--[[ =============== 本地常量 ================ ]]
local PENALTY_X = -3450                                            -- 禁区X
local PENALTY_Y = 1000                                             -- 禁区Y （可以正负）
local INITPOS_DEFENDER = CGeoPoint:new_local(PENALTY_X, PENALTY_Y) -- DEFENDER 初始站位
local INITPOS_TIER = CGeoPoint:new_local(PENALTY_X, -PENALTY_Y)    -- TIER 初始站位
local TIME_TICK_SECON = 70

--[[ =============== DEBUG_MODE ================ ]]
local DEBUG_MODE = true
-- local DEBUG_MODE = false

if DEBUG_MODE then
    -- 调试窗口位置
    DEFENDER_DEBUG_POSITION_X = 0
    DEFENDER_DEBUG_POSITION_Y = 3250
    DEFENDER_DEBUG_POSITION_Offset = -10
end


gPlayTable.CreatePlay {
    firstState = "init",

    -- 初始状态
    ["init"] = {
        switch = function()
            UpdataTickMessage(Defender_Num1, Defender_Num2)
            if bufcnt(player.toPointDist('Defender', INITPOS_DEFENDER) < 100, TIME_TICK_SECON / 2) and bufcnt(player.toPointDist('Tier', INITPOS_TIER) < 100, TIME_TICK_SECON / 2) then
                return "defense"
            end
        end,

        Defender = task.goCmuRush(INITPOS_DEFENDER, 0),
        Tier = task.goCmuRush(INITPOS_TIER, 0),

        match = "{DT}"
    },

    -- 准备接球
    ["defense"] = {
        switch = function()
            UpdataTickMessage(Defender_Num1, Defender_Num2)
            -- debugEngine:gui_debug_msg(
            --     CGeoPoint:new_local(DEFENDER_DEBUG_POSITION_X,
            --         DEFENDER_DEBUG_POSITION_Y + DEFENDER_DEBUG_POSITION_Offset * 2),
            --     tostring(player.toBallDist('Defender')))
            if bufcnt(player.toBallDist('Defender') > 5000, TIME_TICK_SECON * 2) then
                -- return "init"
            end
        end,

        -- Defender = task.trackingDefenderPos("m"),

        Defender = task.trackingDefenderPos("l"),
        Tier = task.trackingDefenderPos("r"),

        match = "{DT}"
    },

    name = "TestDefense",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "defense",
    timeout = 99999
}
