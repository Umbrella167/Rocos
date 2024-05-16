local playerCount = {'', '', '', '', '', ''}
local DSS_FLAG = flag.allow_dss + flag.dodge_ball

local readyPosX = param.pitchLength / 2 - 300

local stopPos = function(role)
    for i=1, #playerCount do
    	-- debugEngine:gui_debug_msg(CGeoPoint(1000, 1000+150*i), playerCount[i])
    	if playerCount[i] == role then
    		if i<#playerCount/2 then
	    		return CGeoPoint(readyPosX,-param.pitchWidth / 2 + 300 * i)
    		end
    		return CGeoPoint(readyPosX,param.pitchWidth / 2 - 300 * (#playerCount-i))
    	end
    	if playerCount[i] == '' then
    		playerCount[i] = role
    		return CGeoPoint(readyPosX,-param.pitchWidth / 2 + 300 * i)
    	end
    end
    return CGeoPoint(readyPosX,-param.pitchWidth / 2 + 300)
end

local getBallPos = function()
	local idir = (ball.pos() - param.ourGoalPos):dir()
	local getBallPos = ball.pos() + Utils.Polar2Vector(-param.playerFrontToCenter*2, idir)
	return getBallPos
end


local getBestInterBallPos = function()


end


local subScript = false

return {

	__init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,


firstState = "Init",

["Init"] = {
	switch = function()
		if not subScript then
            gSubPlay.new("Goalie", "Nor_Goalie")
        end
		if cond.isNormalStart() then
			return "Wait"
		end
	end,
    Assister = function() return task.goCmuRush(stopPos("Assister"), 0, a, DSS_FLAG, r, v, s, force_manual) end,
    Kicker = function() return task.goCmuRush(stopPos("Kicker"), 0, a, DSS_FLAG, r, v, s, force_manual) end,
    Special = function() return task.goCmuRush(stopPos("Special"), 0, a, DSS_FLAG, r, v, s, force_manual) end,
    Defender = function() return task.goCmuRush(stopPos("Defender"), 0, a, DSS_FLAG, r, v, s, force_manual) end,
    Tier = function() return task.goCmuRush(stopPos("Tier"), 0, a, DSS_FLAG, r, v, s, force_manual) end,
	Goalie = function() return task.goCmuRush(param.ourGoalPos, player.toBallDir("Goalie"), a, DSS_FLAG) end,
    match = "[AKS]{TDG}"
},

["Wait"] = {
	switch = function()
		local enemyNum = enemy.closestBall()
		if enemy.toBallDist(enemyNum)<param.playerRadius*1.5 then
			return "Getball"
		end
	end,
	Goalie = function() return task.goCmuRush(param.ourGoalPos, player.toBallDir("Goalie"), a, DSS_FLAG) end,
    match = "{G}"
},

["Getball"] = {
	switch = function()
		local enemyNum = enemy.closestBall()

		if ball.velMod() < 100 then
			maxBallVel = 0
		end

		if enemy.toBallDist(enemyNum)>param.playerRadius*4 or ball.velMod()>1000  then
			return "CatchBall"
		end
	end,
	-- Goalie = task.stop(),
	Goalie = function() return task.goSimplePos(getBallPos("Goalie"), player.toBallDir("Goalie"), flag.dribbling) end,
    match = "{G}"
},


["CatchBall"] = {
	switch = function()
		local enemyNum = enemy.closestBall()
		if enemy.toBallDist(enemyNum)<param.playerRadius*2 then
			return "Getball"
		end
		-- if enemy.toBallDist(enmeyNum) < param.playerRadius*2 then
		-- 	return "Getball"
		-- end
	end,
	Goalie = task.stop(),
	-- Goalie = function() return task.goalie_catchBall("Goalie") end,
    match = "{G}"
},

name = "their_Penalty",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
