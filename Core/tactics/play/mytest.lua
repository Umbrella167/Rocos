
local shootGen = function()
	return function()
		local standPos = CGeoPoint:new_local(4500,0)
		return CGeoPoint:new_local(4500,0)
	end
end
gPlayTable.CreatePlay{

firstState = "GetGlobalMessage",

["GetGlobalMessage"] = {
	switch = function()
		local tick = Utils.UpdataTickMessage(vision,1,2)   -- 更新帧信息

		Utils.GlobalComputingPos(vision)      -- 获取跑位点
		-- status = Utils.GlobalStatus(vision,0) -- 获取状态
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-2000,0),status)
		task.GetGlobalStatus(0)

		debugEngine:gui_debug_msg(CGeoPoint:new_local(0,0), tostring(tick))
		debugEngine:gui_debug_msg(CGeoPoint:new_local(0,-200), tostring(tick.our.player_num))
		for num,i in pairs(globalMessage.attackPlayerStatus) do 
			debugEngine:gui_debug_msg(CGeoPoint:new_local(-2000,num * 200), 
			tostring(i.num) ..
			"      " .. 
			tostring(i.status))
			num = num + 500
		end

	end,
	Assister = task.stop(),
	Kicker = task.stop(),
	Special = task.stop(),
	Tier = task.stop(),
	Defender = task.stop(),
	Goalie = task.stop(),
	match = "[AKS]{TDG}"
},


name = "mytest",
applicable ={
	exp = "a",
	a = true
},
attribute = "attack",
timeout = 99999
}
