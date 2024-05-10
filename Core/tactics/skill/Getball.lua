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
			local inter_pos = Utils.GetBestInterPos(vision,playerPos,param.playerVel,minter_flag,0,param.V_DECAY_RATE)
			debugEngine:gui_debug_msg(CGeoPoint(0,0),minter_flag)
			local ballLine = CGeoSegment(ball.pos(),ball.pos() + Utils.Polar2Vector(-param.INF,ball.velDir()))
			local playerPrj = ballLine:projection(player.pos(runner))
			local canGetBall = ballLine:IsPointOnLineOnSegment(playerPrj)
			local toballdist = player.toBallDist(runner) 
			if player.kickBall(runner) and inter_pos:x() == ball.pos():x() then
				inter_pos = CGeoPoint(-99999,-99999)
			end
		--  特殊情况 敌方球权的时候
		if GlobalMessage.Tick.ball.rights == -1 or GlobalMessage.Tick.ball.rights == 2 then
			local theirDribblingPlayerPos = enemy.pos(GlobalMessage.Tick.their.dribbling_num)
			inter_pos = ball.pos() + Utils.Polar2Vector(80,(ball.pos() - theirDribblingPlayerPos):dir())
		end

			if ((player.pos(runner) - mshootPos):mod() < 800) then
				inter_pos = mshootPos
			end
			if(GlobalMessage.Tick.ball.rights == 0 and ball.velMod() < 500 and ball.pos() - player.pos(runner)) then
				inter_pos = ball.pos()
			end
			-- debugEngine:gui_debug_x(inter_pos,3)
			-- debugEngine:gui_debug_msg(inter_pos,runner .. "getBallPos",3)

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

		--获取常用数据
		local playerPos = CGeoPoint:new_local(player.pos(runner):x(),player.pos(runner):y())
		local inter_pos = Utils.GetBestInterPos(vision,playerPos,param.playerVel,minter_flag,0,param.V_DECAY_RATE)
		local idir = player.toBallDir(runner)
		local ballLine = CGeoSegment(ball.pos(),ball.pos() + Utils.Polar2Vector(9999,ball.velDir()))
		local prjPos = ballLine:projection(player.pos(runner))
		local toballDir = math.abs((ball.pos() - player.rawPos(runner)):dir() * 57.3)
		local playerDir = math.abs(player.dir(runner)) * 57.3
		local Subdir = math.abs(toballDir-playerDir)
		local iflag = flag.dribbling + flag.allow_dss
		local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
		local iacc
		-- 特殊情况 一：当拿球的角度不对的时候调整角度
		if Subdir > 15 and player.toBallDist(runner) < 150 then 
			iflag =  DSS_FLAG
		else
			iflag = flag.dribbling + flag.allow_dss
		end

		-- 球速过慢 去追球的时候
		

		if (ballLine:IsPointOnLineOnSegment(prjPos)) and ball.velMod() > 200 then
			idir = (ball.pos() - inter_pos):dir()
			debugError = "GetballPos Special: InterceptBall"
		elseif (ball.velMod() < 800 and ball.velMod() > 200 and not ballLine:IsPointOnLineOnSegment(prjPos)) then
			idir = player.toBallDir(runner)
			inter_pos = ball.pos() + Utils.Polar2Vector(-10,idir)
			endVel = Utils.Polar2Vector(ball.velMod() + 100,idir)

			debugError = "GetballPos Special: RushToBall"
		elseif (ball.velMod() > 1200 and not ballLine:IsPointOnLineOnSegment(prjPos)) then
			idir = (ball.pos() - inter_pos):dir()
			iflag =  flag.dodge_ball
			debugError = "GetballPos Special: RushToInterceptBall"
		elseif ball.velMod() < 200 then
			idir = player.toBallDir(runner)
			inter_pos = ball.pos() + Utils.Polar2Vector(-param.playerFrontToCenter + 15,idir)
			debugError = "GetballPos Special: GoBallPos"
			endvel = Utils.Polar2Vector(400,(inter_pos - player.pos(runner)):dir())

		end
		
		--  除去抖动
		if (inter_pos - param.lastInterPos):mod() < 10 then
			inter_pos = param.lastInterPos
		end 
		-- 在禁区的时候
		if inter_pos:x() == param.INF then
			inter_pos = player.pos(runner)
			idir = player.toBallDir(runner)
			debugError = "GetballPos Special: inter_pos is INF"
		end

		-- 解决敌人过近的问题
		if GlobalMessage.Tick.ball.rights == -1 or GlobalMessage.Tick.ball.rights == 2 then
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

				
				local theirDribblingPlayerPos = enemy.pos(GlobalMessage.Tick.their.dribbling_num)
				local middlePos = enemy.pos(minEnemyDistNum[1]):midPoint(enemy.pos(minEnemyDistNum[2]))

				theirDribblingPlayerPos = middlePos
				if player.pos(runner):dist(ball.pos() + Utils.Polar2Vector(param.playerFrontToCenter + 80,(ball.pos() - theirDribblingPlayerPos):dir())) < 50 then
					dist_ = param.playerFrontToCenter

				end
				inter_pos = ball.pos() + Utils.Polar2Vector(dist_,(ball.pos() - theirDribblingPlayerPos):dir())

				debugEngine:gui_debug_msg(inter_pos,"middlePos",9)
				debugEngine:gui_debug_x(inter_pos,9)
				debugError = "GetballPos Special: TwoEnemy"

			elseif (#minEnemyDistNum == 1) then
				local dist_ = param.playerFrontToCenter + 80

				local theirDribblingPlayerPos = enemy.pos(GlobalMessage.Tick.their.dribbling_num)
				if player.pos(runner):dist(ball.pos() + Utils.Polar2Vector(param.playerFrontToCenter + 80,(ball.pos() - theirDribblingPlayerPos):dir())) < 50 then
					dist_ = param.playerFrontToCenter
				end
				inter_pos = ball.pos() + Utils.Polar2Vector(dist_,(ball.pos() - theirDribblingPlayerPos):dir())
				debugError = "GetballPos Special: OneEnemy"
			end
		end



		param.lastInterPos = inter_pos
		mvel = _c(endvel) or CVector:new_local(0,0)
		mpos = _c(inter_pos,runner)
		mdir = _c(idir,runner)
		macc = iacc or 0
		mspeed = _c(task.speed) or 0
		if type(task.sender) == "string" then
			msender = player.num(task.sender)
		end
		local debugflag = iflag == flag.dribbling and "Dribbling" or "DSS"
		debugEngine:gui_debug_msg(CGeoPoint(0,-3800),"iflag:  " .. debugflag)
		debugEngine:gui_debug_x(inter_pos,4)
		debugEngine:gui_debug_msg(inter_pos,debugError,4)
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
