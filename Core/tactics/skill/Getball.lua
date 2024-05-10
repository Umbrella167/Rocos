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
			debugEngine:gui_debug_x(inter_pos,3)
			debugEngine:gui_debug_msg(inter_pos,runner .. "getBallPos",3)

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
		local playerPos = CGeoPoint:new_local(player.pos(runner):x(),player.pos(runner):y())
		local inter_pos = Utils.GetBestInterPos(vision,playerPos,param.playerVel,minter_flag,0,param.V_DECAY_RATE)
		local idir = (ball.pos() - inter_pos ):dir()
		local ballLine = CGeoSegment(ball.pos(),ball.pos() + Utils.Polar2Vector(9999,ball.velDir()))
		local prjPos = ballLine:projection(player.pos(runner))
		if (inter_pos:x() == ball.posX() and inter_pos:y() == ball.posY()) or not ballLine:IsPointOnLineOnSegment(prjPos) then
			idir = player.toBallDir(runner)
			debugError = "GetballPos Special: 60"
		end
		local ipos = inter_pos	

		local toballDir = math.abs((ball.rawPos() - player.rawPos(runner)):dir() * 57.3)
		local playerDir = math.abs(player.dir(runner)) * 57.3
		local Subdir = math.abs(toballDir-playerDir)
		local iflag = bit:_or(flag.allow_dss, flag.dodge_ball)
		if Subdir > 15 and player.toBallDist(runner) < 150 then 
			local DSS_FLAG = bit:_or(flag.allow_dss, flag.dodge_ball)
			iflag =  DSS_FLAG
		else
			-- iflag = bit:_or(flag.allow_dss,flag.dribbling) 
			iflag = flag.dribbling
		end
		-- 如果是敌方的球权，那么关闭闭障，直接怼脸

		ipos = CGeoPoint:new_local(ipos:x(),ipos:y())
		local ballLine = CGeoSegment(ball.pos(),ball.pos() + Utils.Polar2Vector(param.INF,ball.velDir()))
		local playerPrj = ballLine:projection(player.rawPos(runner))
		local canRush = ballLine:IsPointOnLineOnSegment(playerPrj)
		local endvel = Utils.Polar2Vector(0,(ipos - player.pos(runner)):dir())
		if canRush then
			endvel = Utils.Polar2Vector(0,(ipos - player.pos(runner)):dir())
		end


		--  特殊情况 敌方球权的时候
		if GlobalMessage.Tick.ball.rights == -1 or GlobalMessage.Tick.ball.rights == 2 then
			local theirDribblingPlayerPos = enemy.pos(GlobalMessage.Tick.their.dribbling_num)
			iflag = flag.dribbling
			ipos = ball.pos() + Utils.Polar2Vector(80,(ball.pos() - theirDribblingPlayerPos):dir())
			debugError = "GetballPos Special: 94"
		end
		--  特殊情况 去球坐标的时候
		if (ipos:x() == ball.posX() and ipos:y() == ball.posY()) then
			iflag = flag.dribbling
			ipos = ball.pos() + Utils.Polar2Vector(-65,player.toBallDir(runner))
			debugError = "GetballPos Special: 100"
		end
		--  除去抖动
		if (ipos - param.lastInterPos):mod() < 50 then
			ipos = param.lastInterPos
		end 
		if ipos:x() == param.INF then
			ipos = ball.pos()
			debugError = "Special: 103"
		end

		param.lastInterPos = ipos
		mvel = _c(endvel) or CVector:new_local(0,0)
		mpos = _c(ipos,runner)
		mdir = _c(idir,runner)
		macc = _c(task.acc) or 0
		mspeed = _c(task.speed) or 0
		if type(task.sender) == "string" then
			msender = player.num(task.sender)
		end
		local debugflag = iflag == flag.dribbling and "Dribbling" or "DSS"
		debugEngine:gui_debug_msg(CGeoPoint(0,-3800),"iflag:  " .. debugflag)
		debugEngine:gui_debug_x(ipos,4)
		debugEngine:gui_debug_msg(ipos,debugError,4)
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
