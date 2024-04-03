
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
		Utils.UpdataTickMessage(vision,1,2)   -- 更新帧信息
		Utils.GlobalComputingPos(vision)      -- 获取跑位点
		-- status = Utils.GlobalStatus(vision,0) -- 获取状态
		-- debugEngine:gui_debug_msg(CGeoPoint:new_local(-2000,0),status)
		a = task.GetGlobalStatus(0)
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-2000,0), 
			tostring(globalMessage.playerStatus[1].num) ..
			"      " .. 
			tostring(globalMessage.playerStatus[1].status))
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-2000,-500), 
			tostring(globalMessage.playerStatus[2].num) ..
			"      " .. 
			tostring(globalMessage.playerStatus[2].status))
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-2000,-1000), 
			tostring(globalMessage.playerStatus[3].num) ..
			"      " .. 
			tostring(globalMessage.playerStatus[3].status))

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
