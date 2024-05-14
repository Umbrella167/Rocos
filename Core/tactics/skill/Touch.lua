function Touch(task)
	local mpos
	local useInter = task.useInter or false
	matchPos = function(runner)
		local inter_pos = Utils.GetBestInterPos(vision,player.pos(runner),param.playerVel,param.getballMode,0,param.V_DECAY_RATE,param.distRate)
		return _c(inter_pos)
	end
	execute = function(runner)
		mpos = _c(task.pos,runner)
		task_param = TaskT:new_local()
		task_param.executor = runner
		task_param.player.pos = mpos
		task_param.is_specify_ctrl_method = useInter
		return skillapi:run("Touch", task_param)
	end

	return execute, matchPos
end

gSkillTable.CreateSkill{
	name = "Touch",
	execute = function (self)
		print("This is in skill"..self.name)
	end
}