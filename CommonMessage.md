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
| `Core/HuRocos-2024/play/NORMALPLAYV2.lua` | Main play; Defender & marking task logic inline |
| `Core/HuRocos-2024/task.lua` | Task functions (module) including `pass_2026` |
| `ZBin/lua_scripts/worldmodel/task.lua` | Core task module: `defender_marking`, `defend_normV2`, `defend_kick`, `power`, etc. |
| `ZBin/lua_scripts/worldmodel/param.lua` | All tunable parameters (including marking v2 params) |
| `ZBin/lua_scripts/worldmodel/player.lua` | Player functions (`toPointDir`, `pos`, `toBallDist`) |
| `ZBin/lua_scripts/worldmodel/ball.lua` | Ball functions (`pos`, `velMod`) |
| `ZBin/lua_scripts/worldmodel/enemy.lua` | Enemy functions (`valid`, `pos`, `vel`, `velDir`, `velMod`, `dir`) |
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

## defender_marking() v2 Optimization (ZBin/lua_scripts/worldmodel/task.lua:1406)

The `defender_marking(role, pos)` function handles man-marking for Kicker & Special in `defendNormalState` (NORMALPLAYV2.lua:564-578). 6 optimizations implemented:

### 1. Goal-aware side selection
Lateral offset uses **goal direction** (`param.ourGoalPos - enemy_pos`) instead of static y-sign:
```lua
local perp_flag = (param.ourGoalPos:y() - enemy_pos:y()) > 0 and 1 or -1
local perp_dir = goal_dir + perp_flag * math.pi / 2
```
Ensures defender stands between enemy and our goal, blocking shooting lanes.

### 2. Reverse distance scaling
When enemy is close to ball → large lateral offset (wider stance to block angles). When far → small offset (collapse to center):
```lua
local lateral_offset = param.markingLateralBase * (1 - normalized_dist) + param.markingLateralMin
```

### 3. Threat-based sorting
Each enemy scored by: `threat = speed * moving_toward_goal * threatSpeedWeight + depth * threatPosWeight`
- `moving_toward_goal`: boolean based on angle between enemy velocity direction and goal direction
- `depth`: how far into our half the enemy is (x < markingThreshold)
- Uses `table.sort` descending; `angleDiff` computed via `math.atan2(math.sin(diff), math.cos(diff))`

### 4. Dynamic role-target assignment
Kicker gets the **highest threat** target; Special gets the **second-highest** (falls back to run-to-position if only 1 candidate). Replaces old fixed `markingTable[0]` / `markingTable[1]` assignment.

### 5. Graceful out-of-field fallback
No longer stays in place — falls back to `enemy_pos + Polar2Vector(minMarkingDist, goal_dir)`, then `MakeInField(buffer=150)`.

### 6. Independent parameters
Kicker & Special share the same function but get different targets via threat sorting. Parameters are tunable in `param.lua`.

## Enemy API — Available Methods

`ZBin/lua_scripts/worldmodel/enemy.lua` exposes:
- `enemy.pos(i)`, `enemy.posX(i)`, `enemy.posY(i)` — position
- `enemy.dir(i)` — orientation
- `enemy.vel(i)` — velocity vector (CGeoPoint)
- `enemy.velDir(i)` — velocity direction (float, radians)
- `enemy.velMod(i)` — velocity magnitude (float)
- `enemy.valid(i)` — boolean
- `enemy.toBallDist(i)`, `enemy.toBallDir(i)` — ball-relative

Same API shape as `ZBin/lua_scripts/worldmodel/player.lua`.

## CGeoPoint Constructor

Both forms work (tolua++ __call metamethod + :new_local):
- `CGeoPoint(x, y)` — function-call syntax
- `CGeoPoint:new_local(x, y)` — colon syntax

Both return a CGeoPoint userdata. `CGeoPoint(x, y)` is shorter for inline use.

## Lua vs C++ Performance Decision

For the marking logic, **keeping computation in Lua is correct**:
- All heavy operations (`Polar2Vector`, `dist`, `dir`, `mod`, `GoCmuRush`) are already tolua++ C++ bindings
- Lua only does simple conditionals, table ops, and scalar math (microsecond-level cost)
- `GoCmuRush` path planning accounts for 90%+ of tick computation, dwarfing marking position math
- Lua offers faster iteration: no recompilation, parameters in `param.lua`, restart Core only

**When to move to C++**: large-scale numerical computation (RRT, Kalman filter, dense collision detection), 100+ geometry ops per frame, hard real-time constraints.

## New Marking Parameters (ZBin/lua_scripts/worldmodel/param.lua:179-188)

| Parameter | Default | Description |
|---|---|---|
| `markingThreshold` | 1500 | Ball x-coordinate threshold to enter marking mode (mm) |
| `minMarkingDist` | playerRadius * 3 (~210) | Minimum marking distance from enemy (mm) |
| `maxMarkingDist` | 3000 | Max effective marking distance; beyond this = run-to-position (mm) |
| `markingLateralBase` | 500 | Lateral offset when enemy-ball distance = 0 (mm) |
| `markingLateralMin` | 80 | Minimum lateral offset when enemy is far (mm) |
| `markingBackRate` | 1/10 | Backward offset coefficient = ballToEnemyDist * this |
| `markingThreatSpeedWeight` | 1.0 | Threat score multiplier for enemy speed toward goal |
| `markingThreatPosWeight` | 1.0 | Threat score multiplier for enemy depth in our half |

## Workflow Tips

- Restart Core process to pick up Lua changes (no hot-reload)
- Lua `local function` definitions must be ordered before their callers (Lua does not hoist locals)
- When creating local functions that reference each other, define in dependency order
- `defender_kick_cooldown` was removed (not needed); `defender_clear_target` is a global state variable
