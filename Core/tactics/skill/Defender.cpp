#include "Defender.h"
#include "utils.h"

namespace
{
    /* 球场信息 */
    /* 己方半场信息 */
    const int FIELD_X_MIN = -PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PENALTY_AREA_DEPTH;
    const int FIELD_X_MAX = 0;
    const int FIELD_Y_MIN = -PARAM::Field::PITCH_WIDTH / 2;
    const int FIELD_Y_MAX = PARAM::Field::PITCH_WIDTH / 2;

    const CGeoLine FIELD_BOR[3] = {
        {{FIELD_X_MIN, PARAM::Field::PENALTY_AREA_WIDTH / 2}, {FIELD_X_MIN, -PARAM::Field::PENALTY_AREA_WIDTH / 2}},
        {{PARAM::Field::PITCH_LENGTH / 2, PARAM::Field::PENALTY_AREA_WIDTH / 2}, {FIELD_X_MIN, PARAM::Field::PENALTY_AREA_WIDTH / 2}},
        {{-PARAM::Field::PITCH_LENGTH / 2, PARAM::Field::PENALTY_AREA_WIDTH / 2}, {FIELD_X_MIN, PARAM::Field::PENALTY_AREA_WIDTH / 2}}};
    const CGeoLine FIELD_PENALTYBOR({FIELD_X_MIN, PARAM::Field::PENALTY_AREA_WIDTH / 2}, {FIELD_X_MIN, -PARAM::Field::PENALTY_AREA_WIDTH / 2}); // 禁区所在直线

    /* 禁区信息 */

    /* 球员默认站位信息 */
    const CGeoPoint DEFAULT_STAND_POS(FIELD_X_MIN, PARAM::Field::PENALTY_AREA_WIDTH / 2);
    const double DEFAULT_STAND_DIR = 0;
    const double DEFAULT_DISTANCE_MAX = PARAM::FILED::PENALTY_AREA_WIDTH; // 两个后卫之间的最大距离
    const double DEFAULT_DISTANCE_MIN = 200.0;                            // 两个后卫之间的最小距离
}

void Defender::plan(const CVisionModule *pVision, const GlobalTick tick)
{
    auto ball = pVision->ball().pos();
    double their_angle = pVision->theirPlayer(tick.their.to_balldist_min_num);

    /* ====================================================================== */

    /* STAND - 默认状态站在位置等待 */
    CGeoPoint stand_pos = DEFAULT_STAND_POS;
    double stand_dir = -pVision->ball.Vel().dir();
    // MIND: 考虑是要恢复站位还是直接不动了

    /* PRE - 准备态 */
    bool state_pre = pVision->ball().pos().x() > FIELD_X_MIN && pVision->ball().pos().x() < FIELD_X_MAX && pVision->ball().pos().y() > FIELD_Y_MIN && pVision->ball().pos().y() < FIELD_Y_MAX;
    CGeoPoint hitPoint = ComputeCrossPENALTY(pVision->ball());
    if (hitPoint == {NULL, NULL}) // 朝向我方则防守
        state_pre = false;

    /* GET - 抢夺态 */
    bool state_get = pVision->ball.pos().dist() < 500;
    // TODO: 预测滚动距离截球

    /* WALL - 阻止态 */
    bool state_wall = pVision->theirPlayer(tick.their.to_balldist_min_num).Pos().dist(hitPoint) < 1000;

    /* ====================================================================== */

    TaskT newTask(task());

    if (NULL)
    {
        // 这里只是为了切换代码顺序（操作优先级）方便
    }
    else if (1 == tick.ball.rights && state_wall)
    {
        _state = WALL;
        newTask.player.pos = {FIELD_X_MIN, ComputeCrossPENALTY(pVision->ball()).y() + PARAM::Vehicle::V2::PLAYER_SIZE / 2};
        newTask.player.angle = stand_dir;
        setSubTask("SmartGoto", newTask);
    }
    else if (1 == tick.ball.rights && state_get)
    {
        _state = GET;
        setSubTask("Touch", newTask);
    }
    else if (state_pre)
    {
        // NOTE: 基本就是说车的间距跟着球走然后对球的跟随运动
        _state = PRE;
        newTask.player.pos = {FIELD_X_MIN, ComputeCrossPENALTY(pVision->ball()).y() + ComputeDistance(pVision->ball()) / 2, hitPoint};
        newTask.player.angle = stand_dir;
        setSubTask("SmartGoto", newTask);
    }
    else
    {
        newTask.player.pos = stand_pos;
        newTask.player.angle = stand_dir;
        setSubTask("SmartGoto", newTask);
    }

    Skill::plan(pVision);
}

/**
 * 根置动态调整后卫间距离
 @pam  {MobileVisionT} ball : 球    
 * @param  {CGeoPoint} hitPoint : 交点
 * @return {double}             : 两后卫之间距离
 */
double ComputeDistance(MobileVisionT ball, CGeoPoint  )
{
    double ballDis = ball.Pos().dist(hitPoint);
    if (ballDis > PARAM::Field::PITCH_WIDTH / 2)
        return DEFAULT_DISTANCE_MAX;
    else if (ballDis < PARAM::Field::PENALTY_AREA_DEPTH)
        return DEFAULT_DISTANCE_MIN;
    else
        return DEFAULT_DISTANCE_MIN + (DEFAULT_DISTANCE_MAX - DEFAULT_DISTANCE_MIN) * (ballDis / (PARAM::Field::PITCH_WIDTH / 2 - PARAM::Field::PENALTY_AREA_DEPTH));
}

/**
 * 球方向与禁区边的交点
 * @param  {MobileVisionT} ball : 球
 * @return {CGeoPoint}          : {NULL, NULL} 时表示无交点
 */
CGeoPoint ComputeCrossPENALTY(MobileVisionT ball)
{
    CGeoLineLineIntersection intersection(FIELD_PENALTYBOR, {ball.Pos(), ball.Vel().dir()}); // 获取球运动姿态的交点
    if (true == intersection.Intersectant())
    {
        return intersection.IntersectPoint();
    }
    return {NULL, NULL};
}

// TODO: 写个接口方便上层调用
