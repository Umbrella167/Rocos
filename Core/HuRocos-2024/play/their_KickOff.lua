
local p2 = CGeoPoint:new_local(-250,-2000)
local p3 = CGeoPoint:new_local(-600,0)   
local p4 = CGeoPoint:new_local(-2200,100)
local p5 = CGeoPoint:new_local(-2200,-100)
local p6 = CGeoPoint:new_local(-3000,1000)
local p1 = CGeoPoint:new_local(-3000,-1000)

local Dir_ball = function(role)
	return function()
		return (ball.pos() - player.pos(role)):dir()
	end
end

gPlayTable.CreatePlay{
    firstState = "ready",
    ["ready"] = {
        switch = function ()
            if cond.isNormalStart() then
                return "judge"
            elseif cond.isGameOn() then
                 return "judge"
            end
        end,
        Assister   = task.goCmuRush(CGeoPoint(-200,1000), Dir_ball("Assister")),
        Special  = task.goCmuRush(p3, Dir_ball("Special")),
        Kicker = task.goCmuRush(p2, Dir_ball("Kicker")),
        Tier = task.goCmuRush(p1, Dir_ball("Tier")),
        Defender = task.goCmuRush(p6, Dir_ball("Defender")),
        Goalie = task.goalie("Goalie"),
        match = "[ASK]{TDG}"
    },
    ["judge"] = {
        switch = function ()
            if ball.velMod() > 10 then 
                return "exit"
            end
        end,
        Assister   = task.goCmuRush(CGeoPoint(-200,1000), Dir_ball("Assister")),
        Special  = task.goCmuRush(p3, Dir_ball("Special")),
        Kicker = task.goCmuRush(p2, Dir_ball("Kicker")),
        Tier = task.goCmuRush(p1, Dir_ball("Tier")),
        Defender = task.goCmuRush(p6, Dir_ball("Defender")),
        Goalie = task.goalie("Goalie"),
        match = "[ASK]{TDG}"
    },

name = "their_KickOff",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
