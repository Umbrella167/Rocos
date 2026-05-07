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
        Middle = task.stop(),
        Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
        match = "{FMG}"
    },

    ["skill"] = {
        switch = function()
            local k1 = gamepad.pressedForRobot(1)
            local k2 = gamepad.pressedForRobot(2)
            
            if(task.playerDirToPointDirSub("Fronter",param.shootPos) > param.shootError) then 
                debugEngine:gui_debug_line(player.pos("Fronter"),player.pos("Fronter") + Utils.Polar2Vector(9999,player.dir("Fronter")),5)
            else
                debugEngine:gui_debug_line(player.pos("Fronter"),player.pos("Fronter") + Utils.Polar2Vector(9999,player.dir("Fronter")),1)
            end
            if(task.playerDirToPointDirSub("Middle",param.shootPos) > param.shootError) then 
                debugEngine:gui_debug_line(player.pos("Middle"),player.pos("Middle") + Utils.Polar2Vector(9999,player.dir("Middle")),3)
            else
                debugEngine:gui_debug_line(player.pos("Middle"),player.pos("Middle") + Utils.Polar2Vector(9999,player.dir("Middle")),1)
            end
            -- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),"GP1:"..tostring(k1).." GP2:"..tostring(k2))
        end,
        Fronter = gamepad.skill(1),
        Middle = gamepad.skill(2),
        Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
        match = "{FMG}"

    },
    name = "TestMyRun",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}
