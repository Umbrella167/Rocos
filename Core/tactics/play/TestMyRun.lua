return {
    firstState = "init",
    ["init"] = {
        switch = function()
            gSubPlay.new("ShootPoint", "Nor_Shoot",{pos = function() return param.shootPos end})
            gSubPlay.new("Goalie", "Nor_Goalie")
            if bufcnt(true,50) then 
                return "skill"
            end
        end,
        Fronter = task.stop(),
        Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
        match = "{FG}"
    },

    ["skill"] = {
        switch = function()
        end,
        Fronter = gamepad.skill(),
        Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
        -- Leader = task.touch(CGeoPoint:new_local(0,0))
        match = "{FG}"

    },
    name = "TestMyRun",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
