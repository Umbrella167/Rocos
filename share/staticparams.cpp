#include "staticparams.h"
#include "parammanager.h"

auto zpm = ZSS::ZParamManager::instance();

namespace PARAM
{
    namespace Field
    {
        const double PITCH_LENGTH = zpm->value("field/width", QVariant(9000)).toFloat();
        const double PITCH_WIDTH = zpm->value("field/height", QVariant(6000)).toFloat();
        const double PENALTY_AREA_WIDTH = zpm->value("field/penaltyLength", QVariant(2000)).toFloat();
        const double PENALTY_AREA_DEPTH = zpm->value("field/penaltyWidth", QVariant(1000)).toFloat();
        const double GOAL_WIDTH = zpm->value("field/goalWidth", QVariant(1000)).toFloat();
        const double GOAL_DEPTH = zpm->value("field/goalDepth", QVariant(200)).toFloat();
    }

    namespace ZJHU
    {
        const double enemy_buffer = zpm->value("ZJHU/enemy_buffer", QVariant(130)).toFloat();
        const double playerBallRightsBuffer_BUFFER = zpm->value("ZJHU/playerBallRightsBuffer", QVariant(120)).toFloat();
        const double playerInfraredCountBuffer = zpm->value("ZJHU/playerInfraredCountBuffer", QVariant(120)).toFloat();
        const double our_goalie_num = zpm->value("ZJHU/our_goalie_num", QVariant(0)).toFloat();
        const double defend_num1 = zpm->value("ZJHU/defend_num1", QVariant(1)).toFloat();
        const double defend_num2 = zpm->value("ZJHU/defend_num2", QVariant(2)).toFloat();
    }
}