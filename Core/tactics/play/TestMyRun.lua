
return {
    firstState = "init",
    ["init"] = {
        switch = function()
            gSubPlay.new("ShootPoint", "Nor_Shoot",{pos = function() return shoot_pos end})
            gSubPlay.new("Goalie", "Nor_Goalie")
            if bufcnt(true,50) then 
                return "skill"
            end
        end,
        Leader = task.stop(),
        Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
        match = "{LG}"
    },
    ["skill"] = {
        switch = function()
            local key = gamepad.pressed()
            debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),key)
        end,
        Leader = gamepad.skill(),
        Goalie = gSubPlay.roleTask("Goalie", "Goalie"),

        -- Leader = task.touch(CGeoPoint:new_local(0,0))
        match = "{LG}"

    },
    name = "TestMyRun",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
