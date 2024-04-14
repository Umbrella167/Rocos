-- 在进入每一个定位球时，需要在第一次进时进行保持
--need to modify
if ball.refPosX() < -param.pitchLength / 2 / 2 then
		dofile("./lua_scripts/play/Ref/BackKick/BackKick.lua")
else
	dofile("./lua_scripts/play/Ref/CornerKick/CornerKick.lua")

end

-- gCurrentPlay = "TestFreeKick"

gOurIndirectTable.lastRefCycle = vision:getCycle()