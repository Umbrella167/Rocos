function CircleRun(task)
	matchPos = function()
		return ball.pos()
	end

	execute = function(runner)
		task_param = TaskT:new_local()
		task_param.executor = runner
		task_param.player.pos = CGeoPoint(30,80)
        task_param.player.rotvel = -5
        task_param.player.flag = flag.dribbling
		return skillapi:run("CircleRun", task_param)
	end

	return execute, matchPos
end

gSkillTable.CreateSkill{
	name = "CircleRun",
	execute = function (self)
		print("This is in skill"..self.name)
	end
}