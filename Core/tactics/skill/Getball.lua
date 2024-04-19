function Getball(task)
	local mpos
	local mdir
	local mflag   = task.flag or 0
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
			local inter_pos = Utils.GetBestInterPos(vision,playerPos,4,0,0)
			if inter_pos:x() == ball.pos():x() and ball.velMod() > 500 then
				inter_pos = CGeoPoint(-9999,-99999)
			end
			debugEngine:gui_debug_x(inter_pos,4)
			debugEngine:gui_debug_msg(inter_pos,runner .. "rPos",4)
		return _c(inter_pos)
	end
	execute = function(runner)
		if runner >=0 and runner < param.maxPlayer then
			if mrole ~= "" then
				CRegisterRole(runner, mrole)
			end
		else
			print("Error runner in getball", runner)
		end

		mpos = _c(task.pos,runner)
		mdir = _c(task.dir,runner)
		mvel = _c(task.vel) or CVector:new_local(0,0)
		macc = _c(task.acc) or 0
		mspeed = _c(task.speed) or 0
		if type(task.sender) == "string" then
			msender = player.num(task.sender)
		end

		task_param = TaskT:new_local()
		task_param.executor = runner
		task_param.player.pos = CGeoPoint(mpos)
		task_param.player.angle = mdir
		task_param.player.flag = mflag
		task_param.ball.Sender = msender or 0
		task_param.player.max_acceleration = macc or 0
		task_param.player.vel = CVector(mvel)
		task_param.player.force_manual_set_running_param = mforce_maunal_set_running_param
		-- return CGoCmuRush(runner, mpos:x(), mpos:y(), mdir, mflag, msender, macc, mrec, mvel:x(), mvel:y(), mspeed, mforce_maunal_set_running_param)
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
