module(..., package.seeall)

local f = flag.dribbling --  + flag.dodge_ball + flag.allow_dss
-- local p = CGeoPoint:new_local(1000,1000)
local p = CGeoPoint:new_local(3000,0)
local p1 = CGeoPoint:new_local(500,0)
local O = CGeoPoint:new_local(0,0)
local Home1 = CGeoPoint:new_local(-3300,1000)
local Home2 = CGeoPoint:new_local(-3300,0)
local Home3 = CGeoPoint:new_local(-3300,-1000)
local pos = function()
	return function()
		return task.GetShootdot()
	end
end

local pos_self = function(role)
	return function()
		return player.pos(role)
	end
end

local GoalPos = function()
	return function()
		return task.GetGoalPos(task.GetDefenseEnemyNum())
	end
end

local Dir_ball = function(role)
	return function()
		return (ball.pos() - player.pos(role)):dir()
	end
end


local Dir_goal = function(role)
	return function()
		return (task.GetGoalPos(task.GetDefenseEnemyNum()) - player.pos(role)):dir()
	end
end
function Getballv4_BallPlacement(role,p)
	return function()
		local p1 = p
		if type(p) == 'function' then
		  	p1 = p()
		else
		  	p1 = p
		end	
		    local ball_line = CGeoLine:new_local(ball.pos(),ball.velDir())
			local target_pos = (ball_line:projection(player.pos(role))):y()
		if target_pos < 500 and target_pos > -500 then--(((ball.pos()-CGeoPoint:new_local(-3000,500)):dir() * 57.3+180)) > 180 and math.abs(ball.posX())<3000 then
		    -- local ball_line = CGeoLine:new_local(ball.pos(),ball.velDir())
			-- local target_pos = (ball_line:projection(player.pos(role))):y()
			local mexe, mpos = GoCmuRush{pos = CGeoPoint:new_local(-4500,target_pos), dir = (ball.pos() - player.pos(role)):dir(), acc = a, flag = 0x00000100,rec = r,vel = v}
			debugEngine:gui_debug_x(CGeoPoint:new_local(-4500,target_pos),3)
			return {mexe, mpos}
		end

	end
end

function ShootdotV2_BallPlacement(p,Kp,error_,flag)
	return function()
		local p1
		if type(p) == 'function' then
	  		p1 = p()
		else
	  		p1 = p
		end
		local Kp1 = (p1 - CGeoPoint:new_local(goalPos[1],goalPos[2])):mod() < 200 and Kp * 1000000 or Kp
		local shootpos = function(runner)
			return ball.pos() + Utils.Polar2Vector(-100,(p1 - ball.pos()):dir())
		end
		local idir = function(runner)
			return (p1 - player.pos(runner)):dir()
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end
		local mexe, mpos = GoCmuRush{pos = shootpos, dir = idir, acc = a, flag = 0x00000100 ,rec = r,vel = v}
		return {mexe, mpos, flag, idir, error__, power(p,Kp1), power(p,Kp1), 0x00000000}
	end
end
function GetBallV2_BallPlacement(role,p,dist,speed)-------dist开始减速的距离   speed减速的速度 dist 500 speed 200
	return function()
		local p1 = p
	   local retNum

	   if type(p) == "string" then
		    -- retNum = gRoleNum[role]
		    p1 = vision:ourPlayer(gRoleNum[p]):Pos()
		else
		   if type(p) == 'function' then
		  	   p1 = p()
		   else
		  	   p1 = p
		   end
		end
		if(player.infraredCount(role) < 20) then
			if((player.pos(role) - ball.pos()):mod() < dist) then
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(0,idir)
				local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = speed, flag = 0x00000100 + 0x04000000,rec = r,vel = v}
				return {mexe, mpos}
			else
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(-dist + 15,idir)
				local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = a, flag = 0x00000100 + 0x04000000,rec = r,vel = v}
				return {mexe, mpos}
			end
		else
			local pp = player.pos(role)
			local idir = (p1 - player.pos(role)):dir()
			local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = 1, flag = 0x00000100 + 0x04000000,rec = r,vel = v}
			return {mexe, mpos}
		end
	end
end








function power (p,Kp) --根据目标点与球之间的距离求出合适的 击球力度 kp系数需要调节   By Umbrella 2022 06
	return function()
		local p1
		if type(p) == 'function' then
	  		p1 = p()
		else
	  		p1 = p
		end
		local a = Kp * (p1 - ball.pos()):mod()
		-- if a > 310 then
		-- 	a = 310
		-- end
		-- if a < 230 then
		-- 	a = 230
		-- end

		-- if Kp == -1 then
		-- 	a = 130
		-- end
		if a > 7000 then
			a = 7000
		end
		if a < 3400 then
			a = 5000
		end


		debugEngine:gui_debug_msg(CGeoPoint:new_local(-4300,-2000),a,3)
		return a
	end
end


function Shootdot(p,Kp,error_,flag)
--将球射向某一个点（会动态规划射门力度）  
--p 目标点     
--ifInter参数就填false
--Kp 力度系数 
--error_ 误差
--flag:kick.chip or kick.flat By Umbrella 2022 07
	return function()
		local p1
		if type(p) == 'function' then
	  		p1 = p()
		else
	  		p1 = p
		end

		local ipos = p1 or pos.theirGoal()
		local idir = function(runner)
			return (ipos - player.pos(runner)):dir()
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end
	local mexe, mpos = Touch{pos = p, useInter = false}
		return {mexe, mpos, flag, idir, error__, power(p,Kp), power(p,Kp), 0x00000000}
	end
end


function Shootdot__(p,ifInter,Kp,error_,flag)
--将球射向某一个点（会动态规划射门力度）  
--p 目标点     
--ifInter参数就填false
--Kp 力度系数 
--error_ 误差
--flag:kick.chip or kick.flat By Umbrella 2022 07
	return function()
		local p1
		if type(p) == 'function' then
	  		p1 = p()
		else
	  		p1 = p
		end
		local ipos = p1 or pos.theirGoal()
		local idir = function(runner)
			return (ipos - player.pos(runner)):dir()
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end
	local mexe, mpos = Touch{pos = p, useInter = ifInter}
		return {mexe, mpos, flag, idir, error__, kp.specified(8000), kp.specified(8000), 0x00000000}
	end
end






function ShootdotV2(p,Kp,error_,flag)
	return function()
		local p1
		if type(p) == 'function' then
	  		p1 = p()
		else
	  		p1 = p
		end
		local Kp1 = (p1 - CGeoPoint:new_local(goalPos[1],goalPos[2])):mod() < 200 and Kp * 1000000 or Kp
		local shootpos = function(runner)
			return ball.pos() + Utils.Polar2Vector(-50,(p1 - ball.pos()):dir())
		end
		local idir = function(runner)
			return (p1 - player.pos(runner)):dir()
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end

		if Kp == -1 then
			Kp1 = -1
		end
		local mexe, mpos = GoCmuRush{pos = shootpos, dir = idir, acc = a, flag = 0x00000100 ,rec = r,vel = v}
		return {mexe, mpos, flag, idir, error__, power(p,Kp1), power(p,Kp1), 0x00000000}
	end
end

function 
	ShootdotV2__(p,Kp,error_,flag)
	return function()
		local p1
		if type(p) == 'function' then
	  		p1 = p()
		else
	  		p1 = p
		end
		local Kp1 = (p1 - CGeoPoint:new_local(goalPos[1],goalPos[2])):mod() < 200 and Kp * 1000000 or Kp
		local shootpos = function(runner)
			return ball.pos() + Utils.Polar2Vector(-50,(p1 - ball.pos()):dir())
		end
		local idir = function(runner)
			return (p1 - player.pos(runner)):dir()
		end
		local error__ = function()
			return error_ * math.pi / 180.0
		end

		if Kp == -1 then
			Kp1 = -1
		end
		local mexe, mpos = GoCmuRush{pos = shootpos, dir = idir, acc = a, flag = 0x00000100 ,rec = r,vel = v}
		return {mexe, mpos, flag, idir, error__, kp.specified(8000), kp.specified(8000), 0x00000000}
	end
end



----------------------------------------------------------------------------------------------------------
-- 500 ~ 250
-- 250 ~ 0
-- 0 ~ -250

goalPos = {
	4500,--更改标记#########################################################################################
	0,
}

function GetGoalPos(num) --计算出对面守门员的空位
	if num == -1 then
		debugEngine:gui_debug_x(CGeoPoint:new_local(4500,0))
		return CGeoPoint:new_local(4500,0)
	end
	local y = enemy.posY(num)
	if enemy.posY(num) >= 0 then
			goalPos[2] =  y - (y + 500) / 2 --更改标记#########################################################################################
	else
			goalPos[2] =  y + (500 - y) / 2
	end
	debugEngine:gui_debug_x(CGeoPoint:new_local(goalPos[1],goalPos[2]))
	return CGeoPoint:new_local(goalPos[1],goalPos[2])
end

function GetDefenseEnemyNum()--找到对面守门员的号码
	local enemyX
	local enemyY
	local num = -1
	for i=0,param.maxPlayer do--更改标记#########################################################################################
		if(enemy.valid(i)) then 
			enemyX = enemy.posX(i)
			enemyY = enemy.posY(i)
			if enemyX > 3500 and enemyX < 4700 and enemyY > -1000 and enemyY < 1000 then
				return i
			end
		end
	end
	return num
end

-------------------------------------------------------算法工具-----------------------------------------------------------
--by Umbrella
function dotEnemyDistance(dotx,doty,num) --求xy 到某球员的距离
	return (CGeoPoint:new_local(dotx,doty) - enemy.pos(num)):mod()
end

function slope_local(x,y,x1,y1) --求两坐标之间的斜率
	local k = 0
	k =  (x - x1) / (y - y1) 
	return math.abs(math.atan(k) * 57.3)
end
-------------------------------------------------------算法工具-----------------------------------------------------------


--------------------------得分函数---------------------------------------by Umbrella

function grade_pass_ShowTime(x,y)
	if between_dotV2(CGeoPoint:new_local(x,y),ball.pos(),50) == 0 then
		return -99
	else 
		return 0
	end
end

function grade_pass_Point(x,y)
	if between_dotV2(CGeoPoint:new_local(x,y),CGeoPoint:new_local(goalPos[1],goalPos[2]),100) == 1 then
		return 0
	else 
		return -999
	end
end

