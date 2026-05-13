module(..., package.seeall)


InterPos = CGeoPoint:new_local(0,0)
function Inter()
	InterPos = CGeoPoint:new_local(0,0)
end

local function _resolveRoleNum2026(role_or_num)
	if type(role_or_num) == "number" then
		return role_or_num
	end
	if type(role_or_num) == "string" then
		local mapped = player.num(role_or_num)
		if mapped ~= nil and mapped ~= -1 then
			return mapped
		end
	end
	return nil
end

local function _resolveTargetPoint2026(target)
	if type(target) == "function" then
		return target()
	end
	return target
end

function pass_2026(role, pTargetPos, kickType, alignErrorDeg, approachDist, preAlignDist)
	local role_name = role or "Assister"
	local kick_mode = kickType or kick.flat
	local align_error = alignErrorDeg or 4.0

	return function()
		local role_num = _resolveRoleNum2026(role_name)
		if role_num == nil then
			return stop()
		end
		local target_pos = _resolveTargetPoint2026(pTargetPos)
		if target_pos == nil then
			return stop()
		end

		local target_dir = function(runner)
			local runner_pos = player.pos(runner)
			return (_resolveTargetPoint2026(pTargetPos) - runner_pos):dir()
		end
		local error_func = function()
			return align_error * math.pi / 180.0
		end
		local pass_dir = (_resolveTargetPoint2026(pTargetPos) - ball.pos()):dir()
		local hold_pos = ball.pos() + Utils.Polar2Vector(-35, pass_dir)
		local player_dir = player.dir(role_name)
		local sub_dir = math.abs(Utils.angleDiff(pass_dir, player_dir) * 180 / math.pi)
		local move_flag = flag.dribbling + flag.allow_dss
		if sub_dir < align_error + 2 then
			move_flag = flag.dribbling
		end
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-param.pitchLength / 2 + 200, param.pitchWidth / 2 - 1800), "pass_err:" .. string.format("%.1f", sub_dir), param.CYAN)
		debugEngine:gui_debug_msg(CGeoPoint:new_local(-param.pitchLength / 2 + 200, param.pitchWidth / 2 - 1950), "pass_ready:" .. tostring(sub_dir < align_error + 2), param.CYAN)
		debugEngine:gui_debug_x(hold_pos, param.CYAN)
		local end_vel = Utils.Polar2Vector(120, pass_dir)
		local mexe, mpos = GoCmuRush { pos = hold_pos, dir = target_dir, acc = a, flag = move_flag, rec = r, vel = end_vel }
		return {
			mexe,
			mpos,
			kick_mode,
			target_dir,
			error_func,
			power(pTargetPos, role_num, kick_mode),
			power(pTargetPos, role_num, kick_mode),
			flag.nothing
		}
	end
end
-- write your own task functions, and use it with `task.xxx()` in our own play
