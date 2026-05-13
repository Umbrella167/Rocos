# Common Messages

## Lua Module System (module(...), package.seeall)

- `Core/HuRocos-2024/task.lua` uses `module(..., package.seeall)` — all functions defined here belong to the `task` module table, NOT global scope
- Functions from such files must be called with the module prefix: `task.pass_2026(...)`, `task.getLineCrossDefenderPos()`
- Same applies to `ZBin/lua_scripts/worldmodel/task.lua` — functions like `defend_normV2()`, `defend_kick()`, `power()`, `getLineCrossDefenderPos()`, `simpleMoveTargetPos()` are all module-level; use `task.` prefix
- When calling from other files (e.g., NORMALPLAYV2.lua), prefix with `task.`

## CGeoPoint API Notes

- `CGeoPoint` has NO `distToLine()` method
- `CGeoPoint` has NO `isBetween()` method
- Robot-in-path detection must use manual CVector dot/cross product math:
  ```lua
  -- Check if enemyRobot blocks the line from ball to target
  local ball_to_target = target - ball_pos
  local ball_to_enemy = enemy_pos - ball_pos
  local proj_len = (ball_to_enemy:x() * ball_to_target:x() + ball_to_enemy:y() * ball_to_target:y()) / ball_to_target:length()
  local proj_point = ball_pos + ball_to_target * (proj_len / ball_to_target:length())
  local dist_to_line = (enemy_pos - proj_point):length()
  ```

## Utils.GetBestInterPos Return Value

- `Utils.GetBestInterPos` returns a `CGeoPoint` directly, NOT a `{isValid, point}` table
- My custom wrapper `Utils.GetBestIntercept2026` returns `CGeoPoint` directly too

## Play.lua Kick Return Format (lines 244-250)

The kick task in Play.lua processes return values as:
```lua
return { mexe, mpos, kickMode, dir, pre, kp, cp, flags }
```

## SmartGotoPosition::validateFinalTarget() Bug

- When `Allow_outside=true`, the penalty area avoidance code in `validateFinalTarget()` would pull out-of-field targets BACK inside the field
- Fix: skip penalty checks when `Allow_outside=true`
- File: `Core/src/Strategy/skill/SmartGotoPosition.cpp`

## Allow_outside Configuration

- C++ static param: `PARAM::ZJHU::Allow_outside` in `share/staticparams.cpp`
- INI key: `"ZJHU/Allow_outside"` (mind trailing spaces!)
- Lua-facing: `InField()` in `Core/src/Utils/utils.cpp` respects this flag
- RRT path planner KD-tree bounds also need expansion when Allow_outside=true (but reverted due to instability)

## INI File Quirk

- `share/staticparams.cpp` had a trailing space in the key string `"ZJHU/Allow_outside "` which caused param loading to fail silently
- Always trim whitespace in INI key strings

## Kick Power

- `power(pTargetPos, role_num, kick_mode)` calculates kick power based on distance to target
- Further target = stronger kick

## player.toPointDir

- `player.toPointDir(p, role)` returns a number (the direction angle), NOT a function
- Don't try to call it as a function

## Key Parameters (ZBin/lua_scripts/worldmodel/param.lua)

| Parameter | Default | Description |
|---|---|---|
| `defenderFastBallThreshold` | 800 | Ball speed threshold for "fast ball" |
| `defenderKickDist` | 1200 | Distance to kick when ball is close |
| `defenderMaxChaseDist` | 1000 | Max distance Defender chases ball |
| `defenderAssisterDist` | 200 | Small = Defender is more aggressive |
| `defenderActiveDist` | 700 | Distance trigger for active retrieval |
| `defenderActiveVel` | 400 | Ball speed threshold for active retrieval |
| `isReality` | false | Switches sim vs real-field parameters |

## Relevant Files

| File | Purpose |
|---|---|
| `Core/HuRocos-2024/play/NORMALPLAYV2.lua` | Main play; Defender task logic inline |
| `Core/HuRocos-2024/task.lua` | Task functions (module) including `pass_2026` |
| `ZBin/lua_scripts/worldmodel/task.lua` | Core task module: `defend_normV2`, `defend_kick`, `power`, etc. |
| `ZBin/lua_scripts/worldmodel/param.lua` | All tunable parameters |
| `ZBin/lua_scripts/worldmodel/player.lua` | Player functions (`toPointDir`, `pos`, `toBallDist`) |
| `ZBin/lua_scripts/worldmodel/ball.lua` | Ball functions (`pos`, `velMod`) |
| `ZBin/lua_scripts/worldmodel/enemy.lua` | Enemy functions (`valid`, `pos`) |
| `ZBin/lua_scripts/Play.lua` | Play execution engine |
| `ZBin/lua_scripts/SubPlay.lua` | Sub-play system |
| `Core/src/Strategy/skill/SmartGotoPosition.cpp` | `validateFinalTarget()` Allow_outside fix |
| `Core/src/Utils/utils.cpp` | `MakeInField`, `IsInField`, `InField`, `GetBestInterPos` |
| `share/staticparams.cpp` | `PARAM::ZJHU::Allow_outside` |
| `Core/src/LuaModule/utils.pkg` | tolua++ binding for Utils |
| `Core/src/OtherLibs/cmu/path_planner.cpp` | RRT planner (modified then reverted) |

## Key Functions (NORMALPLAYV2.lua, local)

- `defenderDirectTask()` — Main Defender task dispatcher
- `defendToBall(role, mode)` — Defense positioning facing the ball
- `kickBallForward()` — Consistent kick logic with chip detection
- `defenderClearTarget()` — Returns clear target position
- `rolePos(role)` — Get role's position
- `roleNum(role)` — Get role's robot number
- `roleHasBallControl(role)` — Check if role controls the ball
- `nearestEnemyInfo(role)` — Get nearest enemy info
- `isLuaCGeoPointValid(point)` — Check CGeoPoint validity
- `point(x, y)` — Shorthand for CGeoPoint creation
- `clamp(val, min, max)` — Clamp utility

## Key Functions (ZBin/lua_scripts/worldmodel/task.lua, module-level)

- `defend_normV2(r, target)` — Normal defense movement
- `defend_kick(r, target, kickPower, kickMode)` — Defense kick
- `getLineCrossDefenderPos()` — Line-cross defender position
- `simpleMoveTargetPos()` — Simple move target
- `power(pTargetPos, role_num, kick_mode)` — Kick power calculation
- `defenderCount`, `defenderNums` — Defender count/number tables
- `getDefenderCount()` — Get defender count
- `isClosestPointDefender()` — Check if closest point defender

## Workflow Tips

- Restart Core process to pick up Lua changes (no hot-reload)
- Lua `local function` definitions must be ordered before their callers (Lua does not hoist locals)
- When creating local functions that reference each other, define in dependency order
- `defender_kick_cooldown` was removed (not needed); `defender_clear_target` is a global state variable