function grade_pass(x,y)
	if between_dotV2(CGeoPoint:new_local(x,y),CGeoPoint:new_local(goalPos[1],goalPos[2]),150) == 1 and between_dotV2(CGeoPoint:new_local(x,y),ball.pos(),150) == 1 then
		return 0
	else 
		return -99999
	end
end
function grade_goal(dotx,doty)  --球门 与坐标点 得分函数 归一化
	return 1400 / math.sqrt((dotx - goalPos[1])^2 + (doty - goalPos[2])^2)
end

-- function grade_enemy(x,y)   --敌人位置 与坐标点 得分函数  归一化
-- 	local grade = 0
-- 	enemy_dis = {}
-- 	enemy_min = 0
-- 	enemy_grade = 0
-- 	local j = 1
-- 	for i = 1,#enemy_valid do
-- 			enemy_dis[i] = dotEnemyDistance(x,y,enemy_valid[i])
-- 	end 
-- 	-- local enemy_min = math.max(unpack(enemy_dis))
-- 	for i = 1,#enemy_dis do 
-- 		if enemy_dis[i] == enemy_min then
-- 			enemy_dis[i] = 0
-- 		end
-- 		enemy_grade = enemy_grade + 20 * enemy_dis[i]
-- 	end
-- 	enemy_grade = enemy_grade + 0.8 * enemy_min 

-- 	return enemy_grade / 5100 / 20
-- end


function grade_enemy(x,y)
	local enemyDis = {}
	local minDist = 9999999
	local enemy_grade = 0
	for i=1,#enemy_valid do
		enemyDis[i] = dotEnemyDistance(x,y,enemy_valid[i]) 
		if minDist > enemyDis[i] then
			minDist = enemyDis[i]
		end
		enemy_grade = enemy_grade + enemyDis[i] 
	end
	enemy_grade = 1.5 * (enemy_grade - minDist) + 3 * minDist
	return enemy_grade / 50000 
end


function grade_playerV3(x,y,r)   --检测该点附近有无player 有则直接Pass
	local playerDis
	local minDist = 9999999
	for i=1,#player_valid do
		playerDis = (player.pos(player_valid[i]) - CGeoPoint:new_local(x,y)):mod()
		if minDist > playerDis then
			minDist = playerDis
		end
	end
	if minDist < r then  
		return -999
	end
	return 0
end


function grade_ball(x,y) -- 球位置 得分函数 归一化
	local ballX = ball.posX()
	local ballY = ball.posY()
	return 1 - math.sqrt((x - ballX)^2 + (y - ballY)^2) / 10816
end

function grade_dir_goal(x,y) --射门角度得分函数 归一化
	local dirS = slope_local(x,y,goalPos[1],goalPos[2])
	local res = dirS > 80 and (dirS / 90 * math.pi) + 0.3 or math.sin(dirS / 90 * math.pi)
	if dirS > 5 and dirS < 30 then
		res = res - 0.4
	end
	if res > 2 then 
		res = res - 2.7
	end
	return res
end

function grade_Mydis(role,x,y) --xy 与某角色的距离  伪高斯分布 + 归一化
	local p = player.pos(role)
	local px = p:x()
	local py = p:y()
	return 1 - math.sin( math.sqrt( (px - x)^2 + (py - y)^2) / 1000 / 2)
	--return 1 - (CGeoPoint:new_local(x,y) - player.pos(role)):mod() / 3000
end




function XYroleBallIsLine(p,role,error) -- 检测 某座标点  球  playe 是否在一条直线上
	if type(p) == 'function' then
	  	p1 = p()
	else
	  	p1 = p
	end
	local dir_pass = (ball.pos() - player.pos(role)):dir() * 57.3 + 180
	local dir_xy = (p1 - ball.pos()):dir() * 57.3 + 180
	local sub = math.abs(dir_pass - dir_xy)
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-1000,0),sub)
	if sub < error then
		return true
	else 
		return false
	end
end

function XYroleBallDirIsLine(role,error) 
	local dir_pass = ball.velDir() * 57.3 + 180
	local dir_xy = (p1 - ball.pos()):dir() * 57.3 + 180
	local sub = math.abs(dir_pass - dir_xy)
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-1000,0),sub)
	if sub < error then
		return true
	else 
		return false
	end
end




function BallLineToMe(role,error) -- 检测 球的运动轨迹是否 在一条直线上
	if type(p) == 'function' then
	  	p1 = p()
	else
	  	p1 = p
	end
	local dir_pass = (player.pos(role) - ball.pos()):dir() * 57.3 + 180
	local dir_xy = ball.velDir() * 57.3 + 180
	local sub = math.abs(dir_pass - dir_xy)
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-1000,0),sub)
	if sub < error then
		return true
	else 
		return false
	end
end










function grade_pass_line(x,y,role) --- 传球概率得分
	local dir_pass = (ball.pos() - player.pos(role)):dir() * 57.3 + 180
	local dir_xy = (CGeoPoint:new_local(x,y) - ball.pos()):dir() * 57.3 + 180
	local sub = math.abs(dir_pass - dir_xy)
	grade = 1 - (sub / 360)
	if grade < 0.2 then 
		grade = 0.9 - grade
	end
	if grade < 0.8 and grade > 0.3 then
		grade = 0
	end

	return grade
end



function grade_Gaussian_dis_ball(x,y) --坐标点与球的距离得分函数   伪高斯分布 + 归一化
	local  grade = math.abs(math.sin(((ball.pos() - CGeoPoint:new_local(x,y)):mod() / 5200) * math.pi))
	return grade
end

--------------------------得分函数---------------------------------------by Umbrella





-- ShowTime：以Role为圆心 均匀撒点（将R均匀分层N端作为r 以r的周长撒点） 计算每个点的收益。
-- AIattack：以自己的8个方位为预选点，计算收益（贪心 8 * N 限定运球距离 R * PI）
angle = 0

 --以球为中点作圆周，SPEED为：1～10  越大越满
 --p面向位置
 function GoCircula(role,r,SPEED,p)   --某角色以球为中心点 绕着半径为r的圆做圆周 直到 人 球 坐标点 为一条直线
 	return function ()
 		local p1 = p
		if type(p) == 'function' then
		  	p1 = p()
		else
		  	p1 = p
		end
 		local sub
 		local myDir
 		local pDir
 		myDir = 180 - (ball.pos()- player.pos(role) ):dir() * 57.3 
 		pDir = 180 - (p1 - ball.pos()):dir() * 57.3
 		sub = math.abs(myDir - pDir)
 		if sub < 15 then
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(-120,idir)	
				local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = a, flag = 0x00000100,rec = r,vel = v}
				return {mexe, mpos}
 		else	
		 		local p = CGeoPoint:new_local(ball.posX() + r * math.cos(angle) ,ball.posY() + r * math.sin(angle))
		 		angle = angle + math.pi * 2/(SPEED*50)
		 		debugEngine:gui_debug_x(p,3)
		 		local mexe, mpos = GoCmuRush{pos = p, dir = (ball.pos() - p):dir(), acc = 2000, flag = flag.dribbling,rec = r,vel = v}
				return {mexe, mpos}
 		end
 	end
 end

StartPos = CGeoPoint:new_local(0,0)
StartPosBall = CGeoPoint:new_local(0,0)
--------------------------------------------------------------------------------------------------------
-- email：1670187757@qq.com
--by Umbrella
--2022-07 ~ 2023~01

--GetBall V系列
--V2 去拿球 拿到球以后 转向指定地点
--V3 去拿球 拿到球以后以球为圆心 旋转到 player 球 目标点 一条直线的位置（建议：使用V3前一个State应该用V2 因为V3有一个初始值要在V2中读取）
--V4 使用条件：当球在运动过程时       效果：能够精准的到合适的地方接球   通常用在传球的时候 接球人上
-------------------------------------------------------------------------------------------------------------
angle = 0
function GetBallV2(role,p,dist,speed)-------dist开始减速的距离   speed减速的速度 
--参数说明
--role  使用这个函数的角色
--p	    拿到球后指向的目标点
--dist  距离球dist mm时开始减速
--speed 减速后的速度 （范围 0～2500）			
	return function()
		local dist1
		local minDist = 9999999
		local minNum = 0 
		local speedKP = 1
		local ballspeed = 800
		angle = (player.pos(role) - ball.pos()):dir()
		for i=1,#enemy_valid - 1 do
			dist1= (enemy.pos(enemy_valid[i]) - ball.pos()):mod()
			if minDist >= dist1 then
				minDist = dist1
				minNum = i - 1
			end
		end

		local p1 = p
		if type(p) == 'function' then
		  	p1 = p()
		else
		  	p1 = p
		end
		if(player.infraredCount(role) < 20) then
			if((player.pos(role) - ball.pos()):mod() < dist)then
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(0,idir)
				if ball.velMod() > ballspeed and minDist > 180 then
					pp = ball.pos() + Utils.Polar2Vector(350,idir)
				end
				local mexe, mpos = GoCmuRush{pos = pp,dir = idir,acc = speed,flag = 0x00000100,rec = r,vel = v}
				return {mexe, mpos}
			else
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(-1 * dist + 10,idir)
				if ball.velMod() > ballspeed and minDist > 180 then
					pp = ball.pos() + Utils.Polar2Vector(350,idir)
				end
				local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = a, flag = 0x00000100,rec = r,vel = v}
				return {mexe, mpos}
			end
		else

			local pp = player.pos(role)	
			local idir = (p1 - player.pos(role)):dir()
				debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),3)

			local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = 1, flag = 0x00000100,rec = r,vel = v}
			return {mexe, mpos}
		end
	end
end

