function Getball(task)
	local minter_flag = task.inter_flag or 1
	local mpermissions = task.permissions or 0
	local mshootPos = task.shootPos or CGeoPoint(-param.INF,-param.INF)
	local mpos
	local mdir
	local msender = task.sender or 0
	local mrole   = task.srole or ""
	local macc    = task.acc or 0
	local mrec    = task.rec or 0 --mrec判断是否吸球  gty 2016-6-15
	local mvel
	local mspeed  = task.speed or 0
	local mforce_maunal_set_running_param = task.force_manual or false

	matchPos = function(runner)
		local qflag = inter_flag or 0
		local playerPos = CGeoPoint:new_local(player.pos(runner):x(),player.pos(runner):y())
		local inter_pos = Utils.GetBestInterPos(vision,playerPos,param.playerVel,minter_flag,0,param.V_DECAY_RATE,param.distRate)
		debugEngine:gui_debug_msg(CGeoPoint(0,0),minter_flag)
		local ballLine = CGeoSegment(ball.pos(),ball.pos() + Utils.Polar2Vector(-param.INF,ball.velDir()))
		local playerPrj = ballLine:projection(player.pos(runner))
		local canGetBall = ballLine:IsPointOnLineOnSegment(playerPrj)
		local toballdist = player.toBallDist(runner) 
		
		-- --  敌方球权的情况
		-- if GlobalMessage.Tick().ball.rights == -1 or GlobalMessage.Tick().ball.rights == 2 then
		-- 	local theirDribblingPlayerPos = enemy.pos(GlobalMessage.Tick().their.dribbling_num)
		-- 	inter_pos = ball.pos() + Utils.Polar2Vector(80,(ball.pos() - theirDribblingPlayerPos):dir())
		-- end
		-- -- 接球的情况
		-- if ((player.pos(runner) - mshootPos):mod() < 800 and canGetBall ) then
		-- 	inter_pos = mshootPos
		-- end
		-- -- 踢了一脚
		-- if(player.kickBall(runner) or( GlobalMessage.Tick().ball.rights == 0 and not canGetBall and player.myinfraredOffCount(runner)  < 20) and ball.velMod() > 1500)then
		-- 	inter_pos = CGeoPoint(-99999,-99999)
		-- end
		-- if(player.myinfraredOffCount(runner)  > 1) then
		-- 	inter_pos = CGeoPoint(ball.posX(),ball.posY())
		-- end
		
		
		
		debugEngine:gui_debug_x(inter_pos,9)
		debugEngine:gui_debug_msg(inter_pos,runner .. "getBallPos",9)
		return _c(inter_pos)
	end

	execute = function(runner)
		local debugError = "GetballPos"
		if runner >=0 and runner < param.maxPlayer then
			if mrole ~= "" then
				CRegisterRole(runner, mrole)
			end
		else
			print("Error runner in getball", runner)
		end
		local playerEndVel = {
			-- [num] = {endVel, ballVelRate} 
			[-1] = {0,1}, -- Other
			[0] = {0,1},
			[1] = {0,1},
			[2] = {0,1},
			[3] = {0,1}, -- 吸球强
			[4] = {0,1},	
			[5] = {0,1},
			[6] = {0,1},
			[7] = {0,1},
			[8] = {0,1},
			[9] = {0,1},
			[10] = {0,1},
			[11] = {0,1},
			[12] = {0,1},
			[13] = {0,1},
			[14] = {0,1},
			[15] = {0,1},
			[16] = {0,1}, -- Other
		}
		--获取常用数据
		local playerPos = CGeoPoint:new_local(player.pos(runner):x(),player.pos(runner):y()) 
		local mouthPos = playerPos + Utils.Polar2Vector(param.playerFrontToCenter-50,player.dir(runner))
		debugEngine:gui_debug_x(mouthPos,4)
		local inter_pos = Utils.GetBestInterPos(vision,playerPos,param.playerVel,minter_flag,0,param.V_DECAY_RATE,param.distRate)
		local idir = player.toBallDir(runner)
		local ballLine = CGeoSegment(ball.pos(),ball.pos() + Utils.Polar2Vector(9999,ball.velDir()))
		local prjPos = ballLine:projection(mouthPos)
		local isOnBallLine = ballLine:IsPointOnLineOnSegment(prjPos)
		local toballDir = math.abs((ball.pos() - player.rawPos(runner)):dir())
		local playerDir = math.abs(player.dir(runner))
		local Subdir = math.abs(Utils.angleDiff(toballDir,playerDir) * 180/math.pi)
		local iflag = flag.dribbling + flag.allow_dss
		local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
		local iacc
		local endVel = Utils.Polar2Vector(0,idir)
		-- 特殊情况 一：当拿球的角度不对的时候调整角度
		if Subdir > 15 and player.toBallDist(runner) < 250 then 
			iflag =  DSS_FLAG
			debugError = debugError .. "  DSS_FLAG "
		else
			iflag = flag.dribbling + flag.allow_dss
			debugError = debugError .. "  DRIBLE_FLAG "
		end

		-- 球迎面向我的情况   接球
		if (isOnBallLine) and ball.velMod() > 200 then
			-- if GlobalMessage.Tick().ball.pos_move_befor then
			if GlobalMessage.Tick().ball.pos_move_befor:dist(player.pos(runner)) < 2000 then
				endVel = Utils.Polar2Vector(0 ,idir)
			end
			idir = (ball.pos() - inter_pos):dir()
			debugError = debugError .. "  InterceptBall "

		elseif (ball.velMod() > 200 and not isOnBallLine) then
			idir = (ball.pos() - inter_pos):dir()
			iflag = flag.dodge_ball + flag.dribbling
			debugError = debugError ..  "  RushToInterceptBall "
		end
		
		if (not isOnBallLine and (prjPos:dist(player.pos(runner)) < 150 or ball.velMod() < 1000) or ball.velMod() < 200 ) then
			idir = player.toBallDir(runner)
			inter_pos = ball.pos() + Utils.Polar2Vector(-10,idir)
			if Subdir > 15 and player.toBallDist(runner) < 250 then 
				iflag =  DSS_FLAG
				debugError = debugError .. "  DSS_FLAG "
			else
				iflag = flag.dribbling + flag.allow_dss
				debugError = debugError .. "  DRIBLE_FLAG "
			end
			debugError = debugError .."  RushToBall "
			endVel = Utils.Polar2Vector((ball.velMod() * playerEndVel[runner][2]) + playerEndVel[runner][1],idir)
		end

		-- --  除去抖动
		-- if (inter_pos - param.lastInterPos):mod() < 10 then
		-- 	inter_pos = param.lastInterPos
		-- end 
		-- 在禁区的时候
		if inter_pos:x() == param.INF then
			inter_pos = player.pos(runner)
			idir = player.toBallDir(runner)
			debugError = debugError .. "  INF "
		end

		-- 解决敌人过近的问题
		if GlobalMessage.Tick().ball.rights == -1 or GlobalMessage.Tick().ball.rights == 2 then
			local minEnemyDistNum = {}
			for i = 0 ,param.maxPlayer -1 do 
				if enemy.valid(i) then
					if enemy.pos(i):dist(ball.pos()) < 300 then
						-- print(i)
						table.insert(minEnemyDistNum,i)
					end
					if #minEnemyDistNum == 2 then
						break
					end
				end
			end
			if (#minEnemyDistNum == 2) then
				local dist_ = param.playerFrontToCenter + 20

				
				local theirDribblingPlayerPos = enemy.pos(GlobalMessage.Tick().their.dribbling_num)
				local middlePos = enemy.pos(minEnemyDistNum[1]):midPoint(enemy.pos(minEnemyDistNum[2]))

				theirDribblingPlayerPos = middlePos
				if player.pos(runner):dist(ball.pos() + Utils.Polar2Vector(param.playerFrontToCenter + 80,(ball.pos() - theirDribblingPlayerPos):dir())) < 50 then
					dist_ = param.playerFrontToCenter

				end
				inter_pos = ball.pos() + Utils.Polar2Vector(dist_,(ball.pos() - theirDribblingPlayerPos):dir())

				debugEngine:gui_debug_msg(inter_pos,"middlePos",9)
				debugEngine:gui_debug_x(inter_pos,9)
				debugError = debugError ..  "  TwoEnemy "

			elseif (#minEnemyDistNum == 1) then
				local dist_ = param.playerFrontToCenter + 80

				local theirDribblingPlayerPos = enemy.pos(GlobalMessage.Tick().their.dribbling_num)
				if player.pos(runner):dist(ball.pos() + Utils.Polar2Vector(param.playerFrontToCenter + 80,(ball.pos() - theirDribblingPlayerPos):dir())) < 50 then
					dist_ = param.playerFrontToCenter
				end
				inter_pos = ball.pos() + Utils.Polar2Vector(dist_,(ball.pos() - theirDribblingPlayerPos):dir())
				debugError = debugError ..   "  OneEnemy "
			end
		end



		param.lastInterPos = inter_pos
		mvel = _c(endVel) or CVector:new_local(0,0)
		mpos = _c(inter_pos,runner)
		mdir = _c(idir,runner)
		macc = iacc or 0
		mspeed = _c(task.speed) or 0
		if type(task.sender) == "string" then
			msender = player.num(task.sender)
		end
		debugError = mdir == player.toBallDir(runner) and debugError.."  ToBallDir " or debugError.. "  ToInterPosDir "
		debugEngine:gui_debug_x(inter_pos,4)
		debugEngine:gui_debug_msg(inter_pos,debugError,4,0,80)
		task_param = TaskT:new_local()
		task_param.executor = runner
		task_param.player.pos = CGeoPoint(mpos)
		task_param.player.angle = mdir
		task_param.ball.Sender = msender or 0
		task_param.player.max_acceleration = macc or 0
		task_param.player.vel = CVector(mvel)
		task_param.player.force_manual_set_running_param = mforce_maunal_set_running_param
		task_param.player.flag = iflag
		return skillapi:run("SmartGoto", task_param)
	end

	return execute, matchPos
end

gSkillTable.CreateSkill{
	name = "Getball",
	execute = function (self)
		print("This is in skill"..self.name)
	end
}
