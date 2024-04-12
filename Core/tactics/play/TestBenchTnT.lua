local p = {
    CGeoPoint:new_local(-3000,-1000),
    CGeoPoint:new_local(3000,-1000)
}
local TEST_X = false
local FAIL_DEGREE = 30.0

local p_dir = (p[2]-p[1]):dir()
local task_dir = TEST_X and p_dir or p_dir+math.pi/2

local ROBOT_OFFSET = Utils.Polar2Vector(400,p_dir+math.pi/2)

local task_max_acc = 2000
local task_max_vel = 3500
local task_flag = flag.not_avoid_our_vehicle

local det_max_vel = 0
local det_rot_err = 0.0
local trigger_cycle = 0

local result_list = { -- {task_max_acc, task_max_vel, det_max_vel, det_rot_err, time(s)} - {3000,2000,3000,0.0}
}
local MAX_TEST_ACC_STEP = 9000
local MIN_TEST_ACC_STEP = 3000
-- default test acc
local set_new_task_param = function()
    local last_acc = task_max_acc
    local last_vel = task_max_vel
    local last_det_vel = det_max_vel
    local last_det_err = det_rot_err
    local last_success = det_rot_err < FAIL_DEGREE
    local total_success_cnt = 0.0
    local total_testing_cnt = 0
    for i=1,#result_list do
        local res = result_list[i]
        total_success_cnt = total_success_cnt + (res[4] < FAIL_DEGREE and 1 or 0)
        total_testing_cnt = total_testing_cnt + 1
    end
    local success_rate = total_success_cnt / total_testing_cnt
    local step = MAX_TEST_ACC_STEP*success_rate - (1-success_rate)*MAX_TEST_ACC_STEP + (last_success and MIN_TEST_ACC_STEP or -MIN_TEST_ACC_STEP)
    task_max_acc = math.max(2000,math.min(9999,task_max_acc+step))
end

local state_reset = function(store)
    if store then
        local times = (vision:getCycle() - trigger_cycle)*1.0/(1.0*param.frameRate)
        local result = {task_max_acc, task_max_vel, det_max_vel, det_rot_err, times}
        table.insert(result_list,result)
        set_new_task_param()
        -- store only the last 10
        if #result_list > 20 then
            table.remove(result_list,1)
        end
    end
    det_max_vel = 0
    det_rot_err = 0.0
    trigger_cycle = vision:getCycle()
end


-- 有用到的

local maxPower = task.maxPower
local powerStep = task.powerStep
local ballMaxSpeed = {}

local init_params = function()
    task.kickPower = {}
    ballMaxSpeed = {}
    task.playerCount = 0
    for i=0,param.maxPlayer do
        task.kickPower[i] = -1
        ballMaxSpeed[i] = -1
        if player.valid(i) then
            ballMaxSpeed[i] = 0
            task.kickPower[i] = 0
            task.playerCount = task.playerCount + 1
        end
    end
    task.playerCount = task.playerCount - 1
end


-- local time = 0
local label = 0
-- local file = io.open("data.csv", "w+")
-- io.output(file)
-- io.write("time,playerPosX,playerPosY,playerVelMod,playerVelDir,playerRowVelMod,playerRowVelDir,targetPosX,targetPosY,label\n")


