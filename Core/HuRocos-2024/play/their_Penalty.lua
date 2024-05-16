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

local getBallPos = function(role)
	local enemyNum = enemy.closestBall()
	local rolePos = player.pos(role)
	local enemyPos = enemy.pos(enemyNum)
    local tPos = Utils.GetBestInterPos(vision, rolePos, param.playerVel, 1, 1,param.V_DECAY_RATE)
    if enemyPos:dist(tPos) < param.playerRadius then
    	tPos = tPos + Utils.Polar2Vector(param.playerRadius, (param.ourGoalPos-enemyPos):dir())
    end
    return tPos
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
			return "Defend"
		end
	end,
    Assister = function() return task.goCmuRush(stopPos("Assister"), 0, a, DSS_FLAG, r, v, s, force_manual) end,
    Kicker = function() return task.goCmuRush(stopPos("Kicker"), 0, a, DSS_FLAG, r, v, s, force_manual) end,
    Special = function() return task.goCmuRush(stopPos("Special"), 0, a, DSS_FLAG, r, v, s, force_manual) end,
    Defender = function() return task.goCmuRush(stopPos("Defender"), 0, a, DSS_FLAG, r, v, s, force_manual) end,
    Center = function() return task.goCmuRush(stopPos("Tier"), 0, a, DSS_FLAG, r, v, s, force_manual) end,
	Goalie = task.goCmuRush(param.ourGoalPos, player.toBallDir("Goalie"), a, DSS_FLAG),
    match = "[AKSC]{DG}"
},

["Defend"] = {
	switch = function()
		-- debugEngine:gui_debug_msg(CGeoPoint(0,0),ball.posX())
		-- if bufcnt(ball.pos():dist(enemy.pos(enemy.closestBall())) < param.playerRadius * 1.5, 20) then
		-- 	return "Getball"
		-- end
		return "CatchBall"

		-- if bufcnt(ball.pos():dist(enemy.pos(enemy.closestBall())) < param.playerRadius * 1.5, 20) then
		-- 	return "Getball"
		-- end
	end,
	Goalie = gSubPlay.roleTask("Goalie", "Goalie"),
	-- Leader = task.getball(function() return shoot_pos end,playerVel,getballMode),
    match = "{G}"
},


["CatchBall"] = {
	switch = function()
		-- debugEngine:gui_debug_msg(CGeoPoint(0,0),ball.posX())
		-- if ball.pos():dist(enemy.pos(enemy.closestBall())) > param.playerRadius * 1.5 then
		-- 	return "Defend"
		-- end
		-- if ball.posX() < player.posX("Goalie") then
		-- 	return "CatchBall"
		-- end

	end,
	Goalie = function() return task.goalie_catchBall("Goalie") end,
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
