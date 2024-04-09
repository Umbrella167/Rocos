#pragma once
#include "skill_registry.h"

class Defender : public Skill
{
public:
    Defender() = default;
    virtual void plan(const CVisionModule *pVision) override;
    virtual void toStream(std::ostream &os) const override { os << "Defender"; }

private:
    enum STATE
    {
        ERROR = -1, // 错误
        STAND = 0,  // 等待
        PRE,        // 准备态
        GET,        // 抢夺态
        WALL,       // 阻止态
        // SHOOT
    };
    STATE _state;
    std::string debug_state;
};

REGISTER_SKILL(Defender, Defender);