function GetBallV2__(role,p,dist,speed)-------dist开始减速的距离   speed减速的速度 
--参数说明
--role  使用这个函数的角色
--p	    拿到球后指向的目标点
--dist  距离球dist mm时开始减速
--speed 减速后的速度 （范围 0～2500）			
	return function()
		local dist1
		local minDist = 9999999
		local minNum = 0 
		local speedKP = 1
		local ballspeed = 2000
		angle = (player.pos(role) - ball.pos()):dir()
		for i=1,#enemy_valid - 1 do
			dist1= (enemy.pos(enemy_valid[i]) - ball.pos()):mod()
			if minDist >= dist1 then
				minDist = dist1
				minNum = i - 1
			end
		end

		local p1 = p
		if type(p) == 'function' then
		  	p1 = p()
		else
		  	p1 = p
		end
		if(player.infraredCount(role) < 20) then
			if((player.pos(role) - ball.pos()):mod() < dist)then
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(0,idir)
				if ball.velMod() > ballspeed and minDist > 180 then
					pp = ball.pos() + Utils.Polar2Vector(ball.velMod() * speedKP,idir)
				end
				local mexe, mpos = GoCmuRush{pos = pp,dir = idir,acc = speed,flag = 0x00000100,rec = r,vel = v}
				return {mexe, mpos}
			else
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(150,idir)
				if ball.velMod() > ballspeed and minDist > 180 then
					pp = ball.pos() + Utils.Polar2Vector(ball.velMod() * speedKP,idir)
				end
				local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = a, flag = 0x00000100,rec = r,vel = v}
				return {mexe, mpos}
			end
		else

			local pp = player.pos(role)	
			local idir = (p1 - player.pos(role)):dir()
				debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),3)

			local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = 1, flag = 0x00000100,rec = r,vel = v}
			return {mexe, mpos}
		end
	end
end
function GetBallV2PLUS(role,a,flag)-------dist开始减速的距离   speed减速的速度 
--参数说明 
--role  使用这个函数的角色
--p	    拿到球后指向的目标点
--dist  距离球dist mm时开始减速
--speed 减速后的速度 (范围 0～2500)
	return function()
		local dist
		local minDist = 9999999
		local minNum
		angle = (player.pos(role) - ball.pos()):dir()
		for i=1,#enemy_valid - 1 do
			dist= (enemy.pos(enemy_valid[i]) - ball.pos()):mod()
			if minDist >= dist then
				minDist = dist
				minNum = i - 1
			end
		end
		if player.infraredCount(role) < 1 then
			local p_ini = ball.pos() + Utils.Polar2Vector(150,(ball.pos() - enemy.pos(0)):dir())
			local dir_ini = ( ball.pos() - player.pos(role) ):dir()
			local mexe, mpos = GoCmuRush{pos = p_ini, dir = dir_ini, acc = a, flag = flag,rec = r,vel = v}
			return {mexe, mpos}
		end
	end
end



function GetBallV3(role,p,dist,speed,r,SPEED,R,error)-------dist开始减速的距离   speed减速的速度 
--待优化： 旋转的方向应该离停止点最近

--参数说明 
--role   使用这个函数的角色
--p	     拿到球后指向的目标点
--dist   距离球dist mm时开始减速
--speed  减速后的速度 （范围 0～2500）
--r      转圈半径
--SPEED  圆周速度 (取值范围 2～10  2的速度最大）
--R      停止后离球距离 
--error  停车误差
	return function()
-- p1 startpos startposball
		local p1 = p
		if type(p) == 'function' then
		  	p1 = p()
		else
		  	p1 = p
		end
 		local sub
 		local myDir
 		local pDir
 		local myDir_change
 		local pDir_change
 		local FTBP 
 		myDir = 180 - (ball.pos()- player.pos(role) ):dir() * 57.3 
 		pDir = 180 - (p1 - ball.pos()):dir() * 57.3
 		sub = math.abs(myDir - pDir)
 		if sub < error then
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(-R,idir)
				local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = a, flag = 0x00000100,rec = r,vel = v}
				return {mexe, mpos}
 		else
		 		local p = CGeoPoint:new_local(ball.posX() + r * math.cos(angle) ,ball.posY() + r * math.sin(angle))
				if(StartPos:y()) - (StartPosBall:y())  < 0  and p1:x()<0 then
		 			angle = angle + math.pi * 2/(SPEED*60) 
		 		end 

		 		if (StartPos:y()) - (StartPosBall:y()) > 0  and p1:x()<0 then
		 			angle = angle - math.pi * 2/(SPEED*60)
		 		end
		 		if(StartPos:y()) - (StartPosBall:y())  < 0  and p1:x()>0 then
		 			angle = angle - math.pi * 2/(SPEED*60)
		 		end
		 		if(StartPos:y()) - (StartPosBall:y())  > 0  and p1:x()>0 then
		 			angle = angle + math.pi * 2/(SPEED*60)
		 		end
		 		local mydir = (StartPosBall - player.pos(role)):dir()--player.toBallDir(role)
		 		local mexe, mpos = GoCmuRush{pos = p, dir = mydir, acc = 2000, flag = 0x00000100,rec = r,vel = v}
				return {mexe, mpos}
 		end
	end
	-- end
end
--V4 使用条件：当球在运动过程时       效果：能够精准的到合适的地方接球   通常用在传球的时候接球人上
function Getballv4(role,p)
--参数说明 
--role   使用这个函数的角色
--p	     等待位置
	return function()
		local p1 = p
		if type(p) == 'function' then
		  	p1 = p()
		else
		  	p1 = p
		end
		if ball.velMod() > 1000 then
			local ball_line = CGeoLine:new_local(ball.pos(),ball.velDir())
			local target_pos = ball_line:projection(player.pos(role))
			local mexe, mpos = GoCmuRush{pos = target_pos, dir = (ball.pos() - player.pos(role)):dir(), acc = a, flag = 0x00000100,rec = r,vel = v}
			return {mexe, mpos}
		-- elseif ball.velMod() > 2000 and ball.velMod() < 2000  and (ball.pos() - player.pos(role)):mod() > 150 then
		-- 	local mexe, mpos = GoCmuRush{pos = ball.pos() + Utils.Polar2Vector(100,(player.pos(role) - ball.pos()):dir()), dir = (ball.pos() - player.pos(role)):dir(), acc = a, flag = 0x00000100,rec = r,vel = v}
		-- 	return {mexe, mpos}
		else 
			local mexe, mpos = GoCmuRush{pos = p1, dir = (ball.pos() - player.pos(role)):dir(), acc = a, flag = 0x00000100,rec = r,vel = v}
			return {mexe, mpos}
		end

	end
end



------------------------------------------1670187757@qq.com--------------------------------------------------------
----------------------------Simple dynamic programming algorithm + greedy algorithm-----------------------------------------------
------------------------------------------2023-3-20 by Umbrella--------------------------------------------------------

