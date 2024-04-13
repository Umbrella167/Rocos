module(..., package.seeall)

-- 全局机器人状态
globalPlayerStatus = {
	{
		num = 0,
		status = "NOTHING"
	},
	{
		num = 1,
		status = "NOTHING"
	},
	{
		num = 2,
		status = "NOTHING"
	},
	{
		num = 3,
		status = "NOTHING"
	},
	{
		num = 4,
		status = "NOTHING"
	},
	{
		num = 5,
		status = "NOTHING"
	},
	{
		num = 6,
		status = "NOTHING"
	},
	{
		num = 7,
		status = "NOTHING"
	},
	{
		num = 8,
		status = "NOTHING"
	},
	{
		num = 9,
		status = "NOTHING"
	},
	{
		num = 10,
		status = "NOTHING"
	},
	{
		num = 11,
		status = "NOTHING"
	},
	{
		num = 12,
		status = "NOTHING"
	},
	{
		num = 13,
		status = "NOTHING"
	},
	{
		num = 14,
		status = "NOTHING"
	},
	{
		num = 15,
		status = "NOTHING"
	},

}


-- 有效进攻机器人状态
attackPlayerStatus = {
	--格式
	-- {
	-- 	num = 1,
	-- 	status = "NOTHING",
	-- },
}
-- 有效进攻机器人跑位点
attackPlayerRunPos = {
	--格式
	-- {
	-- 	num = 1,
	-- 	pos = CGeoPoint:new_local(0,0),
	-- },
}

attackMainPlayerStatus = {
	-- {
	-- 	num = 1,
	-- 	status = "NOTHING",
	-- },
}
-- 帧信息
Tick = Utils.UpdataTickMessage(vision,0,1,2)
