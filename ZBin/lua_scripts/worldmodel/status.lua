module(..., package.seeall)
--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---

--			               HU-ROCOS-2024   	                 ---

--- ///  /// --- /// /// --- /// /// --- /// /// --- /// /// ---
-- 	 			 
--  
-- 处理C++传输的机器人状态、跑位点等信息
-- @auther: Umbrella
-- @2024/04/07
-- 
-- 获取全局机器人状态、存放到 GlobalMessage.globalPlayerStatus / attackPlayerStatus
function getGlobalStatus(attack_flag)
	-- 我方球权的情况下 获取进攻状态
    global_status = Utils.GlobalStatus(vision, attack_flag)
    local result = {}
    local i = 1
    -- 将有效信息单独放在一个表里
    GlobalMessage.attackPlayerStatus = {}
    --处理数据
    for content in global_status:gmatch("%[(.-)%]") do
        local parts = {}

        for part in content:gmatch("[^,]+") do
            table.insert(parts, part)
        end
        table.insert(result, parts)
        local number = tonumber(parts[1]) + 1
        -- 全局信息存放在 playerStatus
        GlobalMessage.globalPlayerStatus[number].num = number - 1
        GlobalMessage.globalPlayerStatus[number].status = parts[2]
        table.insert(GlobalMessage.attackPlayerStatus, 
        {
        	num = number - 1,
        	status = parts[2]
        }
        	)
        i = i + 1
    end
end

-- 获取跑位点
function getPlayerRunPos()
	GlobalMessage.attackPlayerRunPos = {}
	-- 遍历进攻机器人表
	for key,attackPlayerStatus in pairs(GlobalMessage.attackPlayerStatus) do
		-- 找到需要跑位的机器人
		if attackPlayerStatus.status == "Run" then
			-- 获取跑位点
			local run_pos =  Utils.GetAttackPos(vision,attackPlayerStatus.num)
			run_pos_table = {
				num = attackPlayerStatus.num,
				pos = run_pos
			}
			-- append 到 attackPlayerRunPos
			table.insert(GlobalMessage.attackPlayerRunPos, run_pos_table)
		end
	end

	local dribbling_run_pos =  Utils.GetAttackPos(vision,GlobalMessage.Tick.our.dribbling_num)
	run_pos_table = {
				num = GlobalMessage.Tick.our.dribbling_num,
				pos = dribbling_run_pos
			}
	table.insert(GlobalMessage.attackPlayerRunPos, run_pos_table)
end

-- 获取主要（抢球、带球）机器人状态存入 attackMainPlayerStatus
function MainPlayerStatusFactory()
	GlobalMessage.attackMainPlayerStatus = {}
	for key,attackMainPlayerStatus in pairs(GlobalMessage.attackPlayerStatus) do
		-- 找到主要（抢球、带球）机器人
		if attackMainPlayerStatus.status ~= "Run" then
			-- 获取状态
			main_table = {
				num = attackMainPlayerStatus.num,
				status = attackMainPlayerStatus.status
			}
			-- append 到 attackPlayerRunPos
			table.insert(GlobalMessage.attackMainPlayerStatus, main_table)
		end
	end
end

-- 获取某机器人当前状态
-- function getPlayerStatus(role)
-- 	if role == -1 then
-- 		return "ERROR ROLE NUM = -1"
-- 	end
-- 	local num = player.num(role)
-- 	local playerStatus = GlobalMessage.globalPlayerStatus[num + 1].status
-- 	if playerStatus:sub(1, 12) == "passToPlayer" then
-- 		local name = player.name(tonumber(playerStatus:sub(13, -1)))
-- 		playerStatus = player.name(role) .. "passToPlayer" .. name
-- 	end
-- 	return playerStatus
-- end

function getPlayerStatus(role)
	if role == -1 then
		return "ERROR ROLE NUM = -1"
	end
	local num = player.num(role)
	local playerStatus = GlobalMessage.globalPlayerStatus[num + 1].status
	if playerStatus:sub(1, 12) == "passToPlayer" then
		playerStatus = "passToPlayer"
	end
	return playerStatus
end


function debugStatus()
	for key,i in pairs(GlobalMessage.globalPlayerStatus) do
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-6000,3000 - 300 * key),i.num .. "  " .. i.status,3,0,90)
	end

end