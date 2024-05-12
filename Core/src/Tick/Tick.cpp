#include "Tick.h"
#include "utils.h"
#include "singleton.hpp"
#include "WorldModel.h"

CTick::CTick() : _time(),
                 _ball(),
                 _our{6, -1, -1, 0},
                 _their{6, -1, -1, 0},
                 _task{},
                 _globalData()
{
}

void CTick::updateTick(const CVisionModule *pVision, int goalie_num, int defend_player_num1, int defend_player_num2)
{
    CTick newTick = new CTick();

    CWorldModel RobotSensor;

    /// 机器人信息
    int num_count = 0;
    int num_count_their = 0;

    // 防守人员
    newTick._our.goalie_num = goalie_num;
    newTick._our.defend_player_num1 = defend_player_num1;
    newTick._our.defend_player_num2 = defend_player_num2;

    // 球信息
    newTick._ball.valid = pVision->ball().Valid();
    newTick._ball.pos = pVision->ball().Valid() ? pVision->ball().Pos() : pVision->rawBall().Pos();
    newTick._ball.vel = pVision->ball().Vel().mod() / 1000;
    newTick._ball.vel_dir = pVision->ball().Vel().dir();

    // 时间信息
    newTick._time._time = std::chrono::high_resolution_clock::now();
    newTick._time.delta_time = (double)std::chrono::duration_cast<std::chrono::microseconds>(newTick._time._time - Tick[last]._time._time).count() / 1000000;
    newTick._time.tick_count += 1.0;

    // 最短距离
    double our_min_dist = inf;
    double their_min_dist = inf;

    /// 处理机器人数据
    for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
    {
        if (pVision->ourPlayer(i).Valid())
        {
            num_count += 1;

            // 如果球的视野消失，但是有红外信息，认为球的位置在触发红外的机器人上
            if (!pVision->ball().Valid())
                if (RobotSensor.InfraredOnCount(i) > 5)
                {
                    newTick._ball.pos = pVision->ourPlayer(i).Pos() + Polar2Vector(150, pVision->ourPlayer(i).Dir());
                }

            // 我方距离球最近的车号
            double to_ball_dist = pVision->ourPlayer(i).Pos().dist(newTick._ball.pos);
            if (our_min_dist > to_ball_dist)
            {
                our_min_dist = to_ball_dist;
                newTick._our.to_balldist_min_num = i;
            }
        }

        if (pVision->theirPlayer(i).Valid())
        {
            num_count_their += 1;

            // 敌方距离球最近的车号
            double to_ball_dist = pVision->theirPlayer(i).Pos().dist(newTick._ball.pos);
            if (their_min_dist > to_ball_dist)
                their_min_dist = to_ball_dist, newTick._their.to_balldist_min_num = i;

            // 获取敌方守门员
            if (InExclusionZone(pVision->theirPlayer(i).Pos()))
                newTick._their.goalie_num = i;
        }
    }
    newTick._our.player_num = num_count;
    newTick._their.player_num = num_count_their;

    // 处理红外无回包的情况 自定义红外
    if (pVision->ball().Valid())
    {
        if ((our_min_dist < PARAM::Player::playerInfraredCountBuffer &&
             abs(angleDiff(pVision->ourPlayer(newTick._our.to_balldist_min_num).RawDir(),
                           (pVision->ball().Pos() - pVision->ourPlayer(newTick._our.to_balldist_min_num).Pos()).dir()) *
                 PARAM::Math::PI) < 1.28) ||
            RobotSensor.InfraredOnCount(newTick._our.to_balldist_min_num) > 1)
        {
            newtick._task[newTick._our.to_balldist_min_num].infrared_off_count = 0;
            if (RobotSensor.InfraredOnCount(newTick._our.to_balldist_min_num) > 10)
            {
                newtick._task[newTick._our.to_balldist_min_num].infrared_count = RobotSensor.InfraredOnCount(newTick._our.to_balldist_min_num);
            }
            else
            {
                newtick._task[newTick._our.to_balldist_min_num].infrared_count += 1;
            }
        }
        else
        {
            newtick._task[newTick._our.to_balldist_min_num].infrared_count = 0;
            newtick._task[newTick._our.to_balldist_min_num].infrared_off_count += 1;
        }
    }
    else
    {
        newtick._task[newTick._our.to_balldist_min_num].infrared_count = RobotSensor.InfraredOnCount(newTick._our.to_balldist_min_num);
        newtick._task[newTick._our.to_balldist_min_num].infrared_off_count = RobotSensor.InfraredOffCount(newTick._our.to_balldist_min_num);
    }

    /// 球权判断
    // 球权一定是我方的情况
    if (RobotSensor.InfraredOnCount(newTick._our.to_balldist_min_num) > 5 || (our_min_dist < PARAM::Player::playerBallRightsBuffer && their_min_dist > PARAM::Player::playerBallRightsBuffer))
    {
        newTick._ball.rights = 1;
        newTick._our.dribbling_num = newTick._our.to_balldist_min_num;
        newTick._their.dribbling_num = -1;
    }
    // 球权一定是敌方的情况
    else if (RobotSensor.InfraredOffCount(newTick._our.to_balldist_min_num) > 5 && our_min_dist > PARAM::Player::playerBallRightsBuffer && their_min_dist < PARAM::Player::playerBallRightsBuffer)
    {
        newTick._ball.rights = -1;
        newTick._their.dribbling_num = newTick._their.to_balldist_min_num;
        //            newTick._our.dribbling_num = -1;
    }
    // 传球或射门失误导致的双方都无球权的情况
    else
    {
        newTick._ball.rights = 0;
    }
    // 顶牛 或 抢球对抗
    //        printf("_our minTob%f,_their %f", our_min_dist, their_min_dist);
    if ((RobotSensor.InfraredOnCount(newTick._our.to_balldist_min_num) > 5 || our_min_dist < PARAM::Player::playerBallRightsBuffer) && their_min_dist < PARAM::Player::playerBallRightsBuffer - 15)
    {
        newTick._ball.rights = 2;
    }

    // 球静止状态
    if (newTick._ball.vel < 0.01 || (abs(Tick[last]._ball.vel_dir - newTick._ball.vel_dir) > 0.006 && abs(Tick[last]._ball.vel_dir - newTick._ball.vel_dir) < 6))
    {
        newTick._ball.pos_move_befor = newTick._ball.pos;
        newTick._time.tick_key = 0;
        newTick._ball.predict_vel_max = 0;
    }

    // 获取第一次带球的位置
    // 如果远离球一定距离就一直更新
    if (our_min_dist > PARAM::Player::playerBallRightsBuffer + 15)
    {
        newTick._ball.first_dribbling_pos = newTick._ball.pos;
    }
    GDebugEngine::Instance()->gui_debug_arc(newTick._ball.first_dribbling_pos, 1000, 0, 360, 8);

    /// 需要两帧来更新的
    newTick._ball.acc = (newTick._ball.vel - tick._ball.vel) / newTick._time.delta_time;

    tick = newTIck;

    free newTick;
}