--与GetballV3类似 但是 ShowTIme版会将球运到指向的地点   且可开启带球功能 
--role   使用这个函数的角色
--p	     拿到球后指向的目标点
--dist   距离球dist mm时开始减速
--speed  减速后的速度 （范围 0～2500）
--r      转圈半径
--SPEED  圆周速度 (取值范围 2～10  2的速度最大）
--R      停止后离球距离 
--error  停车误差
function ShowTIme_GetBallV3(role,p,dist,speed,r,SPEED,R,error)-------dist开始减速的距离   speed减速的速度 
	return function()
		local p1 = p
		if type(p) == 'function' then
		  	p1 = p()
		else
		  	p1 = p
		end

		if(player.infraredCount(role) < 5) then
			angle = (player.pos(role) - ball.pos()):dir()
			if((player.pos(role) - ball.pos()):mod() < dist) then
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(0,idir)
				local mexe, mpos = GoCmuRush{pos = pp,dir = idir,acc = speed,flag = 0x00000100,rec = r,vel = v}
				return {mexe, mpos}
			else
				local idir = (ball.pos() - player.pos(role)):dir()
				local pp = ball.pos() + Utils.Polar2Vector(-1 * dist + 10,idir)
				local mexe, mpos = GoCmuRush{pos = pp, dir = idir, acc = a, flag = 0x00000100,rec = r,vel = v}
				return {mexe, mpos}
			end
		else
			local p1 = p
			if type(p) == 'function' then
			  	p1 = p()
			else
			  	p1 = p
			end
	 		local sub
	 		local myDir
	 		local pDir
	 		local error_ = error
	 		myDir = 180 - (ball.pos()- player.pos(role) ):dir() * 57.3 
	 		pDir = 180 - (p1 - ball.pos()):dir() * 57.3
	 		sub = math.abs(myDir - pDir)
	 		if (player.pos(role) - p1):mod() < 100 then
					local idir = (p1 - player.pos(role)):dir()
					local mexe, mpos = GoCmuRush{pos = player.pos(role), dir = idir, acc = a, flag = 0x00000100,rec = r,vel = v}
					return {mexe, mpos}
	 		end
		 		if sub < error_ then
						-- if (ball.pos() - p1):mod() > 500 and player.infraredCount(role) > 1 then  											----------------------------------------------
						-- 	local iiidir = (p1 - player.pos(role)):dir()																	----------------------------------------------
						-- 	local mexe, mpos = GoCmuRush{pos = p, dir = iiidir, acc = 3000, flag = f,rec = r,vel = v}						----------------------------------------------
						-- 	return {mexe, mpos, kick.flat, dir.shoot(), pre.lowist, kp.specified(1000), cp.full, 0x00000100}				----------------------------------------------
						-- elseif (ball.pos() - p1):mod() > 100 and player.infraredCount(role) == 0 then										-------------------若不要运球功能则直接将---------
						-- 	local idir = (p1 - player.pos(role)):dir() 																		------------------------标记处注释--------------
						-- 	local mexe, mpos = GoCmuRush{pos = ball.pos(), dir = idir, acc = 3000, flag = 0x00000100,rec = r,vel = v}		----------------------------------------------
						-- 	return {mexe, mpos} 																							----------------------------------------------
						-- else 																										---------------------------------------------
							local idir = (p1 - player.pos(role)):dir()
							local mexe, mpos = GoCmuRush{pos = p, dir = idir, acc = a, flag = 0x00000100,rec = r,vel = v}
							return {mexe, mpos}
						-- end 																												----------------------------------------------
		 		else
		 			local p = CGeoPoint:new_local(ball.posX() + r * math.cos(angle) ,ball.posY() + r * math.sin(angle))
					if(StartPos:y()) - (StartPosBall:y())  < 0  and p1:x()<0 then
			 			angle = angle + math.pi * 2/(SPEED*60) 
			 		end 

			 		if (StartPos:y()) - (StartPosBall:y()) > 0  and p1:x()<0 then
			 			angle = angle - math.pi * 2/(SPEED*60)
			 		end
			 		if(StartPos:y()) - (StartPosBall:y())  < 0  and p1:x()>0 then
			 			angle = angle - math.pi * 2/(SPEED*60)
			 		end
			 		if(StartPos:y()) - (StartPosBall:y())  > 0  and p1:x()>0 then
			 			angle = angle + math.pi * 2/(SPEED*60)
			 		end
			 		local mexe, mpos = GoCmuRush{pos = p, dir = (StartPosBall - player.pos(role)):dir(), acc = 2000, flag = 0x00000100,rec = r,vel = v}
					return {mexe, mpos}
		 		end

			end
	end
end

StartPos = CGeoPoint:new_local(0,0)
StartPosBall = CGeoPoint:new_local(0,0)
function ShowTimeV1_ini(role,flag) --若要使用ShowTimeV1 需要在前面加上此函数
	local infraredCount = player.infraredCount(role)
	if infraredCount < 10 then
		StartPos = CGeoPoint:new_local(player.posX(role),player.posY(role))
		StartPosBall = CGeoPoint:new_local(ball.posX(),ball.posY())
	end
	if flag == 1 then
		-- StartPosBall = CGeoPoint:new_local(ball.posX(),ball.posY())
		-- StartPosGetballV3 = CGeoPoint:new_local(ball.posX(),ball.posY())
	end
	if (player.pos(role) - ball.pos()):mod() > 200 then
		StartPos_ShowTime = CGeoPoint:new_local(player.posX(role),player.posY(role))
		angle = (player.pos(role) - ball.pos()):dir()	
	end
	-- if (player.pos(role) - ball.pos()):mod() > 200 then
	-- 	StartPos = CGeoPoint:new_local(player.posX(role),player.posY(role))
	-- end
	--debugEngine:gui_debug_msg(CGeoPoint:new_local(0, 0),StartPos:x().."             "..StartPos:y(),3)
end
ShowTimeV1Pos = CGeoPoint:new_local(0,0)

ShowTimeV1Dir = 0
--此函数可以算出带球的目标点 以第一次触球为中心展开一个R为半径的法阵  然后算出下一秒应该去的位置
--具体用法 放在switch内
--	task.ShowTimeV1_ini("Kicker")
--  task.ShowTimeV1("Kicker",1000,4)
--然后调用ShowTimeV1Pos
-- 






randomCont = 0
-- function ShowTimeV2(role,speed)
-- 	return function()
-- 	local safetyDist = 300
-- 	local dist1
-- 	local minDist = 9999999
-- 	local minNum
-- 	local speedKP = 1
-- 	math.randomseed(os.time())
-- 	local flag = math.random(1,2)
-- 	local CrossOverFlag = math.random(1,2)
-- 	randomCont = randomCont + 1
-- 	local Symbol = 1
-- 	local newdist = -500 
-- 	for i=1,#enemy_valid - 1 do
-- 		dist1= (enemy.pos(enemy_valid[i]) - ball.pos()):mod()
-- 		if minDist >= dist1 then
-- 			minDist = dist1
-- 			minNum = i - 1
-- 		end
-- 	end
-- 	if player.infraredCount(role) > 10 then
-- 		if minDist > safetyDist then
-- 			if flag == 1  then
-- 				-- BackOff
-- 				local p = player.pos(role) + Utils.Polar2Vector(newdist,(ball.pos() - player.pos(role)):dir())
-- 			 	local mexe, mpos = GoCmuRush{pos = p, dir = (ball.pos() - player.pos(role)):dir(), acc = speed, flag = 0x00000100,rec = r,vel = v}
-- 				return {mexe, mpos}
-- 			end
-- 			if flag == 2 then
-- 				-- CrossOver
-- 				if CrossOverFlag == 1 then
-- 					Symbol = 1
-- 				else
-- 					Symbol = -1
-- 				end
-- 				local p = player.pos(role) + Utils.Polar2Vector(newdist,(ball.pos() - player.pos(role)):dir() + Symbol * (math.pi / 2))
-- 			 	local mexe, mpos = GoCmuRush{pos = p, dir = (ball.pos() - player.pos(role)):dir(), acc = speed, flag = 0x00000100,rec = r,vel = v}	
-- 				return {mexe, mpos}
-- 			end
-- 			if flag == 3 then
-- 				-- TurnToPoint
-- 			end
-- 		else
-- 			--BackOff
-- 				local p = player.pos(role) + Utils.Polar2Vector(newdist,(ball.pos() - player.pos(role)):dir())
-- 			 	local mexe, mpos = GoCmuRush{pos = p, dir = (ball.pos() - player.pos(role)):dir(), acc = speed, flag = 0x00000100,rec = r,vel = v}
-- 				return {mexe, mpos}
-- 		end
-- 	else
-- 		local p = ball.pos()
-- 		local mexe, mpos = GoCmuRush{pos = p, dir = (ball.pos() - player.pos(role)):dir(), acc = a, flag = 0x00000100,rec = r,vel = v}
-- 		return {mexe, mpos}
-- 	end	

-- end
-- end






function ShowTimeV1Pos()
	return ShowTimeV1Pos
end
--思路 ：
--用Infraredcount来判断是否拿到球
-- 若未拿到球：则用GetBallV2拿球
-- 拿到球后： 记录初次拿到球的坐标点，以它为圆心 在一个r为1000的圆内均匀撒点 算出最优点
--朝向问题： 由于硬件缺点， 计算出了最佳点位后可以 以球为中心进行旋转作为转向的函数，球也可有弧度。 也就是可以以弧线前往计算出的点位


function BackXYroleBallGrade(p,role)
	if type(p) == 'function' then
	  	p1 = p()
	else
	  	p1 = p
	end
	local dir_pass = (player.pos(role) - ball.pos()):dir() * 57.3 + 180
	local dir_xy = (p1 - ball.pos()):dir() * 57.3 + 180
	local sub = math.abs(dir_pass - dir_xy)
	local res =  1 - (sub / 225)
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-1000,0),res)
	return res 
end
function ToCircleGrade(Position,Rpos,r)
	local ToCircleDist = (r - (Position - Rpos):mod()) / r
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),ToCircleDist)
	
	return ToCircleDist
end

function ToEnemyCircleGrade(role,Position,Rpos,r)
	local MinNum = -1
	local MinDist = 99999
	for i=1,#enemy_valid do
		if (Rpos - enemy.pos(enemy_valid[i])):mod() < r then
			local Dist = (enemy.pos(enemy_valid[i]) - ball.pos()):mod() 
			if Dist < MinDist then
				MinDist = Dist
				MinNum = i - 1
			end
		end
	end
	-- if MinNum ~= -1 then
		local Position_left = player.pos(role) + Utils.Polar2Vector(1000 - (ball.pos() - enemy.pos(MinNum)):mod(),(enemy.pos(MinNum) - player.pos(role)):dir() + (math.pi / 2))
		local Position_right = player.pos(role) + Utils.Polar2Vector(1000  - (ball.pos() - enemy.pos(MinNum)):mod(),(enemy.pos(MinNum) - player.pos(role)):dir() - (math.pi / 2))
    -- end
end

function ToEnemyDistGrade(role,Position,Rpos,r)
	local MinNum = 0
	local MinDist = 99999
	for i=1,#enemy_valid do
		if (Rpos - enemy.pos(enemy_valid[i])):mod() < r then
			local Dist = (enemy.pos(enemy_valid[i]) - ball.pos()):mod() 
			if Dist < MinDist then
				MinDist = Dist
				MinNum = i - 1
			end
		end
	end
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),1 - (1000 - (Position - enemy.pos(MinNum)):mod()) / 1000)
	return 1 - (1000 - (Position - enemy.pos(MinNum)):mod()) / 1000
end
ShowTimeV2Pos = CGeoPoint:new_local(0,0)
function ShowTimeV2(role,r,density) --鸡肋 带改进
	local angle = 0
	local a = 0
	local r1 = 0
	local position_self = player.pos(role)
	local Position = CGeoPoint:new_local(0,0)
	local grade = 0
	local grade_last = -999999
	local grade_max = -999999
	local maxPosition = CGeoPoint:new_local(0,0)
	local Rpos = StartPos--CGeoPoint:new_local(0,0)
	local gradeBackXYroleBallGrademax = 0
	local gradeToCircleGrademax = 0
	local gradeToEnemyDistGrademax = 0
	for j=1,density do
		r1 = r1 + r / density
		for i = 1,j * 8 do
			Position = CGeoPoint:new_local(position_self:x() + r1 * math.cos(angle),position_self:y() + r1 * math.sin(angle))
			angle = angle + math.pi * i / (j * 4)
			grade = 0.2 * BackXYroleBallGrade(Position,role) + 0.5 * ToCircleGrade(Position,Rpos,1000) + 0.3 * ToEnemyDistGrade(role,Position,Rpos,1000)
			if(grade > grade_last) then
				if(grade > grade_max) then
					maxPosition = Position
					grade_max = grade
					-- gradeBackXYroleBallGrademax = 0.2 * BackXYroleBallGrade(Position,role)
					-- gradeToCircleGrademax =  0.5 *ToCircleGrade(maxPosition,Rpos,1000)
					-- gradeToEnemyDistGrademax =  0.2 *ToEnemyDistGrade(role,Position,Rpos,r)
				end
			end
			grade_last = grade
			debugEngine:gui_debug_x(Position,1)
			debugEngine:gui_debug_arc(Rpos, 1000, 0,360,3)

		end
	end
			debugEngine:gui_debug_x(maxPosition,3)
			-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, 2000),gradeBackXYroleBallGrademax,3)
			-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, 1500),gradeToCircleGrademax,3)
			-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, 1000),gradeToEnemyDistGrademax,3)
			ShowTimeV2Pos = maxPosition

end
function GetShowTimeV2Pos()
	return ShowTimeV2Pos
end

--------------------------------------------------------------------------------------------------------------------
-- email：1670187757@qq.com
--by Umbrella
--2022-07
--最佳可传空位 + 可射门空位 点计算
--GetShootdot()
--GetShootPoint_Debug() 
--GetShootdot_Debug()
---------------------------------------------------------------------------------------------------------------------

count = 0
position = CGeoPoint:new_local(0, 0)
--具体用法
--task.GetGoalPos(task.GetDefenseEnemyNum())
--task.GetShootdot_Debug()
--将这两个函数放到switch内
--最后在需要用到该点的坐标上调用 GetShootdot() 的闭包形式 即可 具体参考 RUN.lua
--GetShootPoint_Debug 与 GetShootdot_Debug 区别
--GetShootPoint_Debug 不考虑队友是否可以传到该点上 而GetShootdot_Debug算出的点既可以被队友传到 也可以射门
function GetShootdot()   
	return position
end

