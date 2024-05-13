gPlayTable.CreatePlay {
    firstState = "Init",

    ["Init"] = {
        switch = function()
            param.player_goalie = 1000
            return "Init1"
        end,
        Assister = task.stop(),
        match = "[A]"
    },

    ["Init1"] = {
        switch = function()
            debugEngine:gui_debug_msg(CGeoPoint(0, 1500), param.player_goalie)
        end,
        Assister = task.stop(),
        match = "[A]"
    },

    name = 'testsalta',
}


--[[ NOTE: 怎么修改的，写个备忘 ]]
--[[
~/zss.ini                                   是拿来存放参数的
~/Client/src/field.cpp                      利用 PARAM::FIELD::init 加了个初始化，从 zss.ini 里面加载
~/share/staticparams.h                      里面定义了 PARAM::ZJHU
~/share/staticparams.cpp                    里面定义了 PARAM::ZJHU
~/ZBin/lua_scripts/worldmodel/param.lua     lua 层的也从 zss.ini 里面加载
 ]]
