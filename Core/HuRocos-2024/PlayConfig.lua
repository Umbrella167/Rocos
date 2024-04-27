--[[
- `GameHalt`            : 比赛停止
- `GameStop`            : 比赛暂停
- `OurTimeout`          : 我方暂停
- `TheirIndirectKick`   : 对方间接任意球
- `OurIndirectKick`     : 我方间接任意球
- `TheirKickOff`        : 对方开球
- `OurKickOff`          : 我方开球
- `TheirBallPlacement`  : 对方自动放球
- `OurBallPlacement`    : 我方自动放球
- `TheirPenaltyKick`    : 对方点球
- `OurPenaltyKick`      : 我方点球
- `NormalPlay`          : 正常比赛
]]

---[[
gRefConfig = {
    GameHalt = "HALT",
    GameStop = "STOP",
    OurTimeout = "HALT",
    TheirIndirectKick = "NORMALPLAY",
    OurIndirectKick = "our_IndirectKick",
    TheirKickOff = "NORMALPLAY",
    OurKickOff = "NORMALPLAY",
    TheirBallPlacement = "their_BallPlacement",
    OurBallPlacement = "our_BallPlacement",
    TheirPenaltyKick = "STOP",
    OurPenaltyKick = "STOP",
    NormalPlay = "NORMALPLAY",
}
--]]