local debug_F = function()
    -- local ttick = Utils.UpdataTickMessage(vision, 1, 1)
    -- local time = time + ttick.time.delta_time
    
    local sx,sy = 200,-1000
    local span = 140
    local sp = CGeoPoint:new_local(sx,sy)
    local v = CVector:new_local(0,-span)

    -- local tTime = os.clock() - time
    local role = "Assister"
    -- local playerRawPos = player.rawPos(role)
    -- local playerRawPosX = player.rawPos(role):posX()  
    -- local playerRawPosY = player.rawPos(role):posY()  

    local playerPosX = player.posX(role)
    local playerPosY = player.posY(role)
    local playerVelMod = player.velMod(role)
    local playerVelDir = player.vel(role):dir()
    local playerRowVelMod = player.rawVelMod(role)
    local playerRowVelDir = player.rawVel(role):dir()
    -- local targetPos = player.gRolePos[role]()
    -- local targetPosX = targetPos:x()
    -- local targetPosY = targetPos:y()
    -- local playerToTargetDist = player.pos(role):dist(targetPos)
    det_max_vel = math.max(det_max_vel, playerVelMod)
    -- det_rot_err = math.max(det_rot_err,math.abs(rawDir-task_dir)*180/math.pi)

    -- debugEngine:gui_debug_line(p[1],p[2],param.GRAY)
    -- debugEngine:gui_debug_msg(sp+v*0,string.format("Set     ACC : %4.0f",task_max_acc),param.BLUE)
    -- debugEngine:gui_debug_msg(sp+v*1,string.format("Set MAX VEL : %4.0f",task_max_vel),param.BLUE)
    -- debugEngine:gui_debug_msg(sp+v*2,string.format("Det MAX VEL : %4.0f",rawVel),param.BLUE)
    -- debugEngine:gui_debug_msg(sp+v*3,string.format("Det MAX VEL : %4.0f",det_max_vel),param.GREEN)
    -- debugEngine:gui_debug_msg(sp+v*4,string.format("Rot MAX ERR°: %4.1f",det_rot_err),det_rot_err < FAIL_DEGREE and param.GREEN or param.RED)
    -- debugEngine:gui_debug_msg(sp+v*0,string.format("time:              %6.3f", time),param.BLUE)
    debugEngine:gui_debug_msg(sp+v*1,string.format("playerPosX:        %6.3f", playerPosX),param.BLUE)
    debugEngine:gui_debug_msg(sp+v*2,string.format("playerPosY:        %6.3f", playerPosY),param.BLUE)
    -- debugEngine:gui_debug_msg(sp+v*3,string.format("playerRawPosX:     %6.3f", playerRawPosX),param.BLUE)
    -- debugEngine:gui_debug_msg(sp+v*4,string.format("playerRawPosY:     %6.3f", playerRawPosY),param.BLUE)
    debugEngine:gui_debug_msg(sp+v*5,string.format("velMod:            %6.3f", playerVelMod),param.BLUE)
    debugEngine:gui_debug_msg(sp+v*6,string.format("velDir:            %6.3f", playerVelDir),param.BLUE)
    debugEngine:gui_debug_msg(sp+v*7,string.format("rowVelMod:         %6.3f", playerRowVelMod),param.BLUE)
    debugEngine:gui_debug_msg(sp+v*8,string.format("rowVelDir:         %6.3f", playerRowVelDir),param.BLUE)
    debugEngine:gui_debug_msg(sp+v*4,string.format("det_max_vel:    %6.3f", det_max_vel),param.GREEN)
    -- debugEngine:gui_debug_msg(sp+v*10,string.format("targetPosX:       %6.3f", targetPosX),param.GREEN)
    -- debugEngine:gui_debug_msg(sp+v*11,string.format("targetPosY:       %6.3f", targetPosY),param.GREEN)
    debugEngine:gui_debug_msg(sp+v*12,string.format("task.playerCount:       %d", task.playerCount),param.GREEN)

    debugEngine:gui_debug_msg(sp+v*13,string.format("task.kickPower:"))
    for i=0, task.playerCount-1 do
        debugEngine:gui_debug_msg(sp+v*(14+i),string.format("%d task.kickPower:       %d", i, task.kickPower[i]),param.GREEN)
    end
    debugEngine:gui_debug_msg(CGeoPoint(-2000, -2800),string.format("BallMaxSpeed:"))
    for i=0, task.playerCount-1 do
        debugEngine:gui_debug_msg(CGeoPoint(-2000, -2800-150*(i+1)), string.format("%d ballMaxSpeed:       %d", i, ballMaxSpeed[i]), param.GREEN)
    end

    -- 存储文件
    -- io.write(string.format("%f %f %f %f %f %f %f %f %f %f\n", time,  playerPosX, playerPosY, playerRawPosX, playerRawPosY, playerVelMod, playerVelDir, playerRowVelMod, playerRowVelDir, targetPosX, targetPosY))
    -- io.write(string.format("%f,%f,%f,%f,%f,%f,%f,%f,%f,%d\n", time,  playerPosX, playerPosY, playerVelMod, playerVelDir, playerRowVelMod, playerRowVelDir, targetPosX, targetPosY, label))

    -- if playerToTargetDist < 10 and playerVelMod < 11 then
    --     -- io.write(string.format("split\n"))
    --     time = 0
    --     label = label + 1
    -- end
    -- if label == 10 then
    --     io.close()
    -- end
end


toPlayerDir = function(role1, role2)
    return player.toPlayerDir(role1, role2)
end

-- 判断是否对准
local function judgePlayerDir(role,targetPos,error)
    local p = targetPos
    if type(p) == 'function' then
        p = p()
    else
        p = p
    end

    if math.abs(player.dir(role) - (p - player.pos( role )):dir()) < error then
        return true
    else 
        return false
    end
end


gPlayTable.CreatePlay{

firstState = "init",
["init"] = {
    switch = function()
        init_params()
        debug_F()
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
        -- debugEngine(CGeoPoint(1000,1000), task.fitPlayer1)
        -- if player.kickBall(task.fitPlayer1) then
        --     return "recording"
        -- end
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
        -- if ball.velMod() < 20 then
        --     return "shoot_ball"
        -- end
    end,
    Assister = task.stop(),
    Kicker = task.stop(),
    Special = task.stop(),
    Tier = task.stop(),
    Defender = task.stop(),
    Goalie = task.stop(),
    -- Assister = task.getFitData_recording("Assister"),
    -- Kicker = task.getFitData_recording("Kicker"),
    -- Special = task.getFitData_recording("Special"),
    -- Tier = task.getFitData_recording("Tier"),
    -- Defender = task.getFitData_recording("Defender"),
    -- Goalie = task.getFitData_recording("Goalie"),
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
