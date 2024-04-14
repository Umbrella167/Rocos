local temp01 = CGeoPoint:new_local(-1000,1000)
local temp02 = CGeoPoint:new_local(-1000,-1000)
local temp03 = CGeoPoint:new_local(-1000,0)
local temp04 = CGeoPoint:new_local(-1500,500)
local theirgoal = CGeoPoint:new_local(4500,0)
local target = CGeoPoint:new_local(3000,2000)
local target2 = CGeoPoint:new_local(-2500,1500)
local target3 = CGeoPoint:new_local(0,0)
local p1 = CGeoPoint:new_local(-600,0)
local p2 = CGeoPoint:new_local(-250,-2000)
local p3 = CGeoPoint:new_local(-200,1500)
local p4 = CGeoPoint:new_local(-2200,100)
local p5 = CGeoPoint:new_local(-2200,-100)
local p6 = CGeoPoint:new_local(-3000,0)

local Dir_ball = function(role)
	return function()
		return (ball.pos() - player.pos(role)):dir()
	end
end

local pos_self = function(role)
	return function()
		return player.pos(role)
	end
end
local pos_ = function(ppp)
	return function()
		return ppp
	end
end

gPlayTable.CreatePlay{
firstState = "halt",
switch = function()
	if cond.isNormalStart() and ball.velMod() > 500 then
      return "exit"
    end
end,
["halt"] = {
	Assister   = task.goCmuRush(CGeoPoint(-200,1000), Dir_ball("Assister"), a, f, r, v),
	Special  = task.goCmuRush(p3, Dir_ball("Special"), a, f, r, v),
	Kicker = task.goCmuRush(p2, Dir_ball("Kicker"), a, f, r, v),
	Tier = task.goCmuRush(p1, Dir_ball("Tier"), a, f, r, v),
	Defender = task.goCmuRush(p1, Dir_ball("Tier"), a, f, r, v),
	Goalie = task.goalie(),
    match = "[ASK]{TDG}"
},

["pp"] = {
	switch = function ()

	end,
	Assister = task.stop,
	Special =task.stop,
	Kicker = task.stop,
	-- Tier = task.defender_defence("Tier"),
	-- Defender = task.defender_defence("Defender"),
	Goalie = task.goalie(),
	match = "{ASKTDG}"
},
name = "Ref_KickOffDefV1",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