function GetShootPoint_Debug(role) -----------带球新思路  全局找点 然后运过去
	local max_X = 0
	local max_Y = 0
	local grade = 1
	local grade_last = 0
	local GradeMax = 0
	local GradeEnemy = 0
	local GradeBall = 0
	local GradeGoal = 0
	local GradeDir = 0

	for x=-4000,4000,600 do--更改标记#########################################################################################
		for y=-2700,2700,600 do--更改标记#########################################################################################
			grade = grade_enemy(x,y) * 60 + grade_goal(x,y) * 10 + grade_dir_goal(x,y) * 30 + grade_pass_Point(x,y,passer)
			grade = grade / 100
			if(x > 3000 and y < 1500 and y > -1500) then --更改标记#########################################################################################
				grade = 0
			end

			if(x < -3000 and y < 1500 and y > -1500) then --更改标记#########################################################################################
				grade = 0
			end
			if(grade < 0) then 
				grade = 0
			end
			if(grade > 0) then
				--debugEngine:gui_debug_msg(CGeoPoint:new_local(x,y),string.format ("%.2f",grade_dir_goal(x,y)),1)
				debugEngine:gui_debug_x(CGeoPoint:new_local(x, y),1)
			end

			if(grade > grade_last) then
				if(grade > GradeMax) then
					max_X = x
					max_Y = y
					GradeMax = grade
					GradeEnemy = grade_enemy(x,y)
					GradeGoal = grade_goal(x,y)
					GradeDir =  grade_dir_goal(x,y)
				end
			end
			grade_last = grade
		end
	end
	between_dot1(CGeoPoint:new_local(max_X, max_Y),CGeoPoint:new_local(goalPos[1], goalPos[2]))

	debugEngine:gui_debug_x(CGeoPoint:new_local(max_X, max_Y),1)
	debugEngine:gui_debug_arc(CGeoPoint:new_local(max_X, max_Y), 300, 0,360,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, 0),"GradeMax: "..GradeMax,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, -500),"GradeGoal: "..GradeGoal,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, -1000),"GradeEnemy: "..GradeEnemy,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, -1500),"GradeBall: "..GradeBall,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, -2000),"GradeDir: "..GradeDir,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(goalPos[1],goalPos[2]),goalPos[2],1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000,-2500),"X: "..max_X.."   Y: "..max_Y,1)
	count = count + 1
	position = CGeoPoint:new_local(max_X, max_Y)


end
player_valid = {}
enemy_valid = {}
attack_player_valid = {}
attack_enemy_valid = {}
function GetPlayerAndEnemyValid() --获取场上的有效角色     
	local j = 0
	for i=0,param.maxPlayer do
	 	if player.valid(i) then
	 		j = j + 1
	 		player_valid[j] = i
	 	end
	end
	local k = 0
	for z=0,param.maxPlayer do
	 	if enemy.valid(z) then
	 		k = k + 1
	 		enemy_valid[k] = z
	 	end
	end


end

-- function motionLineSafety(role,a)  -- 计算球运动线路上的安全性     
-- 	--CGeoLine:new_local(ball.pos(),ball.velDir())
-- 	--local target_pos = ball_line:projection(player.pos(role))
-- 	local enemyDis = {}
-- 	local enemyToTargetTime = {}
-- 	if (ball.pos() - player.pos(role)):mod() < 200 then
-- 		local ballLineDrbbling = CGeoLine:new_local(ball.pos(),(ball.pos() - player.pos(role)):dir())
-- 		for i=1,#enemy_valid - 1 do
-- 			local p1 = enemy.pos(enemy_valid[i])
-- 			local dir_pass = (ball.pos() - player.pos(role)):dir() * 57.3 + 180
-- 			local dir_xy = (p1 - ball.pos()):dir() * 57.3 + 180
-- 			local sub = math.abs(dir_pass - dir_xy)
-- 			enemyDis[i] = (enemy.pos(enemy_valid[i]) - ballLineDrbbling:projection(enemy.pos(enemy_valid[i]))):mod()
-- 			enemyToTargetTime[i] = sub < 100 and math.sqrt(2 * enemyDis[i] * a) / 1000 or math.sqrt(2 * (enemy.pos(enemy_valid[i]) - ball.pos()):mod() * a) / 1000
-- 		end
-- 	else
-- 		local ballLineMotion = CGeoLine:new_local(ball.pos(),ball.velDir())
-- 		for i=1,#enemy_valid - 1 do
-- 			local p1 = enemy.pos(enemy_valid[i])
-- 			local dir_pass = ball.velDir() * 57.3 + 180
-- 			local dir_xy = (p1 - ball.pos()):dir() * 57.3 + 180
-- 			local sub = math.abs(dir_pass - dir_xy)
-- 			enemyDis[i] = (enemy.pos(enemy_valid[i]) - ballLineMotion:projection(enemy.pos(enemy_valid[i]))):mod()
-- 			enemyToTargetTime[i] = sub < 100 and math.sqrt(2 * enemyDis[i] * a) / 1000 or math.sqrt(2 * (enemy.pos(enemy_valid[i]) - ball.pos()):mod() * a) / 1000
-- 		end
-- 	end
-- 	debugEngine:gui_debug_msg(CGeoPoint:new_local(0,2000),"emenyDis 0:    "..enemyToTargetTime[1])
-- 	debugEngine:gui_debug_msg(CGeoPoint:new_local(0,1500),"emenyDis 1:    "..enemyToTargetTime[2])
-- 	debugEngine:gui_debug_msg(CGeoPoint:new_local(0,1000),"emenyDis 2:    "..enemyToTargetTime[3])
-- 	debugEngine:gui_debug_msg(CGeoPoint:new_local(0,500),"emenyDis 3:    "..enemyToTargetTime[4])
-- 	debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0),"emenyDis 4:    "..enemyToTargetTime[5])
-- 	debugEngine:gui_debug_msg(CGeoPoint:new_local(0,-500),"emenyDis 5:    "..enemyToTargetTime[6])
-- end
f = 0
function motionLineSafety(pos1,pos2)
	local line = CGeoLine:new_local(pos1,(pos1 - pos2):dir())
	local dist = {0,1}
	for i=1,#enemy_valid - 1 do
		local target_pos = line:projection(enemy.pos(enemy_valid[i]))
		dist[i] = (target_pos - pos1):mod() < (pos1 - pos2):mod() and (enemy.pos(enemy_valid[i]) - target_pos):mod() /  ((pos1 - target_pos):mod()) or 1
		dist[i] = (target_pos - pos2):mod() < (pos1 - pos2):mod() and dist[i] or 1
		-- debugEngine:gui_debug_x(line:projection(enemy.pos(enemy_valid[i])),3)
	end
	if f == 0 then
		f = dist[1]
	end
	 -- 0.2589
	-- debugEngine:gui_debug_line(pos1,pos2)
	
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,2000),"dist 1:    "..f)
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,2500),"dist 1:    "..dist[1])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,2000),"dist 2:    "..dist[2])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,1500),"dist 3:    "..dist[3])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,1000),"dist 4:    "..dist[4])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,500),"dist 5:    "..dist[5])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,0),"dist 6:    "..dist[6])
	return math.min(unpack(dist))
end

function motionLineSafetyPass(role)
	local line = CGeoLine:new_local(player.pos(role),(player.pos(role) - ball.pos()):dir())
	local dist = {}
	for i=1,#player_valid - 1 do

		local target_pos = line:projection(player.pos(player_valid[i]))
		-- debugEngine:gui_debug_x(target_pos,3)
		dist[i] = (player.pos(player_valid[i]) - target_pos):mod() / ((target_pos - player.pos(role)):mod() + 0.000001)
		dist[i] = (target_pos - (ball.pos() + Utils.Polar2Vector(100000,(ball.pos() - player.pos(role) ):dir()))):mod() > (player.pos(role) - (ball.pos() + Utils.Polar2Vector(100000,(ball.pos() - player.pos(role) ):dir()))):mod() and 100000 or dist[i]
		dist[i] = dist[i] < 0.0001 and 100000 or dist[i]
		dist[i] = ((player.posX(player_valid[i]) < -3200) and (player.posY(player_valid[i]) > - 1200 and player.posY(player_valid[i]) < 1200)) and 100000 or dist[i]
	end
	 -- 0.2589
	-- debugEngine:gui_debug_line(player.pos(role),player.pos(role) + Utils.Polar2Vector(10000,(ball.pos() - player.pos(role)):dir()),3)

	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,2000),"dist 1:    "..f)
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,2500),"dist 0:    "..dist[1])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,2000),"dist 1:    "..dist[2])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,1500),"dist 2:    "..dist[3])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,1000),"dist 3:    "..dist[4])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,500),"dist 4:    "..dist[5])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,0),"dist 5:    "..dist[6])
	local mindist = math.min(unpack(dist))
	for i=1,#dist do
		if mindist == dist[i] then
			local res = {mindist,i - 1}
			return res
		end
	end
end



