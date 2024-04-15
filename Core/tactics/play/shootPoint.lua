
local ballpos = function ()
	return CGeoPoint:new_local(ball.posX(),ball.posY())
end
local balldir = function ()
	return function()
		return player.toBallDir("Assister")
	end
end

local runPos = function()
	return function()
		return CGeoPoint:new_local(run_pos:x(),run_pos:y())
	end
end

local shootPosFun = function()
	if type(param.shootPos) == "function" then
		return param.shootPos()
	else
		return param.shootPos
	end
end

return {

firstState = "ready1",

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
        print(args.pos)
        shoot_pos = args.pos
    end,

["ready1"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint(-1000,1000),shootPosFun():x() .. "   "  .. shootPosFun():y(),3)
		shoot_pos = shootPosFun()
		if(player.infraredCount("Assister") > 5) then
			return "shoot"
		end
	end,
	Assister = task.getball("Assister",param.playerVel,param.getballMode,CGeoPoint:new_local(0,0)),
	match = "[A]"
},

["shoot"] = {
	switch = function()
		-- if(not bufcnt(player.infraredOn("Assister"),1)) then
		-- 	return "ready1"
		-- end
		debugEngine:gui_debug_msg(CGeoPoint(-1000,1000),shootPosFun():x() .. "   "  .. shootPosFun():y(),3)
		if(task.playerDirToPointDirSub("Assister",shootPosFun()) < 8) then 
			return "shoot1"
		end
	end,
	Assister = task.TurnToPointV2("Assister", function() return param.shootPos end,param.rotVel),
	match = "{A}"
},

["shoot1"] = {
	switch = function()
		debugEngine:gui_debug_msg(CGeoPoint(-1000,1000),shootPosFun():x() .. "   "  .. shootPosFun():y(),3)
		if(not bufcnt(player.infraredOn("Assister"),1)) then
			return "ready1"
		end
	end,
	Assister = task.ShootdotV2(function() return param.shootPos end, 10, 8, kick.flat),
	match = "{A}"
},



name = "shootPoint",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}

