local maxPower = task.maxPower
local powerStep = task.powerStep

local maxBallVelMod = 0
local maxBallRawVelMod = 0
local firstBallVel = 0
local flag = true

local finsh = True
local file = io.open("./fitdatas/data.csv", "w+")
io.output(file)
io.write("playerNumber,power,maxBallVelMod,firstBallVel\n")

local init_params = function()
    task.task.kickPower = {}
    task.playerCount = 0
    for i=0,param.maxPlayer do
        task.task.kickPower[i] = -1
        if player.valid(i) then
            task.task.kickPower[i] = task.minPower
            task.playerCount = task.playerCount + 1
        end
    end
    task.playerCount = task.playerCount - 1
end

local debug_F = function()
    local sx, sy = (param.pitchLength/2)-1000, (param.pitchWidth/2)-param.penaltySegment
    local span = 140
    local sp = CGeoPoint:new_local(sx, sy)
    local v = CVector:new_local(0, -span)
    debugEngine:gui_debug_msg(sp+v*(-2),"fitPlayer1: "..tostring(task.fitPlayer1), param.BLUE)
    debugEngine:gui_debug_msg(sp+v*(-1),"fitPlayer2: "..tostring(task.fitPlayer2), param.BLUE)

    for i=0,param.maxPlayer-1 do
        debugEngine:gui_debug_msg(sp+v*i,"kickPower: "..tostring(task.kickPower[i]).."  "..tostring(i))
    end

    -- 打印需要测试的车
    debugEngine:gui_debug_msg(CGeoPoint(-3000, 2800),"fitPlayerLen: "..tostring(task.fitPlayerLen))

    for i=0, task.fitPlayerLen-1 do
        debugEngine:gui_debug_msg(CGeoPoint(-3000, 2600-(200*i)),"player: "..tostring(task.fitPlayerList[i]).."  "..tostring(i))
    end
    debugEngine:gui_debug_msg(CGeoPoint(-3000, 2600-(200*19)),"minPower:  "..tostring(task.minPower))
    debugEngine:gui_debug_msg(CGeoPoint(-3000, 2600-(200*20)),"maxPower:  "..tostring(task.maxPower))
    debugEngine:gui_debug_msg(CGeoPoint(-3000, 2600-(200*21)),"powerStep: "..tostring(task.powerStep))

end



local updateFitParams = function()
    local sx,sy = 200, -1000
    local sp = CGeoPoint:new_local(sx, sy)
    local span = 140
    local v = CVector:new_local(0, -span)

    local role = task.fitPlayer1
    local ballVelMod = ball.velMod()
    if flag then
        firstBallVel = ball.velMod()
        flag = false
    end
    -- 暂时拿不了
    -- local ballRawVelMod = ball.rawVelMod()
    local fitPower = task.task.kickPower[task.fitPlayer1]

    -- 最大速度
    maxBallVelMod = math.max(maxBallVelMod, ballVelMod)
    -- maxBallRawVelMod = math.max(ballRawVelMod, ballRawVelMod)

    debugEngine:gui_debug_msg(sp+v*1, string.format("fitPower:                %6.3f", fitPower), param.BLUE)
    debugEngine:gui_debug_msg(sp+v*2, string.format("maxBallVelMod:           %6.3f", maxBallVelMod), param.BLUE)
    debugEngine:gui_debug_msg(sp+v*3, string.format("firstBallVel:            %6.3f", firstBallVel), param.BLUE)
    -- debugEngine:gui_debug_msg(sp+v*1,string.format("maxBallRawVelMod:        %6.3f", maxBallRawVelMod),param.BLUE)
end

local saveFitParams = function()
    local sx,sy = 200,-1000
    local sp = CGeoPoint:new_local(sx,sy)
    local span = 140
    local v = CVector:new_local(0,-span)

    local role = task.fitPlayer1
    local ballVelMod = ball.velMod()
    -- 暂时拿不了
    -- local ballRawVelMod = ball.rawVelMod()
    local fitPower = task.kickPower[fitPlayer1]


    debugEngine:gui_debug_msg(sp+v*1, string.format("player:                  %6.3f", task.fitPlayer1), param.BLUE)
    debugEngine:gui_debug_msg(sp+v*2, string.format("fitPower:                %6.3f", task.kickPower[task.fitPlayer1]), param.BLUE)
    debugEngine:gui_debug_msg(sp+v*3, string.format("maxBallVelMod:           %6.3f", maxBallVelMod), param.BLUE)
    debugEngine:gui_debug_msg(sp+v*4, string.format("firstBallVel:            %6.3f", firstBallVel), param.BLUE)
    -- 存储文件
    io.write(string.format("%d,%f,%f,%f\n", task.fitPlayer1, task.kickPower[task.fitPlayer1], maxBallVelMod, firstBallVel))
    io.flush()

    task.task.kickPower[task.fitPlayer1] = task.kickPower[task.fitPlayer1] + task.powerStep
    maxBallVelMod = 0
    flag = true
end

toPlayerDir = function(role1, role2)
    return player.toPlayerDir(role1, role2)
end


gPlayTable.CreatePlay{

firstState = "init",
["init"] = {
    switch = function()
        debug_F()
        init_params()
        return "run_to_pos"
    end,
    Assister = task.stop(),
    Kicker = task.stop(),
    Special = task.stop(),
    Tier = task.stop(),
    Defender = task.stop(),
    Goalie = task.stop(),
    match = "[AKSTDG]"
},
["run_to_pos"] = {
    switch = function()
        debug_F()
        if bufcnt(true, 30) and player.kickBall(task.fitPlayer1) then
            return "recording"
        end
    end,
    Assister = task.getFitData_runToPos("Assister"),
    Kicker = task.getFitData_runToPos("Kicker"),
    Special = task.getFitData_runToPos("Special"),
    Tier = task.getFitData_runToPos("Tier"),
    Defender = task.getFitData_runToPos("Defender"),
    Goalie = task.getFitData_runToPos("Goalie"),
    match = "{AKSTDG}"
},
["recording"] = {
    switch = function()
        debug_F()
        updateFitParams()

        if player.kickBall(task.fitPlayer2) or ball.velMod() < 25 then
            saveFitParams()
            if task.fitPlayerLen == 1 and task.kickPower[task.fitPlayer1] > maxPower then
                return "finished"
            end
            return "run_to_pos"
        end
    end,

    Assister = task.getFitData_recording("Assister"),
    Kicker = task.getFitData_recording("Kicker"),
    Special = task.getFitData_recording("Special"),
    Tier = task.getFitData_recording("Tier"),
    Defender = task.getFitData_recording("Defender"),
    Goalie = task.getFitData_recording("Goalie"),
    match = "{AKSTDG}"
},
["finished"] = {
    switch = function()
        debug_F()
        debugEngine:gui_debug_msg(CGeoPoint(0, 0), "数据收集完成")
        if finsh then
            io.close()
        end
    end,
    Assister = task.stop(),
    Kicker = task.stop(),
    Special = task.stop(),
    Tier = task.stop(),
    Defender = task.stop(),
    Goalie = task.stop(),
    match = "{AKSTDG}"
},
name = "TestBenchTnT",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
