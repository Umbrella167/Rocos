

return {
    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,
    firstState = "defend_norm",
    ["defend_norm"] = {
        switch = function()


            -- defender write the kick ball
            local rolePos = player.pos("Defender")


            local getBallPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 0,param.V_DECAY_RATE)
        end,
        Breaker = function() return task.defend_normV2("Tier", 0, param.defenderMode) end,
        Fronter = function() return task.defend_normV2("Defender", 1, param.defenderMode) end,
        match = "{BF}"
    },
    ["defend_kick"] = {
        switch = function()
            if bufcnt(true, 20) then
                return "defend_norm"
            end
        end,
        Breaker = function() return task.defend_kick("Tier") end,
        Fronter = function() return task.defend_kick("Defender") end,
        match = "[TD]"
    },

    name = "Nor_DefendV2",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
