local firstPos = {
    CGeoPoint(-1500,0),
    CGeoPoint(750,-1299),
    CGeoPoint(750,1299)
}
local toBallDir = function(role)
    return function()
        return player.toBallDir(role)
    end
end
local enemyRobot = {

}
-- 获取敌方带球机器人，顺手获取另外的机器人
local getTheirDribblingPlayer = function()
    enemyRobot = {}
    local minDist = 99999
    local minPlayer = -1
    for i=0,param.maxPlayer - 1 do
        if enemy.valid(i)then
            table.insert(enemyRobot,i)
            local dist = (enemy.pos(i) - ball.pos()):mod()
            if dist < minDist then
                minDist = dist
                minPlayer = i
            end
        end
    end
    for k,v in pairs(enemyRobot) do
        if v == minPlayer then
            table.remove(enemyRobot, k)
        end
    end
    return minPlayer
end
-- 获取敌方可能想要传球的机器人
local rotTable = {}
local getInterPos = function(theirDribblingPlayer)
    local dir = enemy.toBallDir(theirDribblingPlayer) * 57.3
    table.insert(rotTable, 1, dir)
    if #rotTable > 10 then
        table.remove(rotTable)
    end
    local enemyToBallLine = CGeoSegment(enemy.pos(theirDribblingPlayer),enemy.pos(theirDribblingPlayer) + Utils.Polar2Vector(9999,enemy.toBallDir(theirDribblingPlayer)))
    local enemy1prjPos =  enemyToBallLine:projection(enemy.pos(enemyRobot[1]))
    local enemy1ToLineDist = enemy1prjPos:dist(enemy.pos(enemyRobot[1]))
    table.insert(rotTable, 1, enemy1ToLineDist)
    if #rotTable > 10 then
        table.remove(rotTable)
    end
    local enemy2prjPos =  enemyToBallLine:projection(enemy.pos(enemyRobot[2]))
    local enemy2ToLineDist = enemy2prjPos:dist(enemy.pos(enemyRobot[2]))
    local dribblingDir = math.abs(57.3 * Utils.angleDiff(enemy.toBallDir(theirDribblingPlayer),(CGeoPoint(0,0) - enemy.pos(theirDribblingPlayer)):dir()))
    local resPos
    if math.abs(enemy.rotVel(theirDribblingPlayer)) > 1 then
        local DDbool = dribblingDir > 60 and true or false
    -- local DDbool = rotTable > 0  and true or false
    -- DDbool = dribblingDir > 60 and not DDbool or DDbool
    if #rotTable > 5 then 
        if rotTable[2] - rotTable[1] > 0 then
            DDbool = true
        else
            DDbool = false
        end
    end
    if(DDbool) then
        resPos = enemy.pos(enemyRobot[1]) + Utils.Polar2Vector(-2000,(enemy.pos(enemyRobot[1]) - enemy.pos(theirDribblingPlayer)):dir())
    else
        resPos = enemy.pos(enemyRobot[2]) + Utils.Polar2Vector(-2000,(enemy.pos(enemyRobot[2]) - enemy.pos(theirDribblingPlayer)):dir())
    end
    else
        resPos = enemy.pos(theirDribblingPlayer) + Utils.Polar2Vector(2000,enemy.toBallDir(theirDribblingPlayer))
    end
    debugEngine:gui_debug_x(resPos)
    -- debugEngine:gui_debug_msg(enemy.pos(theirDribblingPlayer),"dribblingDir:"..dribblingDir .. "rotVel: "..math.abs(enemy.rotVel(theirDribblingPlayer)),4)
    debugEngine:gui_debug_msg(enemy.pos(theirDribblingPlayer),"rotVel: "..math.abs(enemy.rotVel(theirDribblingPlayer)),4)
    debugEngine:gui_debug_msg(enemy.pos(enemyRobot[1]),"enemy1ToLineDist:"..enemy1ToLineDist,4)
    debugEngine:gui_debug_msg(enemy.pos(enemyRobot[2]),"enemy2ToLineDist:"..enemy2ToLineDist,4)
    debugEngine:gui_debug_line(enemy.pos(theirDribblingPlayer),enemy.pos(theirDribblingPlayer) + Utils.Polar2Vector(9999,enemy.toBallDir(theirDribblingPlayer)))
    return resPos
end
local ppos = CGeoPoint(0,0)
gPlayTable.CreatePlay{
firstState = "Init",
-- ["Init"] = {
--     switch = function()
--         local num = getTheirDribblingPlayer()
--         getInterPos(num)
--         return "Run"
--     end,
--     Assister = task.stop(),
--     match = "[A]"
-- },

-- ["Run"] = {
--     switch = function()
--         ppos = getInterPos(getTheirDribblingPlayer())
--     end,
--     Assister = task.goCmuRush(function() return ppos end,toBallDir("Assister"),_,_,_,Utils.Polar2Vector(300,(ppos - player.pos("Assister")):dir())),
--     match = "[A]"
-- },
["Init"] = {
    switch = function()
        local num = getTheirDribblingPlayer()
        getInterPos(num)
        
        for k,v in ipairs(firstPos) do 
            if player.pos("Assister"):dist(v) > 600 and ball.velMod() > 300 then
                return "getball"
            end
        end
        -- return "Run"
    end,
    Assister = task.goCmuRush(CGeoPoint(0,0)),
    match = "[A]"
},

["getball"] = {
    switch = function()
        local num = getTheirDribblingPlayer()
        getInterPos(num)
        for k,v in ipairs(firstPos) do 
            if player.pos("Assister"):dist(v) < 600 then
                return "Init"
            end
        end
        -- return "Run"
    end,
    Assister = task.getball(_,param.playerVel,param.getballMode),
    match = "[A]"
},

name = 'BOSS',
}