function Confidence_pass(role,shootpos) --传球概率计算   差点参数
	 -- 某角色传球 概率  
	 -- 首先 拿 XYroleBallIsLine 的 sub 是一个传球的重要参数， 再考虑安全性 
	 -- 参数： 传球角度、安全度(传过去被截断的可能性) 、射门的角度（越适合射门的角度 越不适合传球）、离球门的距离(越远越不适合射门)
	 -- 否定参数： 球不在自己手上
	local grade_player_pass = {}
	local x = player.posX(role)
	local y = player.posY(role)
	local safety = {}
	for i=1,#player_valid - 1 do
		safety[i] = motionLineSafety(player.pos(role),player.pos(player_valid[i]))
		local grade_safety = safety[i]
		local grade_safety = safety[i] < 0.2589 and (1 - safety[i]) or 0
	   	local p1 = player.pos(player_valid[i])
		local dir_pass = (ball.pos() - player.pos(role)):dir() * 57.3 + 180
		local dir_xy = (p1 - ball.pos()):dir() * 57.3 + 180
		local sub = math.abs(dir_pass - dir_xy)
	    local grade_dir = sub > 300 and 1 - ((360 - sub) / 60) or 1 - (sub / 300)
	    local grade_dir_goal = grade_dir_goal(player.posX(player_valid[i]),player.posY(player_valid[i]))
	    local penalty = between_dotV2(player.pos(role),player.pos(player_valid[i]),130) == 1 and 0 or -999
	    local penalty_shoot = between_dotV2(shootpos,player.pos(player_valid[i]),130) == 1 and 0.2 or 0
		local grade_dis = (9600 - (player.pos(player_valid[i]) - shootpos):mod()) / 9600
		local grade_shoot_mini = between_dotV2(shootpos,player.pos(player_valid[i]),130) == 1 and  (0.5 * grade_dir_goal + 0.5 * grade_dis) or 0
	    grade_player_pass[i] = 0.6 * grade_dir  + 0.4 * grade_shoot_mini + penalty - 0.5 * grade_safety
	    grade_player_pass[i] = grade_player_pass[i] < 0 and 0 or grade_player_pass[i]
	    if (player.pos(role) - player.pos(player_valid[i])):mod() < 1 or (player.posX(player_valid[i]) < -3150 and player.posY(player_valid[i]) < 1250 and player.posY(player_valid[i]) > -1250) then
	    	grade_player_pass[i] = 0
	    end
	end
	-- debugEngine:gui_debug_line(CGeoPoint:new_local(-4927,2800),CGeoPoint:new_local(-800,2800),3)
	-- debugEngine:gui_debug_line(CGeoPoint:new_local(-4927,800),CGeoPoint:new_local(-4927,2800),3)
	-- debugEngine:gui_debug_line(CGeoPoint:new_local(-4927,800),CGeoPoint:new_local(-800,800),3)
	-- debugEngine:gui_debug_line(CGeoPoint:new_local(-800,2800),CGeoPoint:new_local(-800,800),3)
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,2500),"PassConfidencePlayer 0:    "..grade_player_pass[1])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,2200),"PassConfidencePlayer 1:    "..grade_player_pass[2])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,1900),"PassConfidencePlayer 2:    "..grade_player_pass[3])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,1600),"PassConfidencePlayer 3:    "..grade_player_pass[4])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,1300),"PassConfidencePlayer 4:    "..grade_player_pass[5])
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,1000),"PassConfidencePlayer 5:    "..grade_player_pass[6])
	return grade_player_pass
end

function Confidence_shoot(role,shootpos)
	   	local p1 = shootpos
		local dir_pass = (ball.pos() - player.pos(role)):dir() * 57.3 + 180
		local dir_xy = (p1 - ball.pos()):dir() * 57.3 + 180
		local sub = math.abs(dir_pass - dir_xy)
		local grade_dir = sub > 300 and 1 - ((360 - sub) / 60) or 1 - (sub / 60)
		local grade_dis = (9600 - (ball.pos() - shootpos):mod()) / 9600
		local grade_dir_goal = grade_dir_goal(player.posX(role),player.posY(role))
		local penalty = between_dotV2(player.pos(role), shootpos,80) == 0 and -999 or 0
		local grade = 0.05 * grade_dir + 0.40 * grade_dis + 0.55 * grade_dir_goal + penalty
		if grade < 0 then 
			grade = 0
		end
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000,-2500),grade)
		return grade
end




function ConfidenceDrbbling(role,shootpos,threshold)
	--此函数会返回 带球者的三个状态之一  [ 传球 射门 带球 ]  -> []
	local pass = Confidence_pass(role,shootpos)
	local passMax = math.max(unpack(pass))
	local passmaxplayer
	for i=1,#pass do
		if passMax == pass[i] then
			passmaxplayer = i - 1
		end
	end
	if #enemy_valid == 0 then
		return "shoot"
	end
	local shoot = Confidence_shoot(role,shootpos)
	if  (shoot < threshold) and (passMax < threshold) or (NumToName(passmaxplayer) == "Tier" or NumToName(passmaxplayer) == "Receiver" or NumToName(passmaxplayer) == "Goalie") then
		return "dribbling"
	end
	if (shoot < passMax - 0.2) and NumToName(passmaxplayer) ~= "Assister" then
		return "passToPlayer".. NumToName(passmaxplayer)
	else
		return "shoot"
	end
end



-- function Confidence_run(role)
-- end
--[ 传球 射门 带球 ]
--[ 跑位 ]
--[ 防守 抢球 ]


TrueMinNum = 0
TrueMinDist = 0
PlayerStateRUN = {}
PlayerStateGetBall = -1
PlayerStateDefend = -1
PlayerStateDribbling = -1
function NumToName(num)
	local a = {"Leader","Assister","Kicker","Tier","Receiver","Goalie"}
		-- for i=1,#player_valid do
		-- 	for j = 1,6 do 
		-- 		if (player.pos(player_valid[i]) - player.pos(a[j])):mod() < 10 then
		-- 			return a[i]
		-- 		end
		-- 	end
		-- end
		for i=1,6 do
			if (player.pos(a[i]) - player.pos(num)):mod() < 5 then
				return a[i]
			end
		end
		return "Assister"
end

function Confidence_run() 
	--此函数会返回以下状态
	local dist11 = 230
	--Dribbling   RUN{}   GetBall   Defend 
	local dist = {}
	local RunState = {}
	local minDist = 9999999
	local minNum = 0
	local k = 1
	local getballPlayer = -1
	PlayerStateRUN = {}
	PlayerStateGetBall = -1
	PlayerStateDefend = -1
	PlayerStateDribbling = -1
		for i=1,#player_valid do
			dist[i] = player.toBallDist(player_valid[i])
			if minDist >= dist[i] then
				minDist = dist[i]
				minNum = player_valid[i]
			end
		end
		for i=1,#player_valid - 1 do
			if  (player_valid[i] ~= minNum)  and not(player.posX(player_valid[i]) < -3150 and player.posY(player_valid[i]) < 1250 and player.posY(player_valid[i]) > -1250) then
				RunState[k] = player_valid[i]
				k = k + 1
			end
		end
debugEngine:gui_debug_msg(CGeoPoint:new_local(1000,0),minNum)
	if ball.velMod() < 1000 then
		TrueMinNum = minNum
	end
	local getballNum = motionLineSafetyPass(TrueMinNum)
	if minDist < dist11 then
		if #RunState > 1 then 
			-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,200),"Player  "..RunState[1].." RUN",3)
			-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,500),"Player"..RunState[2].." RUN",3)
			PlayerStateRUN = {RunState[1],RunState[2]}
		else
			PlayerStateRUN = {RunState[1]}
			-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,200),"Player  "..RunState[1].." RUN",3)
		end
		PlayerStateDribbling = minNum
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,200),"Player  "..RunState[2].." RUN",3)
	elseif minDist > dist11 and ball.velMod() > 1000 and getballNum[1] < 0.2589 then
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,500),"player"..getballNum[2] .."! G E T B A L L !",3)
		PlayerStateGetBall = getballNum[2]
	else
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,500),"! D E F E N D I N G !",3)
		PlayerStateDefend = 1
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,500),"PassConfidencePlayer  "..RunState[1].." RUN",3)
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,200),"PassConfidencePlayer  "..RunState[2].." RUN",3)
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,-100),"PassConfidencePlayer  "..RunState[3].." GatBall",3)
	end
	k = 1
	-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-4900,-1000),minNum.." RUN",3)
	-- 	return minDist
	-- end
end











function GetShootdot_Down()
	local max_X = 0
	local max_Y = 0
	local grade = 1
	local grade_last = 0
	local GradeMax = 0
	local GradeEnemy = 0
	local GradeBall = 0
	local GradeGoal = 0
	local GradeDir = 0
	for x= 500,4200,500 do--更改标记#########################################################################################
		for y=-2800,0,500 do--更改标记#########################################################################################
			if(x > 2500 and y < 1500 and y > -1500) then --更改标记#########################################################################################
				grade = 0
			else
				if grade_playerV3(x,y,300) == -999 then
					grade = 0
				else
					if grade_pass(x,y) == -99999 then
						grade = 0
					else
						grade = grade_enemy(x,y) * 0.2 + grade_goal(x,y) * 0.35 + grade_ball(x,y) * 0.15 + grade_dir_goal(x,y) * 0.3 
					end
				end
			end
			if(grade < 0) then 
				grade = 0
			end
			if(grade > 0) then
				debugEngine:gui_debug_x(CGeoPoint:new_local(x, y),1)
			end
			if(grade > grade_last) then
				if(grade > GradeMax) then
					max_X = x
					max_Y = y
					GradeMax = grade
					-- GradeBall = grade_ball(x,y)
					-- GradeEnemy = grade_enemy(x,y)
					-- GradeGoal = grade_goal(x,y)
					-- GradeDir =  grade_dir_goal(x,y)
				end
			end
			grade_last = grade
			
		end
	end
	-- between_dot1(CGeoPoint:new_local(max_X, max_Y),CGeoPoint:new_local(goalPos[1], goalPos[2]))
	-- between_dot1(CGeoPoint:new_local(max_X, max_Y),ball.pos())
	debugEngine:gui_debug_arc(CGeoPoint:new_local(max_X, max_Y), 300, 0,360,1)
	position_down = CGeoPoint:new_local(max_X, max_Y)
end

function GetShootdot_Up()
	local max_X = 0
	local max_Y = 0
	local grade = 1
	local grade_last = 0
	local GradeMax = 0
	local GradeEnemy = 0
	local GradeBall = 0
	local GradeGoal = 0
	local GradeDir = 0


	local paramX = 500
	local paramX_from = 4200

	local paramY = 1000
	local paramY_from = 2800
	if ball.posY() > 1000 then
		paramY_from = -1000
		paramY = 1000
	else
		paramY_from = 1000
		paramY = 2800
	end
	for x=500,4200,600 do--更改标记#########################################################################################
		for y=paramY_from,paramY,600 do--更改标记#########################################################################################
			if(x > 2500 and y < 1500 and y > -1500) then --更改标记#########################################################################################
				grade = 0
			else
				if grade_playerV3(x,y,300) == -999 then
					grade = 0
				else
					if grade_pass(x,y) == -99999 then
						grade = 0
					else
						grade = grade_enemy(x,y) * 0.2 + grade_goal(x,y) * 0.35 + grade_ball(x,y) * 0.15 + grade_dir_goal(x,y) * 0.3 
					end
				end
			end
			if(grade > 0) then
				debugEngine:gui_debug_x(CGeoPoint:new_local(x, y),1)
			end

			if(grade > grade_last) then
				if(grade > GradeMax) then
					max_X = x
					max_Y = y
					GradeMax = grade
					GradeBall = grade_ball(x,y)
					GradeEnemy = grade_enemy(x,y)
					GradeGoal = grade_goal(x,y)
					GradeDir =  grade_dir_goal(x,y)
				end
			end
			grade_last = grade
		end
	end
	-- between_dot1(CGeoPoint:new_local(max_X, max_Y),CGeoPoint:new_local(goalPos[1], goalPos[2]))
	-- between_dot1(CGeoPoint:new_local(max_X, max_Y),ball.pos())
	-- count = count + 1
	debugEngine:gui_debug_arc(CGeoPoint:new_local(max_X, max_Y), 300, 0,360,1)
	position_up = CGeoPoint:new_local(max_X, max_Y)
