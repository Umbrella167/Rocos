#pragma once
#include "skill_registry.h"

class Defender : public Skill{
public:
    Defender() = default;
    virtual void plan(const CVisionModule* pVision) override;
    virtual void toStream(std::ostream& os) const override{ os << "Defender"; }
};

REGISTER_SKILL(Defender, Defender);