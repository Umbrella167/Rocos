# Rocos Project — AI Agent Guide

## Project Overview

Rocos is a RoboCup Small Size League (SSL) soccer robot control system. It features a **two-layer design**: C++ for algorithms (vision, path planning, motion control, physics), Lua for high-level strategy logic (plays, tasks, skills, FSM).

- **Version**: 0.0.2
- **License**: GPL-3.0
- **C++ Standard**: C++17
- **Build System**: CMake (>= 3.22)
- **Docs**: https://rocos.readthedocs.io/zh-cn/latest/

## Build Commands

```bash
# Full build
cmake -B build && cmake --build build

# Build with parallel jobs
cmake --build build -j$(nproc)

# Clean rebuild
rm -rf build && cmake -B build && cmake --build build
```

Dependencies (Ubuntu):
```bash
sudo apt-get install -y cmake build-essential libgl1-mesa-dev libode-dev qtbase5-dev qtdeclarative5-dev libqt5serialport5-dev libtolua++5.1-dev libeigen3-dev protobuf-compiler libprotobuf-dev qml-module-qtquick* qml-module-qtgamepad libfmt-dev
```

## Test / Lint / Typecheck

No automated test framework, linter, or typechecker is configured. Manual testing is done by:
- Running the simulator (`Client` binary) with test plays (e.g., `TestRun`, `TestSkill`, `TestGoalie`)
- Running Lua scripts in `ZBin/lua_scripts/play/Test/` directory
- Running test plays in `Core/tactics/play/`

## Project Structure

```
Rocos/
├── Client/          — Qt5 GUI (visualization, debug, simulation, log replay)
│   ├── src/         — 50+ C++ source files
│   ├── plugins/sim/ — Embedded grSim simulator (ODE physics)
│   └── robot/       — Robot sprite images
├── Core/            — AI engine "Medusa" (no GUI, Lua + C++)
│   ├── src/
│   │   ├── Algorithm/     — Core algorithms
│   │   ├── LuaModule/     — tolua++ binding (.pkg files)
│   │   ├── MotionControl/ — Robot motion control
│   │   ├── PathPlan/      — Path planning
│   │   ├── Strategy/      — Strategy (defence, rolematch, skill)
│   │   ├── Vision/        — Vision processing
│   │   ├── WorldModel/    — World state estimation
│   │   └── Main/          — Entry point
│   ├── HuRocos-2024/      — Tactic package (19 plays + skills)
│   └── tactics/           — Test tactic package
├── Controller/      — Qt5 hardware debug tool (gamepad/serial)
├── share/           — Shared C++ headers (geometry, params, protobuf)
│   └── proto/       — 23 .proto files (SSL standard + ZSS custom)
├── ZBin/            — Deployment directory
│   └── lua_scripts/ — Lua strategy system
│       ├── StartZeus.lua      — Entry point
│       ├── Config.lua         — Global config
│       ├── Zeus.lua           — Main loader
│       ├── SelectPlay.lua     — Play selection
│       ├── Play.lua           — FSM play engine
│       ├── RoleMatch.lua      — Role-to-robot matching
│       ├── worldmodel/        — 18 modules (ball, player, enemy, cond, ...)
│       ├── skill/             — 5 skill scripts
│       ├── play/              — Normal/Test/Ref/Autoref play scripts
│       └── utils/             — Utility scripts
├── cmake/           — CMake modules (FindODE, FindSphinx, Findtoluapp)
├── CMakeLists.txt   — Root build config
├── CodeFramework.md — Naming conventions & architecture
├── zss.ini          — Main system configuration
└── zss_simulator.ini — Simulator configuration
```

## Code Conventions

- **C++ functions**: PascalCase (`GetShootConfidence`, `GlobalComputingPos`)
- **C++ variables**: snake_case
- **Lua functions**: camelCase
- **Lua variables**: snake_case
- Philosophy: "C++ layer writes algorithms, Lua layer writes logic"
- All computed data is packed into a world model function; Lua reads on demand

## Key Lua Architecture (5-layer stack)

1. **Tactic** — Macro strategy package (multiple plays + skills)
2. **Play** — FSM defining multi-robot cooperation (states + transitions)
3. **Task** — Encapsulates skills with strategic parameters
4. **Skill** — High-level robot control (move, shoot, pass, intercept)
5. **Plan** — Trajectory planning (converts skill targets to velocity)

## Configuration

- `zss.ini` — Field dimensions, robot protocol, referee ports
- `zss_simulator.ini` — Simulator physics, vision, noise
- `ZBin/lua_scripts/worldmodel/param.lua` — All tunable strategy parameters
- `Core/HuRocos-2024/PlayConfig.lua` — Referee message → play mapping
- `README.md` — Pre-match tuning guide (Chinese)

## Critical Runtime Flags

- `isReality` in `ZBin/lua_scripts/worldmodel/param.lua` — Switches between simulation and real field parameters

## offical website
- https://rocos.readthedocs.io/zh-cn/latest/ 