end

function GetShootdot_Debug()
	local max_X = 0
	local max_Y = 0
	local grade = 1
	local grade_last = 0
	local GradeMax = 0
	local GradeEnemy = 0
	local GradeBall = 0
	local GradeGoal = 0
	local GradeDir = 0
	for x=-1000,4200,300 do--更改标记#########################################################################################
		for y=-2700,2700,300 do--更改标记#########################################################################################
			grade = grade_enemy(x,y) * 0.2 + grade_goal(x,y) * 0.35 + grade_ball(x,y) * 0.15 + grade_dir_goal(x,y) * 0.3 + grade_pass(x,y,passer)
			if(x > 2500 and y < 1500 and y > -1500) then --更改标记#########################################################################################
				grade = 0
			end
			if(grade < 0) then 
				grade = 0
			end
			if(grade > 0) then
				debugEngine:gui_debug_x(CGeoPoint:new_local(x, y),1)
			end

			if(grade > grade_last) then
				if(grade > GradeMax) then
					max_X = x
					max_Y = y
					GradeMax = grade
					GradeBall = grade_ball(x,y)
					GradeEnemy = grade_enemy(x,y)
					GradeGoal = grade_goal(x,y)
					GradeDir =  grade_dir_goal(x,y)
				end
			end
			grade_last = grade
		end
	end
	between_dot1(CGeoPoint:new_local(max_X, max_Y),CGeoPoint:new_local(goalPos[1], goalPos[2]))
	between_dot1(CGeoPoint:new_local(max_X, max_Y),ball.pos())
	count = count + 1
	position = CGeoPoint:new_local(max_X, max_Y)
end
----------------------------------------------------------------------------------------------------------
count = 0
-- enemy_num = {

-- }
-- function GetEnemyNumAll()
-- 	local j = 0
-- 	for i = 0,param.maxPlayer do
-- 		if enemy.valid(i) then
-- 			j = j + 1
-- 			enemy_num[j] = i
-- 		end
-- 	end
-- 	return table.getn(enemy_num) - 1
-- end

position_down = CGeoPoint:new_local(0, 0)
function GetShootdot_down()
	return position_down
end
function GetShootPoint_Debug_down(role)
	local max_X = 0
	local max_Y = 0
	local grade = 1
	local grade_last = 0
	local GradeMax = 0
	local GradeEnemy = 0
	local Gradepassline = 0
	local Grade_Gaussian_dis_ball = 0
	for x=0,2500,250 do--更改标记#########################################################################################
		for y=-1700,1700,250 do--更改标记#########################################################################################
			grade = grade_enemy(x,y) * 0.1 + grade_pass_line(x,y,role) * 0.4 + grade_Gaussian_dis_ball(x,y) * 0.5 + grade_pass_ShowTime(x,y) 
			if(x > 2500 and y < 500 and y > -500) then --更改标记#########################################################################################
				grade = 0
			end
			if(grade < 0) then 
				grade = 0
			end
			if(grade > 0) then
				--debugEngine:gui_debug_msg(CGeoPoint:new_local(x,y),string.format ("%.2f",grade_dir_goal(x,y)),1)
				debugEngine:gui_debug_x(CGeoPoint:new_local(x, y),3)
			end

			if(grade > grade_last) then
				if(grade > GradeMax) then
					max_X = x
					max_Y = y
					GradeMax = grade
					GradeEnemy = grade_enemy(x,y) * 0.2
					Gradepassline = grade_pass_line(x,y,role) * 0.8
					Grade_Gaussian_dis_ball = grade_Gaussian_dis_ball(x,y) * 0.2
				end
			end
			grade_last = grade
		end
	end
	--between_dot1(CGeoPoint:new_local(max_X, max_Y),ball.pos())
	debugEngine:gui_debug_x(CGeoPoint:new_local(max_X, max_Y),1)
	debugEngine:gui_debug_arc(CGeoPoint:new_local(max_X, max_Y), 300, 0,360,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(2000, 0),"GradeMax: "..GradeMax,3)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(2000, -500),"Gradepassline: "..Gradepassline,3)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(2000, -1000),"GradeEnemy: "..GradeEnemy,3)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(2000, -1500),"Gradegaussiandisball: "..Grade_Gaussian_dis_ball,3)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(2000,-2500),"X: "..max_X.."   Y: "..max_Y,3)
	count = count + 1
	position_down = CGeoPoint:new_local(max_X, max_Y)
end

position_up = CGeoPoint:new_local(0, 0)
function GetShootdot_up()
	return position_up
end
function GetShootPoint_Debug_up(role)
	local max_X = 0
	local max_Y = 0
	local grade = 1
	local grade_last = 0
	local GradeMax = 0
	local GradeEnemy = 0
	local Gradepassline = 0
	local Grade_Gaussian_dis_ball = 0

	local paramX = -2500
	local paramX_from = 0

	local paramY = -1700
	local paramY_from = 1700
	if ball.posY() > 1000 then
		paramY = 1000
		paramY_from = -1000
	end
	for x=paramX,paramX_from,250 do--更改标记#########################################################################################
		for y=paramY,paramY_from,250 do--更改标记#########################################################################################
			grade = grade_enemy(x,y) * 0.1 + grade_pass_line(x,y,role) * 0.4 + grade_Gaussian_dis_ball(x,y) * 0.5 + grade_pass_ShowTime(x,y) 
			if(x < -2500 and y < 500 and y > -500) then --更改标记#########################################################################################
				grade = 0
			end
			if(grade < 0) then 
				grade = 0
			end
			if(grade > 0) then
				--debugEngine:gui_debug_msg(CGeoPoint:new_local(x,y),string.format ("%.2f",grade_dir_goal(x,y)),1)
				debugEngine:gui_debug_x(CGeoPoint:new_local(x, y),1)
			end

			if(grade > grade_last) then
				if(grade > GradeMax) then
					max_X = x
					max_Y = y
					GradeMax = grade
					GradeEnemy = grade_enemy(x,y) * 0.2
					Gradepassline = grade_pass_line(x,y,role) * 0.8
					Grade_Gaussian_dis_ball = grade_Gaussian_dis_ball(x,y) * 0.2
				end
			end
			grade_last = grade
		end
	end
	--between_dot1(CGeoPoint:new_local(max_X, max_Y),ball.pos())
	debugEngine:gui_debug_x(CGeoPoint:new_local(max_X, max_Y),1)
	debugEngine:gui_debug_arc(CGeoPoint:new_local(max_X, max_Y), 300, 0,360,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, 0),"GradeMax: "..GradeMax,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, -500),"Gradepassline: "..Gradepassline,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, -1000),"GradeEnemy: "..GradeEnemy,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000, -1500),"Gradegaussiandisball: "..Grade_Gaussian_dis_ball,1)
	debugEngine:gui_debug_msg(CGeoPoint:new_local(-4000,-2500),"X: "..max_X.."   Y: "..max_Y,1)
	count = count + 1
	position_up = CGeoPoint:new_local(max_X, max_Y)
end




--between_dot 检测dot1 与 dot2 间是否有敌人存在 根改enemy_R可以增加宽度
--between_dot1 是debug版 会将运算过程显示出来
local robot_R = 1
local enemy_R = 50--更改标记#########################################################################################
function between_dotV2(dot1, dot2,r)
	if type(dot1) == 'function' then
		p1 = dot1()
	else
		p1 = dot1
	end
	if type(dot2) == 'function' then
		p2 = dot2()
	else
		p2 = dot2
	end
	local seg = CGeoSegment:new_local(p1, p2)
	for i = 1, param.maxPlayer do
		if enemy.valid(i) then
			local dist = seg:projection(enemy.pos(i)):dist(enemy.pos(i))
			local isprjon = seg:IsPointOnLineOnSegment(seg:projection(enemy.pos(i)))
			if dist < r and isprjon then
				return 0
			end
		end
	end
	return 1
end


function between_dot(dot1,dot2)
    local ipos1 = dot1
  	if type(dot1) == 'function' then
  		ipos1 = dot1()
  	else
  		ipos1 = dot1
  	end
    local ipos2 = dot2
  	if type(dot2) == 'function' then
  		ipos2 = dot2()
  	else
  		ipos2 = dot2
  	end

	local enemypos = {
		enemy.pos(0),
		enemy.pos(1),
		enemy.pos(2),
		enemy.pos(3),
		enemy.pos(4),
		enemy.pos(5),

	}
	if(math.abs(ipos1:x() - ipos2:x()) >= 300) then
	  	if(ipos1:x() > ipos2:x()) then
  			if type(dot1) == 'function' then
  				ipos2 = dot1()
  			else
  				ipos2 = dot1
 	 		end
 	 		if type(dot2) == 'function' then
 	 			ipos1 = dot2()
	 	 	else
 	 			ipos1 = dot2
 	 		end
  		end
		for x = ipos1:x() , ipos2:x() , robot_R do
			y = ((x - ipos1:x()) * (ipos2:y() - ipos1:y())) / (ipos2:x() - ipos1:x()) + ipos1:y()
			robot_R = 50
			for i = 1,6 do
				if(enemypos[i]:x() > x - enemy_R and enemypos[i]:x() < x + enemy_R and enemypos[i]:y() > y - enemy_R and enemypos[i]:y() < y + enemy_R) then
					return 0
			else
				flag = 1
			end
			end
		end
	else
	  	if(ipos1:y() > ipos2:y()) then
  			if type(dot1) == 'function' then
  				ipos2 = dot1()
  			else
  				ipos2 = dot1
 	 		end
 	 		if type(dot2) == 'function' then
 	 			ipos1 = dot2()
	 	 	else
 	 			ipos1 = dot2
 	 		end
  		end
		for y = ipos1:y() , ipos2:y() , robot_R do
			x = (y - ipos1:y()) / (ipos2:y() - ipos1:y()) * (ipos2:x() - ipos1:x()) + ipos1:x()
			robot_R = 50
			for i = 1,6 do
				if(enemypos[i]:x() > x - enemy_R and enemypos[i]:x() < x + enemy_R and enemypos[i]:y() > y - enemy_R and enemypos[i]:y() < y + enemy_R) then
					return 0
			else
				flag = 1
			end
			end
		end
	end
	return 1
