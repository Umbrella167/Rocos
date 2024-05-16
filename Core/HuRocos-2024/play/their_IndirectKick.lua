 -- Init 的匹配用表
freeEnemy={}
freePlayer={}
match = {}

-- 获取球位置
local KEEPDIS = 500

-- 朝向球
local balldir = function ()
    return function()
        return player.toBallDir("Assister")
    end
end

local defendPos = CGeoPoint(0,0)
-------------------------------------------------------------------------------------------------
return {

    __init__ = function(name, args)
        print("in __init__ func : ",name, args)
    end,


firstState = "Init",









["Init"] = {
	switch = function ()
		-- 预处理，导入所有车辆
		local freeEnemy_Len = 1
		for i = 0, param.maxPlayer - 1 do
			if enemy.valid(i) then
				freeEnemy[freeEnemy_Len] = i
				freeEnemy_Len = freeEnemy_Len + 1	
			end
		end

		local freePlayer_Len = 1
		for i = 0, param.maxPlayer - 1 do
			if player.valid(i) then
				freePlayer[freePlayer_Len] = i
				freePlayer_Len = freePlayer_Len + 1
			end
		end

		-- 排除最近的机器人并且移出队列
		for i = 1, #freeEnemy do
			if freeEnemy[i] == enemy.closestBall() then
				freeEnemy[i] = freeEnemy[#freeEnemy]
			end
		end

		-- 一人一防
		for i = 1, #freeEnemy do -- E == P
			if i > #freePlayer then -- E > P
				break
			end
			match[freePlayer[i]] = freeEnemy[(i + #freeEnemy - 1) % #freeEnemy + 1] -- E < P

			-- debugEngine:gui_debug_msg(CGeoPoint(0,300 + 150 * i), freePlayer[i].." "..match[freePlayer[i]].." "..((i + #freeEnemy - 1) % #freeEnemy + 1))
			-- debugEngine:gui_debug_msg(CGeoPoint(0,300 + 150 * i), freePlayer[i].." "..match[freePlayer[i]])
		end

		if(bufcnt(true, 5)) then
			Tdebug()
			if #freeEnemy <= #freePlayer then
			else 
				return "Init_marking"
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
		defendPos = ballpos + Utils.Polar2Vector(KEEPDIS,(ball.pos() - StartEnemyPos ):dir())
		debugEngine:gui_debug_msg(CGeoPoint(0,0),defendPos:x(),4)
		debugEngine:gui_debug_msg(CGeoPoint(0,150),defendPos:y(),4)

		if ball.velMod() > 500 then
        	return "exit"
        end
	end,

	Assister = task.goCmuRush( function()return defendPos end ,0,a,0),
    Kicker = function() return task.defender_marking("Kicker",CGeoPoint(param.INF,param.INF)) end,
    Special = function() return task.defender_marking("Special",CGeoPoint(param.INF,param.INF)) end,

    -- Assister = task.stop(),
    -- Kicker = task.stop(),
    -- Special = task.stop(),

    match = "[AKS]"
},
	



name = "their_IndirectKick",
    applicable = {
        exp = "a",
        a = true
    },
    attribute = "attack",
    timeout = 99999
}