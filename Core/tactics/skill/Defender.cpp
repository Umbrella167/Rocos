#include "Defender.h"
void Defender::plan(const CVisionModule* pVision){
    setSubTask("SmartGoto",task());
    Skill::plan(pVision);
}