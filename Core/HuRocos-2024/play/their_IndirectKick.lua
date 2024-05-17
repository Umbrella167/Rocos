local balldir = function ()
    return function()
        return player.toBallDir("Assister")
    end
end
-- table.insert(jj,XX)
local depart = 0

Free_Enemy={}
Free_Player={}

Match = {}	
--[[function Tdebug()
	for i = 0,#Locked_Enemy-1 do
		debugEngine:gui_debug_msg(CGeoPoint(-2000, 2000-150*i), "i: "..i.."     ".."EnemyState: "..Locked_Enemy[i])
	end
end--]]
--获取球位置
local KeepDis = 270



--获取敌人车号
-- local LockdefendNum = function()
-- 	if enemy.valid(j) and Locked_Enemy[j] ==-1 then
-- 		local enemy_num =0
-- 		enemy_num = j
-- 		Locked_Enemy[j] = -2
-- 	end
-- 	return enemy_num
-- end


local DenfendPosFront = function (role)
	-- debugEngine:gui_debug_msg(CGeoPoint(0,0), player.num(role))
	-- for i =1, #Free_Player do
	-- 	debugEngine:gui_debug_msg(CGeoPoint(0,150+i*150), Free_Player[i])
	-- end

	ballpos = ball.pos()
	local denfendPosfront = enemy.pos(Match[player.num(role)]) + Utils.Polar2Vector(KeepDis, (enemy.pos(Match[player.num(role)]) - ballpos):dir() +  math.pi *2/3)
	return denfendPosfront
end

local DenfendPosCenter = function (role)
	-- debugEngine:gui_debug_msg(CGeoPoint(0,0), player.num(role))
	-- for i =1, #Free_Player do
	-- 	debugEngine:gui_debug_msg(CGeoPoint(0,150+i*150), Free_Player[i])
	-- end
	
	ballpos = ball.pos()
	local denfendPoscenter = enemy.pos(Match[player.num(role)]) + Utils.Polar2Vector(KeepDis, (enemy.pos(Match[player.num(role)]) - ballpos):dir() +  math.pi *2/3)
	return denfendPoscenter

end
local DenfendPos = CGeoPoint(0,0)
-------------------------------------------------------------------------------------------------
return {

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,


firstState = "Init",

["Init"] = {
	switch = function ()
		-- 预处理，导入所有车辆
		local Free_Enemy_Len = 1
		for i = 0, param.maxPlayer - 1 do
			if enemy.valid(i) then
				Free_Enemy[Free_Enemy_Len] = i
				Free_Enemy_Len = Free_Enemy_Len + 1	
			end
		end

		local Free_Player_Len = 1
		for i = 0, param.maxPlayer - 1 do
			if player.valid(i) then
				Free_Player[Free_Player_Len] = i
				Free_Player_Len = Free_Player_Len + 1
			end
		end

		-- 排除最近的机器人并且移出队列
		for i = 1, #Free_Enemy do
			if Free_Enemy[i] == enemy.closestBall() then
				Free_Enemy[i] = Free_Enemy[#Free_Enemy]
			end
		end

		-- 一人一防
		for i = 1, #Free_Enemy do -- E == P
			if i > #Free_Player then -- E > P
				break
			end
			Match[Free_Player[i]] = Free_Enemy[(i + #Free_Enemy - 1) % #Free_Enemy + 1] -- E < P

			-- debugEngine:gui_debug_msg(CGeoPoint(0,300 + 150 * i), Free_Player[i].." "..Match[Free_Player[i]].." "..((i + #Free_Enemy - 1) % #Free_Enemy + 1))
			-- debugEngine:gui_debug_msg(CGeoPoint(0,300 + 150 * i), Free_Player[i].." "..Match[Free_Player[i]])
		end

		if(bufcnt(true, 5)) then
			if  #Free_Enemy >  #Free_Player then
				return"Init_marking"
			else
				if ball.posX() < depart then
					return "front"
				else 
					return "center"
				end
			end
			if ball.velMod() > 500 then
	        		return "exit"
	        end
		end
	end,

	Assister = function () return (task.goCmuRush(player.pos("Assister"),balldir("Assister"),DSS_FLAG)) end,
    Kicker = function () return (task.goCmuRush(player.pos("Kicker"),balldir("Kicker"),DSS_FLAG)) end,
    Special = function () return (task.goCmuRush(player.pos("Special"),balldir("Special"),DSS_FLAG)) end,

    -- Assister = task.stop(),
    -- Kicker = task.stop(),
    -- Special = task.stop(),

    match = "[AKS]"
},

["Init_marking"] = {
	switch = function ()

		local ballpos = ball.pos()
		local StartEnemyPos = enemy.pos(enemy.closestBall()) 
		DenfendPos = ballpos + Utils.Polar2Vector(KeepDis,(ball.pos() - StartEnemyPos ):dir())
		debugEngine:gui_debug_msg(CGeoPoint(0,0),DenfendPos:x(),4)
		debugEngine:gui_debug_msg(CGeoPoint(0,150),DenfendPos:y(),4)

		if ball.velMod() > 500 then
        	return "exit"
        end
	end,

	Assister =task.goCmuRush( function()return DenfendPos end ,0,a,0),
    Kicker = function() return task.defender_marking("Kicker",CGeoPoint(param.INF,param.INF)) end,
    Special = function() return task.defender_marking("Special",CGeoPoint(param.INF,param.INF)) end,

    -- Assister = task.stop(),
    -- Kicker = task.stop(),
    -- Special = task.stop(),

    match = "[AKS]"
},








	
["front"] = {
 	switch = function()
 		
		local ballpos = ball.pos()
        if ball.velMod() > 500 then
        	return "exit"
        end
 		--[[Tdebug()--]]
 	end,
 	Assister = function () return (task.goCmuRush(DenfendPosFront("Assister"),balldir("Assister"),DSS_FLAG)) end,
    Kicker = function () return (task.goCmuRush(DenfendPosFront("Kicker"),balldir("Kicker"),DSS_FLAG)) end,
    Special = function () return (task.goCmuRush(DenfendPosFront("Special"),balldir("Special"),DSS_FLAG)) end,

	match = "[AKS]"
} ,
["center"] = {
 	switch = function()
 		
		-- debugEngine:gui_debug_msg(CGeoPoint(0,0),LockdefendNum("Assister"),5)
		-- debugEngine:gui_debug_msg(CGeoPoint(0,200),LockdefendNum("Kicker"),5)
		-- debugEngine:gui_debug_msg(CGeoPoint(0,400),LockdefendNum("Special"),5)
		local ballpos = ball.pos()
        if ball.velMod() > 500 then
        	return "exit"
        end
 		
 	end,
 	Assister = function () return (task.goCmuRush(DenfendPosCenter("Assister"),balldir("Assister"),DSS_FLAG)) end,
    Kicker = function () return (task.goCmuRush(DenfendPosCenter("Kicker"),balldir("Kicker"),DSS_FLAG)) end,
    Special = function () return (task.goCmuRush(DenfendPosCenter("Special"),balldir("Special"),DSS_FLAG)) end,
    match = "[AKS]"
} ,


name = "their_IndirectKick",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}