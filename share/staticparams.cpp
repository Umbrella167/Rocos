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
        const double PLAYER_BUFFER = zpm->value("ZJHU/player_buffer", QVariant(130)).toFloat();
        const double PLAYER_BALLRIGHTS_BUFFER = zpm->value("ZJHU/player_ballrights_buffer", QVariant(120)).toFloat();
        const double PLAYER_INFRAREDCOUNT_BUFFER = zpm->value("ZJHU/player_infraredcount_buffer", QVariant(120)).toFloat();
        const double PLAYER_GOALIE = zpm->value("ZJHU/player_goalie", QVariant(0)).toFloat();
        const double PLAYER_DEFENDER1 = zpm->value("ZJHU/player_defender1", QVariant(1)).toFloat();
        const double PLAYER_DEFENDER2 = zpm->value("ZJHU/player_defender2", QVariant(2)).toFloat();
    }
}