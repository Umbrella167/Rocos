local balldir = function ()
    return function()
        return player.toBallDir("Assister")
    end
end
-- table.insert(jj,XX)
local depart =0

-- 0 = unlocked
-- 1 = locked
Locked_Enemy={
	--0
	--0
	
}

function Tdebug()
	for i = 0,#Locked_Enemy-1 do
		debugEngine:gui_debug_msg(CGeoPoint(-2000, 2000-150*i), "i: "..i.."     ".."EnemyState: "..Locked_Enemy[i])
	end
end
--获取球位置
local ballpos = ball.pos()
KeepDis = 100
--获取敌人车号
local enemy_num =0
local LockdefendNum = function(role)
	
	local KeepEnemyNum = enemy.closestBall()
	local j =KeepEnemyNum
	Locked_Enemy[j] = 1
	for i = 0,param.maxPlayer -1 do
		if enemy.valid(i) and Locked_Enemy[i] ~= 1 then
			enemy_num = i
			Locked_Enemy[i] = 1
			break
		end	
	end

	return enemy_num
end

local EnemyPos =function (role)
	-- local enemynum = LockdefendNum(role)
	local enemynum = 0



	local enemypos = enemy.pos(enemynum)
	return enemypos
end

local DenfendPosFront = function (role)
	ballpos = ball.pos()
	local denfendPosfront = EnemyPos(role) + Utils.Polar2Vector(KeepDis,(EnemyPos(role)- ballpos):dir() +  math.pi / 3)
	return denfendPosfront
end

local DenfendPosCenter = function (role)
	ballpos = ball.pos()
	local denfendPoscenter = EnemyPos(role) + Utils.Polar2Vector(KeepDis,(EnemyPos(role)- ballpos):dir() +  math.pi / 3)
	return denfendPoscenter
end
-------------------------------------------------------------------------------------------------
return {

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,


firstState = "Init",

["Init"] = {
	switch = function ()
		for i = 0,param.maxPlayer -1 do
			if enemy.valid(i) then
				Locked_Enemy[i] = -1
			else
				Locked_Enemy[i] = -2
			end	
		end


		local ballpos = ball.pos()
		local enemy_num =0
		local KeepEnemyNum = enemy.closestBall()
		local j = KeepEnemyNum
 		Tdebug()
		if ball.posX() < depart then
			return"front"
		else 
			return"center"
		end
	end,
	Assister = function () return (task.goCmuRush(DenfendPosFront("Assister"),balldir("Assister"),DSS_FLAG)) end,
    Kicker = function () return (task.goCmuRush(DenfendPosFront("Kicker"),balldir("Kicker"),DSS_FLAG)) end,
    Special = function () return (task.goCmuRush(DenfendPosFront("Special"),balldir("Special"),DSS_FLAG)) end,
    match = "[AKS]"
},

	
["front"] = {
 	switch = function()
 		--[[local enemypos_1 = enemy.pos(defendNum("Tier"))
		local enemypos_2 = enemy.pos(defendNum("Defender"))--]]
		local ballpos = ball.pos()
		local enemy_num =0
		local KeepEnemyNum = enemy.closestBall()
		local ballpos = ball.pos()
        if ball.velMod() > 500 then
        	return "exit"
        end
 		Tdebug()
 	end,
 	Assister = function () return (task.goCmuRush(DenfendPosFront("Assister"),balldir("Assister"),DSS_FLAG)) end,
    Kicker = function () return (task.goCmuRush(DenfendPosFront("Kicker"),balldir("Kicker"),DSS_FLAG)) end,
    Special = function () return (task.goCmuRush(DenfendPosFront("Special"),balldir("Special"),DSS_FLAG)) end,

	match = "[AKS]"
} ,
["center"] = {
 	switch = function()
 		--[[local enemypos_1 = enemy.pos(defendNum("Tier"))
		local enemypos_2 = enemy.pos(defendNum("Defender"))--]]


		-- if (LockdefendNum("Assister") == 0 and LockdefendNum("Kicker") == 0)then
		-- 	Locked_Enemy={
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 		0,
		-- 	}
		-- end
		debugEngine:gui_debug_msg(CGeoPoint(0,0),LockdefendNum("Assister"),5)
		debugEngine:gui_debug_msg(CGeoPoint(0,200),LockdefendNum("Kicker"),5)
		debugEngine:gui_debug_msg(CGeoPoint(0,400),LockdefendNum("Special"),5)
		local ballpos = ball.pos()
		local enemy_num =0
		local KeepEnemyNum = enemy.closestBall()
		local ballpos = ball.pos()
        if ball.velMod() > 500 then
        	return "exit"
        end
 		Tdebug()
 	end,
 	Assister = function () return (task.goCmuRush(DenfendPosCenter("Assister"),balldir("Assister"),DSS_FLAG)) end,
    Kicker = function () return (task.goCmuRush(DenfendPosCenter("Kicker"),balldir("Kicker"),DSS_FLAG)) end,
    Special = function () return (task.goCmuRush(DenfendPosCenter("Special"),balldir("Special"),DSS_FLAG)) end,
    match = "[AKS]"
} ,


name = "IndirectDefend",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}