end




function between_dot1(dot1,dot2)
    local ipos1 = dot1
  	if type(dot1) == 'function' then
  		ipos1 = dot1()
  	else
  		ipos1 = dot1
  	end
    local ipos2 = dot2
  	if type(dot2) == 'function' then
  		ipos2 = dot2()
  	else
  		ipos2 = dot2
  	end

	local enemypos = {
		enemy.pos(0),
		enemy.pos(1),
		enemy.pos(2),
		enemy.pos(3),
		enemy.pos(4),
		enemy.pos(5),

	}
	if(math.abs(ipos1:x() - ipos2:x()) >= 300) then
	  	if(ipos1:x() > ipos2:x()) then
  			if type(dot1) == 'function' then
  				ipos2 = dot1()
  			else
  				ipos2 = dot1
 	 		end
 	 		if type(dot2) == 'function' then
 	 			ipos1 = dot2()
	 	 	else
 	 			ipos1 = dot2
 	 		end
  		end
		for x = ipos1:x() , ipos2:x() , robot_R do
			y = ((x - ipos1:x()) * (ipos2:y() - ipos1:y())) / (ipos2:x() - ipos1:x()) + ipos1:y()
			robot_R = 50
			debugEngine:gui_debug_x(CGeoPoint:new_local(x, y),3)
			--debugEngine:gui_debug_msg(CGeoPoint:new_local(0, 0),"X遍历",3)
			for i = 1,6 do
				if(enemypos[i]:x() > x - enemy_R and enemypos[i]:x() < x + enemy_R and enemypos[i]:y() > y - enemy_R and enemypos[i]:y() < y + enemy_R) then
					debugEngine:gui_debug_msg(CGeoPoint:new_local(0, -500),"有人",3)
					return 0
				else
					flag = 1
				end
			end
		end
	else
	  	if(ipos1:y() > ipos2:y()) then
  			if type(dot1) == 'function' then
  				ipos2 = dot1()
  			else
  				ipos2 = dot1
 	 		end
 	 		if type(dot2) == 'function' then
 	 			ipos1 = dot2()
	 	 	else
 	 			ipos1 = dot2
 	 		end
  		end
		for y = ipos1:y() , ipos2:y() , robot_R do
			x = (y - ipos1:y()) / (ipos2:y() - ipos1:y()) * (ipos2:x() - ipos1:x()) + ipos1:x()
			robot_R = 50
			debugEngine:gui_debug_x(CGeoPoint:new_local(x, y),3)
			debugEngine:gui_debug_msg(CGeoPoint:new_local(0, 0),"Y遍历",3)
			for i = 1,6 do
				if(enemypos[i]:x() > x - enemy_R and enemypos[i]:x() < x + enemy_R and enemypos[i]:y() > y - enemy_R and enemypos[i]:y() < y + enemy_R) then
					--debugEngine:gui_debug_msg(CGeoPoint:new_local(0, -500),"有人",3)
					return 0
			else
				flag = 1
			end
			end
		end

	end
	--debugEngine:gui_debug_msg(CGeoPoint:new_local(0, -500),"无人",3)
	return 1
end



function waitForBall(p, d, a, f, r, v) --p点候球，by keke 2022-6-12 
	local idir
	-- if d ~= nil then
	-- 	idir = d
	-- else
	-- 	idir = dir.shoot()
	-- end
	local idir = function(runner)
		return (ball.pos()-player.pos(runner)):dir()
	end

	local mexe, mpos = GoCmuRush{pos = p, dir = idir, acc = a, flag = f,rec = r,vel = v}
	return {mexe, mpos}
end

function goalie()
	local mexe, mpos = Goalie()
	return {mexe, mpos}
end
function touch()
	local ipos = pos.ourGoal()
	local mexe, mpos = Touch{pos = ipos}
	return {mexe, mpos}
end

-- function touchKick(p,ifInter)
-- 	local ipos = p or pos.theirGoal()
-- 	local idir = function(runner)
-- 		return (ipos - player.pos(runner)):dir()
-- 	end
-- 	local mexe, mpos = Touch{pos = ipos, useInter = ifInter}
-- 	return {mexe, mpos, kick.flat, idir, pre.low, cp.full, cp.full, flag.nothing}
-- end

function getball(dist,to_p, a, f, r, v) --to_p为要传向的点 keke 2022-06-11
    local idir
	if to_p == nil then
		idir = dir.shoot()
	end

    local p = function()
		local goalPos = to_p
	  		if type(to_p) == 'function' then
	  			goalPos = to_p()
	  		else
	  			goalPos = to_p
	  		end
	  		local centerX = goalPos:x()
	  		local centerY = goalPos:y()
		goalPos = CGeoPoint:new_local(centerX,centerY)
		return  ball.pos() + Utils.Polar2Vector(dist,(ball.pos() - goalPos):dir())
	end
	local idir = function ()
			local goalPos = to_p
	  		if type(to_p) == 'function' then
	  			goalPos = to_p()
	  		else
	  			goalPos = to_p
	  		end
		return (goalPos - ball.pos()):dir()
	end
	local mexe, mpos = GoCmuRush{pos = p, dir = idir, acc = a, flag = f,rec = r,vel = v}
	return {mexe, mpos}

end 

local Toward = function(num)
	return function ()
		return (ball.pos() - player.pos(num)):dir()
	end
end





function goSpeciPos(p, d, f, a) -- 2014-03-26 增加a(加速度参数)
	local idir
	local iflag
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end

	if f ~= nil then
		iflag = f
	else
		iflag = 0
	end

	local mexe, mpos = SmartGoto{pos = p, dir = idir, flag = iflag, acc = a}
	return {mexe, mpos}
end

function goSimplePos(p, d, f)
	local idir
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end

	if f ~= nil then
		iflag = f
	else
		iflag = 0
	end

	local mexe, mpos = SimpleGoto{pos = p, dir = idir, flag = iflag}
	return {mexe, mpos}
end

function runMultiPos(p, c, d, idir, a)
	if c == nil then
		c = false
	end

	if d == nil then
		d = 20
	end

	if idir == nil then
		idir = dir.shoot()
	end

	local mexe, mpos = RunMultiPos{ pos = p, close = c, dir = idir, flag = flag.not_avoid_our_vehicle, dist = d, acc = a}
	return {mexe, mpos}
end

--~ p为要走的点,d默认为射门朝向
function goCmuRush(p, d, a, f, r, v)
	local idir
	if d ~= nil then
		idir = d
	else
		idir = dir.shoot()
	end
	local mexe, mpos = GoCmuRush{pos = p, dir = idir, acc = a, flag = f,rec = r,vel = v}
	return {mexe, mpos}
end

function forcekick(p,d,chip,power)
	local ikick = chip and kick.chip or kick.flat
	local ipower = power and power or 8000
	local idir = d and d or dir.shoot()
	local mexe, mpos = GoCmuRush{pos = p, dir = idir, acc = a, flag = f,rec = r,vel = v}
	return {mexe, mpos, ikick, idir, pre.low, kp.specified(ipower), cp.full, flag.forcekick}
end

function shoot(p,d,chip,power)
	local ikick = chip and kick.chip or kick.flat
	local ipower = power and power or 8000
	local idir = d and d or dir.shoot()
	local mexe, mpos = GoCmuRush{pos = p, dir = idir, acc = 3500, flag = f,rec = r,vel = v}
	return {mexe, mpos, kick.flat, idir, pre.lowist, kp.specified(ipower), cp.full, flag.nothing}
end
------------------------------------ 防守相关的skill ---------------------------------------
-- TODO
----------------------------------------- 其他动作 --------------------------------------------

-- p为朝向，如果p传的是pos的话，不需要根据ball.antiY()进行反算
function goBackBall(p, d)
	local mexe, mpos = GoCmuRush{ pos = ball.backPos(p, d, 0), dir = ball.backDir(p), flag = flag.dodge_ball}
	return {mexe, mpos}
end

-- 带避车和避球
function goBackBallV2(p, d)
	local mexe, mpos = GoCmuRush{ pos = ball.backPos(p, d, 0), dir = ball.backDir(p), flag = bit:_or(flag.allow_dss,flag.dodge_ball)}
	return {mexe, mpos}
end

function stop()
	local mexe, mpos = Stop{}
	return {mexe, mpos}
end

function continue()
	return {["name"] = "continue"}
end

------------------------------------ 测试相关的skill ---------------------------------------

function openSpeed(vx, vy, vdir)
	local spdX = function()
		return vx
	end

	local spdY = function()
		return vy
	end
	
	local spdW = function()
		return vdir
	end

	local mexe, mpos = OpenSpeed{speedX = spdX, speedY = spdY, speedW = spdW}
	return {mexe, mpos}
end

function speed(vx, vy, vdir)
	local spdX = function()
		return vx
	end

	local spdY = function()
		return vy
	end
	
	local spdW = function()
		return vdir
	end

	local mexe, mpos = Speed{speedX = spdX, speedY = spdY, speedW = spdW}
	return {mexe, mpos}
end

------------------------------------ 2022年防守代码 by keke ---------------------------------------
function ballPlacement(p,d)
    if p ~= nil then
  		if type(p) == 'function' then
	  			ipos = p()
	  	else
	  			ipos = p
	  	end
    end

   if d ~= nil then
  		if type(d) == 'function' then
	  			Ki = d()
	  	else
	  			Ki = d
	  	end
	end

	local mexe, mpos = theirPlacement{pos = ipos, K = Ki}
	return {mexe, mpos}
end
---defening 用于专职后卫
function defending(p,d) 
    if p ~= nil then
  		if type(p) == 'function' then
	  			ipos = p()
	  	else
	  			ipos = p
	  	end
    end

   if d ~= nil then
  		if type(d) == 'function' then
	  			Ki = d()
	  	else
	  			Ki = d
	  	end
	end

	local mexe, mpos = defendingGoalie{pos = ipos, K = Ki}
	return {mexe, mpos}
end

---盯人防守

function defendingOpp(p, d, a, f, r, v)
	local idir
	if d ~= nil then
		opp_name = d
	else
		opp_name = 2
	end
	local mexe, mpos = GoCmuRushA{pos = p, oppRole = opp_name, acc = a, flag = f,rec = r,vel = v}
	return {mexe, mpos}
end
