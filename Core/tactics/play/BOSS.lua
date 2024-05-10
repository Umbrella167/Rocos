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
local getTheirDribblingPlayer = function()
    local minDist = 99999
    local minPlayer = -1
    for i=0,param.maxPlayer do
        if enemy.valid(i)then 
            local dist = (enemy.pos(i) - ball.pos()):mod()
            if dist < minDist then
                minDist = dist
                minPlayer = i
            end
        end
    end
    return minPlayer
end
local dirbblingEnemyDir = 0
local interPos = function(enemyNum)
        local num 
        if type(enemyNum) == "function" then
            num = enemyNum()
        else
            num = enemyNum
        end
		local enemyDirPos = (enemy.pos(num) + Utils.Polar2Vector(-1200, (enemy.pos(num)-ball.pos()):dir()))
		if enemy.rotVel(num) > 1 then
			
		end
        for i,v in pairs(firstPos) do
            if player.toPointDist("Assister",v) < 700 then
                p = CGeoPoint(0,0)
                break
            end
        end
        return enemyDirPos
end
gPlayTable.CreatePlay{
firstState = "Init",
["Init"] = {
    switch = function()
        debugEngine:gui_debug_x(interPos(function() return getTheirDribblingPlayer() end))
    end,
    Assister = task.stop(),
    match = "[A]"
},
["Run"] = {
    switch = function()
		

    end,
    Assister = task.goCmuRush(function()return interPos(function() return getTheirDribblingPlayer() end)end, toBallDir("Assister"),_,_,Utils.Polar2Vector(700,(interPos(function() return getTheirDribblingPlayer() end) - player.pos("Assister")):dir())),
    match = "[A]"
},


name = 'BOSS',
}