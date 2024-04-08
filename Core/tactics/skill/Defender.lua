function Defender(task)
    matchPos = function()
        return ball.pos()
    end

    execute = function(runner)
        task_param = TaskT:new_local()
        task_param.executor = runner
        task_param.player.pos = CGeoPoint:new_local(0,0)
        return skillapi:run("Defender", task_param) -- 调用 Cpp 层函数
    end

    return execute, matchPos
end

gSkillTable.CreateSkill{
    name = "Defender",
    execute = function (self)
        print("This is in skill"..self.name)
    end
}