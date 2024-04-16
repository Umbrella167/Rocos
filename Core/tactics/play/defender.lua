return {
    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,
    firstState = "defend_norm",
    ["defend_norm"] = {
        switch = function()
            -- print("markdebug : ",gSubPlayFiles)
            -- for key, value in pairs(gSubPlayFiles) do
            --     print("printFileTable: ", key, value)
            -- end
        end,
        Tier = task.defend("Tier", 0),
        Defender = task.defend("Defender", 1),
        Goalie = task.goalie("Goalie"),
        match = "(GTD)"
    },
    ["defend1"] = {
        switch = function()
            -- print("markdebug : ",gSubPlayFiles)
            -- for key, value in pairs(gSubPlayFiles) do
            --     print("printFileTable: ", key, value)
            -- end
        end,
        Tier = task.stop(),
        Defender = task.stop(),
        Goalie = task.goalie("Goalie"),
        match = "(GTD)"
    },

    name = "defender",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
