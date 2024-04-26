#include "utils.h"
#include "WorldModel.h"
#include "staticparams.h"
#include <GDebugEngine.h>
#include <iostream>
#include <unistd.h>
#include <Eigen/Dense>
#include <fstream>
/*
    C++ 传数据到 Lua 总结
    1.utils.cpp        写好功能
    2.utils.h          定义好函数
    3.到 utils.pkg 仿照相应的函数定义
    4.重新构建

    @ data   : 20240205
    @ author : Umbrella
*/

const int inf = 1e9;

GlobalTick Tick[PARAM::Tick::TickLength];
int now = PARAM::Tick::TickLength - 1;
int last = PARAM::Tick::TickLength - 2;
CGeoPoint lastMovePoint = CGeoPoint(inf, inf);

namespace Utils
{
    // 没写完 START

    /**
     * 计算全局位置
     * @param  {CVisionModule*} pVision : 视觉模块
     * @param  {CGeoPoint} p            : 位置
     * @return {string}                 : 计算出的位置
     */
    string GlobalComputingPos(const CVisionModule *pVision)
    {

        return to_string(1);
    }

    /**
     * 全局视觉、物理信息保存
     * @param  {CVisionModule*} pVision : 视觉模块
     * @param  {int} goalie_num         : 守门员编号
     * @param  {int} defend_player_num1 : 后卫 1 编号
     * @param  {int} defend_player_num2 : 后卫 2 编号
     * @return {GlobalTick}             : 返回 Tick
     */
    GlobalTick UpdataTickMessage(const CVisionModule *pVision, int goalie_num, int defend_player_num1, int defend_player_num2)
    {
        CWorldModel RobotSensor;
        int oldest = 0;
        double our_min_dist = inf;
        double their_min_dist = inf;
        /// 记录帧信息
        for (int i = oldest; i < PARAM::Tick::TickLength - 1; ++i)
        {
            Tick[i] = Tick[i + 1];
        }

        /// 获取场上机器人信息
        int num_count = 0;
        int num_count_their = 0;
        Tick[now].our.goalie_num = -1;

        /// 更新帧信息
        // 防守人员
        Tick[now].our.defend_player_num1 = defend_player_num1;
        Tick[now].our.defend_player_num2 = defend_player_num2;
        Tick[now].our.goalie_num = goalie_num;
        // cout << "goalie_num: " << Tick[now].our.goalise_num << endl;
        // 球信息
        Tick[now].ball.pos = pVision->ball().Valid()?pVision->ball().Pos() : pVision->rawBall().Pos();
        Tick[now].ball.vel = pVision->ball().Vel().mod() / 1000;
        Tick[now].ball.vel_dir = pVision->ball().Vel().dir();
        Tick[now].ball.acc = (Tick[now].ball.vel - Tick[last].ball.vel) / Tick[now].time.delta_time;
        // 时间信息
        Tick[now].time.time = std::chrono::high_resolution_clock::now();
        Tick[now].time.delta_time = (double)std::chrono::duration_cast<std::chrono::microseconds>(Tick[now].time.time - Tick[last].time.time).count() / 1000000;
        Tick[now].time.tick_count += 1;

        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (pVision->ourPlayer(i).Valid())
            {
                // 如果球的视野消失，但是有红外信息，认为球的位置在触发红外的机器人上
                if(!pVision ->ball().Valid())
                    if(RobotSensor.InfraredOnCount(i)>5)
                        Tick[now].ball.pos = pVision->ourPlayer(i).Pos()+Polar2Vector(60,pVision->ourPlayer(i).Dir());
                // 我方距离球最近的车号
                double to_ball_dist = pVision->ourPlayer(i).Pos().dist(Tick[now].ball.pos);
                if (our_min_dist > to_ball_dist)
                    our_min_dist = to_ball_dist, Tick[now].our.to_balldist_min_num = i;
                // // 获取我方守门员
                // if (InExclusionZone(pVision->ourPlayer(i).Pos()))
                //     Tick[now].our.goalie_num = i;
            }

            if (pVision->theirPlayer(i).Valid())
            {

                num_count_their += 1;
                // 敌方距离球最近的车号
                double to_ball_dist = pVision->theirPlayer(i).Pos().dist(Tick[now].ball.pos);
                if (their_min_dist > to_ball_dist)
                    their_min_dist = to_ball_dist, Tick[now].their.to_balldist_min_num = i;
                // 获取敌方守门员
                if (InExclusionZone(pVision->theirPlayer(i).Pos()))
                    Tick[now].their.goalie_num = i;
            }
        }
        Tick[now].our.player_num = num_count;
        Tick[now].their.player_num = num_count_their;
        // 处理红外无回包的情况
        if (pVision->ball().Valid())
        {
            if (our_min_dist < PARAM::Player::playerBallRightsBuffer &&
               abs(angleDiff(pVision->ourPlayer(Tick[now].our.to_balldist_min_num).RawDir(),
               (pVision->ball().Pos() - pVision->ourPlayer(Tick[now].our.to_balldist_min_num).Pos()).dir()) *
               PARAM::Math::PI) < 1.28)
                Tick[now].task[Tick[now].our.to_balldist_min_num].infrared_count += 1;
            else
                Tick[now].task[Tick[now].our.to_balldist_min_num].infrared_count = 0;
        }
        else
        {
            Tick[now].task[Tick[now].our.to_balldist_min_num].infrared_count =RobotSensor.InfraredOnCount(Tick[now].our.to_balldist_min_num);
        }
        /// 球权判断
        // 球权一定是我方的情况
        if (RobotSensor.InfraredOnCount(Tick[now].our.to_balldist_min_num) > 5 || (our_min_dist < PARAM::Player::playerBallRightsBuffer && their_min_dist > PARAM::Player::playerBallRightsBuffer))
        {
            Tick[now].ball.rights = 1;
            Tick[now].our.dribbling_num = Tick[now].our.to_balldist_min_num;
            Tick[now].their.dribbling_num = -1;
        }
        // 球权一定是敌方的情况
        else if ((RobotSensor.InfraredOffCount(Tick[now].our.to_balldist_min_num) > 5) && our_min_dist > PARAM::Player::playerBallRightsBuffer && their_min_dist < PARAM::Player::playerBallRightsBuffer + 10)
        {
            Tick[now].ball.rights = -1;
            Tick[now].their.dribbling_num = Tick[now].their.to_balldist_min_num;
            //            Tick[now].our.dribbling_num = -1;
        }
        // 传球或射门失误导致的双方都无球权的情况
        else
            Tick[now].ball.rights = 0;
        // 顶牛 或 抢球对抗
        printf("our %f,their %f", our_min_dist, their_min_dist);
        if (Tick[now].ball.rights == 1 && their_min_dist < PARAM::Player::playerBallRightsBuffer + 20)
        {
            Tick[now].ball.rights = 2;
        }

        // 球静止状态
        if (Tick[now].ball.vel < 0.01 || (abs(Tick[last].ball.vel_dir - Tick[now].ball.vel_dir) > 0.006 && abs(Tick[last].ball.vel_dir - Tick[now].ball.vel_dir) < 6))
        {
            Tick[now].ball.pos_move_befor = Tick[now].ball.pos;
            Tick[now].time.tick_key = 0;
            Tick[now].ball.predict_vel_max = 0;
        }

        // 获取第一次带球的位置
        // 如果远离球一定距离就一直更新
        if (our_min_dist > PARAM::Player::playerBallRightsBuffer)
        {
            Tick[now].ball.first_dribbling_pos = Tick[now].ball.pos;
        }
        return Tick[now];
    }

    /**
     * 坐标安全性评分计算
     * @param  {CVisionModule*} pVision : pVision
     * @param  {CGeoPoint} start        : 起点
     * @param  {CGeoPoint} end          : 终点
     * @return {double}                 : 评判模型
     */
    double PosSafetyGrade(const CVisionModule *pVision, CGeoPoint start, CGeoPoint end, string model)
    {
        /*
            SHOOT 模式考虑守门员
            PASS  模式不考虑守门员
        */
        if (model == "SHOOT")
        {
            // ConfidencePass()
            CGeoSegment BallLine(start, end);
            // model SHOOT
            double dist = 0;
            double min_dist = inf;
            int min_num = 0;
            double grade = 0;
            for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
            {
                if (i == Tick[now].their.goalie_num || !pVision->theirPlayer(i).Valid())
                    continue;

                CGeoPoint VildPos = pVision->theirPlayer(i).Pos();
                if (VildPos.x() < start.x())
                    continue;
                dist = VildPos.dist(BallLine.projection(VildPos));
                if (min_dist > dist)
                    min_dist = dist, min_num = i;
            }
            double goalie_dist = pVision->theirPlayer(Tick[now].their.goalie_num).Pos().dist(end);
            if (goalie_dist > min_dist)
                grade = 0.7 * NumberNormalize(pVision->theirPlayer(min_num).Pos().dist(BallLine.projection(pVision->theirPlayer(min_num).Pos())), 1500, 0) +
                        0.3 * NumberNormalize(pVision->theirPlayer(Tick[now].their.goalie_num).Pos().dist(end), 1500, 0);
            else
                grade = NumberNormalize(pVision->theirPlayer(Tick[now].their.goalie_num).Pos().dist(end), 1000, 0);
            grade = grade > 1 ? 1 : grade;
            return grade;
        }
        else
        {
            double ball_max_speed = 4;
            double robot_max_speed = 1.5;
            double safty_grade;
            double their_min_time = inf;
            double their_min_num = 0;
            double enemy_to_ball_time = 0;
            CGeoSegment ball_line(start, end);
            int count = 0;
            // 获取敌方距离截球点最近的车，过滤在球线以后的车
            for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
            {
                if (!pVision->theirPlayer(i).Valid())
                    continue;
                // 如果有车在球后 计数
                if (Tick[now].their.goalie_num == i || !ball_line.IsPointOnLineOnSegment(ball_line.projection(pVision->theirPlayer(i).Pos())))
                {
                    count++;
                    continue;
                }
                double dist = ball_line.projection(pVision->theirPlayer(i).Pos()).dist(pVision->theirPlayer(i).Pos());
                // 当截球点在敌方禁区的时候，新构造一条垂直X轴的线段，求新的截球点
                if (InExclusionZone(ball_line.projection(pVision->theirPlayer(i).Pos())))
                {
                    // 新构造一条垂直X轴的线段
                    CGeoSegment Segment1(CGeoPoint(pVision->theirPlayer(i).Pos().x(), PARAM::Field::PITCH_WIDTH / 2),
                                         CGeoPoint(pVision->theirPlayer(i).Pos().x(), -1 * PARAM::Field::PITCH_WIDTH / 2));
                    // 新的截球点
                    CGeoPoint newInterPos = ball_line.segmentsIntersectPoint(Segment1);
                    dist = newInterPos.dist(pVision->theirPlayer(i).Pos());
                }
                enemy_to_ball_time = dist / robot_max_speed / 1000;
                if (their_min_time > enemy_to_ball_time)
                    their_min_time = enemy_to_ball_time, their_min_num = i;
                count = 0;
            }
            // 如果敌方车子都在球后面，认为安全
            if (count == Tick[now].their.player_num)
            {
                safty_grade = 1;
                return safty_grade;
            }
            // 球到截球点的时间
            double ball_to_interpos_time = ball_line.projection(pVision->theirPlayer(their_min_num).Pos()).dist(start) / ball_max_speed / 1000;
            safty_grade = NumberNormalize(their_min_time - ball_to_interpos_time, 0.25, -0.15);
            // GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(-3000, 2000), to_string(safty_grade) + "    " + to_string(their_min_num), 3);

            return safty_grade;
        }
    }

    /**
     * 坐标安全性评分计算
     * @param  {CVisionModule*} pVision : pVision
     * @param  {CGeoPoint} run_pos      : 遍历坐标
     * @param  {CGeoPoint} player_pos   : 机器人坐标
     * @return {CGeoPoint} target_pos   : 目标点（此次带球最终目的是为了传球或者射门）
     */
    double ShowDribblingGrade(const CVisionModule *pVision, CGeoPoint run_pos, CGeoPoint player_pos, CGeoPoint target_pos)
    {
        double player_to_target_dir_grade = 0;
        double min_enemy_grade = 0;
        double min_dist = inf;
        double player_to_limit_grade = 0;
        double player_to_ball_dir = (target_pos - player_pos).dir();
        double runpos_to_target_dir = (target_pos - run_pos).dir();
        double sub_dir = abs((runpos_to_target_dir - player_to_ball_dir) * PARAM::Math::RADIAN);
        double grade;

        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (!pVision->theirPlayer(i).Valid())
                continue;
            double dist = run_pos.dist(pVision->theirPlayer(i).Pos());
            if (min_dist > dist)
            {
                min_dist = dist;
            }
        }
        // 与敌人距离 得分
        min_enemy_grade = NumberNormalize(min_dist, 300, 100);
        // 目标点方向 得分
        double target_pos_dist = run_pos.dist(target_pos);
        double target_pos_dist_grade = NumberNormalize(target_pos_dist, 4000, 500);
        player_to_target_dir_grade = 0.5 * (1 - NumberNormalize(sub_dir, 40, 0)) + 0.5 * target_pos_dist_grade;

        player_to_limit_grade = 1 - NumberNormalize(run_pos.dist(Tick[now].ball.first_dribbling_pos), 1000, 300);
        grade = 0.2 * min_enemy_grade + 0.6 * player_to_target_dir_grade + 0.2 * player_to_limit_grade;
        // GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(0, -1000), to_string(grade));

        return grade;
    }

    CGeoPoint GetShowDribblingPos(const CVisionModule *pVision, CGeoPoint player_pos, CGeoPoint target_pos)
    {
        double radius = 300; // 圆的半径
        double step = 0.4;   // 步长
        double max_grade = -inf;
        CGeoPoint max_grade_point = CGeoPoint(0, 0);
        for (double angle = 0.0; angle < 2 * PARAM::Math::PI; angle += step)
        {
            double x = player_pos.x() + radius * cos(angle);
            double y = player_pos.y() + radius * sin(angle);
            CGeoPoint run_pos = CGeoPoint(x, y);
            if (run_pos.dist(Tick[now].ball.first_dribbling_pos) > 1000)
                continue;
            double grade = ShowDribblingGrade(pVision, run_pos, player_pos, target_pos);
            if (max_grade < grade)
            {
                max_grade = grade;
                max_grade_point = CGeoPoint(x, y);
            }
            // GDebugEngine::Instance()->gui_debug_x(CGeoPoint(x, y));
            // GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(x, y), to_string(grade), 1, 0, 60);
        }
        GDebugEngine::Instance()->gui_debug_arc(Tick[now].ball.first_dribbling_pos, 1000, 0, 360, 8);
//        GDebugEngine::Instance()->gui_debug_x(max_grade_point, 3);
//        GDebugEngine::Instance()->gui_debug_msg(max_grade_point,"goDribblingPos", 3);
        return max_grade_point;
    }

    /**
     * 获取球运动的最远距离
     * @brief GetBallMaxDist
     * @param pVision
     * @return
     */
    double GetBallMaxDist(const CVisionModule *pVision)
    {
        double a = PARAM::Field::V_DECAY_RATE;
        double v = pVision->ball().Vel().mod();
        double maxT = v / a;
        double maxDist = a * maxT * maxT;
        // GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(1000, 1500), "v:" + to_string(v));
        // GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(1000, 1000), "d:" + to_string(maxDist));
        return maxDist;
    }

    CGeoPoint GetBallMaxPos(const CVisionModule *pVision)
    {
        CGeoPoint ball_pos = pVision->ball().Pos();
        double maxDist = GetBallMaxDist(pVision);
        if (pVision->ball().Valid())
            ball_pos = pVision->ball().Pos();
        else
            ball_pos = pVision->rawBall().Pos();
        CGeoPoint maxBallPos = ball_pos + Polar2Vector(maxDist, pVision->ball().Vel().dir());

        return maxBallPos;
    }
    /**
     * 给球要经过的距离,返回到达此处的时间
     * @brief GetBallToDistTime
     * @param pVision
     * @param dist
     * @return
     */
    double GetBallToDistTime(const CVisionModule *pVision, double dist)
    {
        // TODO: 当球运动到最后的时候停在最远点，此时球到达这个点的时间应该是无限大的（前提：没有人去拿球）
        //       所以当球滚到最后（且速度较慢）的时候，应该相应的增加其权重

        double a = PARAM::Field::V_DECAY_RATE;
        double v = pVision->ball().Vel().mod();
        double t = sqrt((2 * a * dist + v * v) / a * a) - v / a;
        //        GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(1000, 2000), "t:"+to_string(t));
        return t;
    }

    /**
     * 获取相对某坐标最佳截球点（动态：球在运动过程中）
     * @brief GetBestInterPos
     * @param pVision
     * @param playerPos
     * @param playerVel
     * @param flag 不同模式（默认0）,0-最早能拿到球的截球点，1-时间最充裕的截球点, 2- (0,1)方案取中点
     * @param permissions 球员的权限（默认0）, 0-不允许进禁区和场外， 1-不可以到场外可以到禁区， 2-场外禁区都可以进
     * @return
     */

    CGeoPoint GetBestInterPos(const CVisionModule *pVision, CGeoPoint playerPos, double playerVel, int flag, int permissions)
    {
        CGeoPoint ball_pos = pVision->ball().Pos();
        if (pVision->ball().Valid())
            ball_pos = pVision->ball().Pos();
        else
            ball_pos = pVision->rawBall().Pos();
        double maxDist = GetBallMaxDist(pVision);
        CGeoPoint maxBallPos = ball_pos + Polar2Vector(maxDist, pVision->ball().Vel().dir());
        CGeoPoint maxAllowedBallPos = CGeoPoint(inf, inf);
        CGeoPoint maxTolerancePos = CGeoPoint(inf, inf);
        CGeoPoint minGetBallPos = CGeoPoint(inf, inf);
        double maxTolerance = -inf;
        double minTime = inf;

        double timeWeight = 1.0;

        // 遍历每个点，寻找最有可能的截球点
        for (int dist = 0; dist <= maxDist; dist += 100)
        {
            CGeoPoint ballPrePos = ball_pos + Polar2Vector(dist, pVision->ball().Vel().dir());
            double playerToBallDist = playerPos.dist(ballPrePos);
            double t = (playerToBallDist / playerVel) * 10 / 1000;
            double getBallTime = GetBallToDistTime(pVision, dist) / 1000;
            double tolerance = getBallTime - t;
            // 判断是否在禁区
            if (InExclusionZone(ballPrePos, 200) && permissions == 0)
                continue;
            // 判断是否在场外
            if (!InField(ballPrePos) && permissions < 2)
                continue;
            if (maxTolerance != -inf && tolerance < 0)
                break;

            // 可能截到球的点
            if (tolerance >= 0)
            {
                //                GDebugEngine::Instance()->gui_debug_line(playerPos, ballPrePos);
                // 记录最快截球点
                if (getBallTime < minTime)
                {
                    minTime = getBallTime;
                    minGetBallPos = ballPrePos;
                }
                // 记录时间最充裕的截球点
                if (tolerance > maxTolerance)
                {
                    maxTolerance = tolerance;
                    maxTolerancePos = ballPrePos;
                }
                //                GDebugEngine::Instance()->gui_debug_x(ballPrePos, 2);
            }
            maxAllowedBallPos = ballPrePos;
            //            GDebugEngine::Instance()->gui_debug_msg(ballPrePos, to_string(getBallTime),3,0,90);
            //            GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(ballPrePos.x() + 1000,ballPrePos.y()), to_string(t),4,0,90);
            //            GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(ballPrePos.x() + 2000,ballPrePos.y()), to_string(tolerance),1,0,90);
            //            GDebugEngine::Instance()->gui_debug_x(ballPrePos);
        }

        // 返回结果
        if (maxTolerance != -inf)
        {
            switch (flag)
            {
            case 0:
                // 返回最小能拿到球的位置
                //                GDebugEngine::Instance()->gui_debug_line(playerPos, minGetBallPos,5,1);
                return minGetBallPos;
                break;
            case 1:
                // 返回最大容忍度的位置
                //                GDebugEngine::Instance()->gui_debug_line(playerPos, maxTolerancePos,5,1);
                return maxTolerancePos;
                break;
            case 2:
                // 返回0,1方案的中点
                CGeoPoint posMid = CGeoPoint((minGetBallPos.x() + maxTolerancePos.x()) / 2, (minGetBallPos.y() + maxTolerancePos.y()) / 2);
                //                GDebugEngine::Instance()->gui_debug_line(posMid, maxTolerancePos,5,1);
                return posMid;
                break;
            }
        }
        else if (InField(maxBallPos) && !InExclusionZone(maxBallPos))
        {
            // 返回最远的球位置(场内)
            //            GDebugEngine::Instance()->gui_debug_line(playerPos, maxBallPos,5,1);
            return maxBallPos;
        }
        else
        {
            // 返回最后一个预测球的位置
            //            GDebugEngine::Instance()->gui_debug_line(playerPos, maxAllowedBallPos,5,1);
            return maxAllowedBallPos;
        }
        return CGeoPoint(inf, inf);
    }

    /**
     * 临时函数，用于采集玩家数据
     * @brief getInitData
     * @param pVision
     * @param flag
     */
    int getInitData(const CVisionModule *pVision, int flag = 1)
    {
        int debugInt = 0;

        int ourPlayerNums = pVision->getValidNum();
        int theirPlayerNums = pVision->getTheirValidNum();
        CGeoPoint player0Pos = pVision->ourPlayer(0).Pos();
        CVector player0Vel = pVision->ourPlayer(0).Vel();

        //        GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(-2000, 1000+150*(debugInt++)), "ballVel:"+to_string(pVision->ball().Vel().mod()));
        //        GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(-2000, 1000+150*(debugInt++)), "test:"+to_string(CVector(0, 0).dir())+"     "+to_string(CVector(0, 0).mod()));
        GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(-3000, 1000 + 150 * (debugInt++)), "player0Pos:" + to_string(player0Pos.x()) + "  " + to_string(player0Pos.y()));
        GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(-3000, 1000 + 150 * (debugInt++)), "player0VelMod:" + to_string(pVision->ourPlayer(0).Vel().mod()) + "  player0VelDir" + to_string(player0Vel.dir()));
        return 0;
    }

    /**
     * 获取player到某点的时间
     * @brief GetPlayerToDistTime
     * @param pVision
     * @param playerPos
     * @param playerV
     * @param target
     * @param targetV
     * @return
     */
    double GetPlayerToDistTime(const CVisionModule *pVision, CGeoPoint playerPos, CVector playerV, CGeoPoint target, CVector targetV = CVector(0, 0))
    {
        return 0;
    }

    /**
     * 坐标到坐标之间的时间
     * @param  {CGeoPoint} start_pos : 起始位置
     * @param  {CGeoPoint} end_pos   : 终点位置
     * @param  {double} velocity     : 速度
     * @return {double}              : 时间
     */
    double PosToPosTime(CGeoPoint start_pos, CGeoPoint end_pos, double velocity)
    {
        return (start_pos - end_pos).mod() / velocity;
    }

    /**
     * 预测球运动的线段
     * @param  {CVisionModule*} pVision : pVision
     * @return {CGeoSegment}            : 球运动轨迹的线段
     */

    CGeoSegment PredictBallLine(const CVisionModule *pVision)
    {
    }
    double GlobalConfidence(const CVisionModule *pVision, int attack_flag)
    {
        ///   /// /// OUR BALL RIGHTS /// ///   ///
        ///
        ///     Dribbling player [shoot,pass,dribbling]
        ///
        ///     Run player       [run,getball]
        ///
        ///   /// /// THEIR BALL RIGHTS /// /// ///
        ///
        ///     All player [defend,getball]
        ///
        /// ///////////////////////////////////////
        // attack_flag == 0 传统模式，两后卫专注防守
        // attack_flag == 1 开启猛攻模式 ，当球权在我方时，两个后卫插上辅助进攻
        int status = 0;
        double confidence_dribbling = 0;
        double max_confidence_pass = 0;
        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (!pVision->ourPlayer(i).Valid())
                continue;
            // 跳过守门员
            if (Tick[now].our.goalie_num == i)
                continue;
            // 如果是传统模式跳过后卫
            if (attack_flag == 0 && (Tick[now].our.defend_player_num1 == i || Tick[now].our.defend_player_num2 == i))
                continue;
            int num = i;
            Tick[now].task[num].player_num = i;
            Tick[now].task[num].confidence_shoot = 0;

            Tick[now].task[num].confidence_dribbling = 0;
            Tick[now].task[num].confidence_run = 0;
            Tick[now].task[num].confidence_defend = 0;
            Tick[now].task[num].confidence_getball = 0;
            // 球权是我方的情况
            if (Tick[now].ball.rights == 1)
            {
                // 带球机器人状态  ->  [射门，传球，带球，主动造犯规]
                if (Tick[now].our.dribbling_num == num)
                {
                    // 获取带球机器人的射门置信度
                    Tick[now].task[num].confidence_shoot = ConfidenceShoot(pVision, i);
                    Tick[now].task[num].confidence_shoot = Tick[now].task[num].confidence_shoot - 0.3 * (1 - NumberNormalize(pVision->ourPlayer(num).Pos().x(), 1200, 0));
                }
                // 非带球机器人状态  ->  [跑位，接球]
                else
                {
                    Tick[now].task[num].confidence_pass = 0;
                    // 如果无法被传球的非持球机器人 只能进行跑位
                    if (!isValidPass(pVision, pVision->ourPlayer(Tick[now].our.dribbling_num).Pos(), pVision->ourPlayer(i).Pos(), PARAM::Player::playerBuffer) || !isValidPass(pVision, pVision->ourPlayer(num).Pos(), pVision->ourPlayer(num).Pos(), PARAM::Player::playerBuffer))
                    {
                        Tick[now].task[num].confidence_run = 1;
                        Tick[now].task[num].status = "Run";
                        continue;
                    }
                    // 获取非带球机器人的被传球概率
                    Tick[now].task[num].confidence_shoot = ConfidenceShoot(pVision, pVision->ourPlayer(i).Pos());
//                                        Tick[now].task[num].confidence_shoot = Tick[now].task[num].confidence_shoot - 0.3 * (1 - NumberNormalize(pVision->ourPlayer(num).Pos().x(), 1200, 0));
                    Tick[now].task[num].confidence_shoot = Tick[now].task[num].confidence_shoot;
                    Tick[now].task[num].confidence_pass = ConfidencePass(pVision, Tick[now].our.dribbling_num, i, Tick[now].task[num].confidence_shoot);
                    // 如果友方位置太靠后，酌情扣分
                    if (pVision->ourPlayer(num).Pos().x() < 1000)
                        Tick[now].task[num].confidence_pass = Tick[now].task[num].confidence_pass - 0.4 * (1 - NumberNormalize(pVision->ourPlayer(num).Pos().x(), 1000, -2000));
                    Tick[now].task[num].confidence_run = 1;
                    Tick[now].task[num].status = "Run";
                    // 保存最大的被传球自信度给带球机器人
                    if (max_confidence_pass < Tick[now].task[num].confidence_pass && num != Tick[now].our.defend_player_num1 && num != Tick[now].our.defend_player_num2 && num != Tick[now].our.goalie_num)
                    {
                        max_confidence_pass = Tick[now].task[num].confidence_pass;
                        Tick[now].task[Tick[now].our.dribbling_num].confidence_pass = Tick[now].task[num].confidence_pass;
                        Tick[now].task[Tick[now].our.dribbling_num].max_confidence_pass_num = num;
                    }
                }
            }
            // 球权是敌方的情况
            else if (Tick[now].ball.rights == -1)
            {
                Tick[now].task[num].confidence_pass = 0;
                // 距离球最近的机器人去抢球，其余人去防守
                if (Tick[now].our.to_balldist_min_num == num)
                {
                    Tick[now].task[num].confidence_getball = 1;
                    Tick[now].task[num].status = "Getball";
                }
                else
                {
                    Tick[now].task[num].confidence_defend = 1;
                    Tick[now].task[num].status = "Defend";
                }
            }
            // 传球或射门失误导致的双方都无球权的情况  +  顶牛或抢球对抗的情况
            else if (Tick[now].ball.rights == 0 || Tick[now].ball.rights == 2)
            {
                Tick[now].task[num].confidence_pass = 0;
                // 距离球最近的机器人去抢球，其余人跑位
                if (Tick[now].our.to_balldist_min_num == num)
                {
                    Tick[now].task[num].confidence_getball = 1;
                    Tick[now].task[num].status = "Getball";
                }
                else
                {
                    Tick[now].task[num].confidence_run = 1;
                    Tick[now].task[num].status = "Run";
                }
            }
        }

        return 0;
    }

    std::string GlobalStatus(const CVisionModule *pVision, int attack_flag)
    {
        GlobalConfidence(pVision, attack_flag);
        double dribbling_threshold = 0.2718281828; // 更自然

        double pass_threshold = 0;
        string global_status = "";
        // 如果是我方球权，那么先决定带球机器人状态
        if (Tick[now].ball.rights == 1)
        {
            double confidence_shoot = Tick[now].task[Tick[now].our.dribbling_num].confidence_shoot;
            double confidence_pass = Tick[now].task[Tick[now].our.dribbling_num].confidence_pass;
            // 如果传球、射门的概率都 > 阈值，那么从中选择一项作为状态
            if (confidence_shoot > dribbling_threshold && confidence_pass > dribbling_threshold)
            {
                // 如果 传球概率 > 射门概率 阈值以上，那么才会传球  因为射门的收益会更高，所以条件要宽裕一点
                if (confidence_pass - confidence_shoot > pass_threshold)
                    Tick[now].task[Tick[now].our.dribbling_num].status = "passToPlayer" + to_string(Tick[now].task[Tick[now].our.dribbling_num].max_confidence_pass_num);
                else
                    Tick[now].task[Tick[now].our.dribbling_num].status = "Shoot";
            }
            // 如果某一项大于阈值某一项小于阈值，那么就按照大于阈值的概率来
            if (confidence_shoot > dribbling_threshold && confidence_pass < dribbling_threshold)
                Tick[now].task[Tick[now].our.dribbling_num].status = "Shoot";
            else if (confidence_shoot < dribbling_threshold && confidence_pass > dribbling_threshold)
                Tick[now].task[Tick[now].our.dribbling_num].status = "passToPlayer" + to_string(Tick[now].task[Tick[now].our.dribbling_num].max_confidence_pass_num);

            // 如果两项都小于阈值，那么就带球找机会
            if (confidence_shoot < dribbling_threshold && confidence_pass < dribbling_threshold)
            {
                Tick[now].task[Tick[now].our.dribbling_num].confidence_dribbling = 1;
                Tick[now].task[Tick[now].our.dribbling_num].status = "Dribbling";
            }
        }

        // Debug
        //        GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(0,0), "testmsg0");
        //        GDebugEngine::Instance()->gui_debug_x(GetBestInterPos(pVision, CGeoPoint(0, 0), 2, 0));
        GetPlayerToDistTime(pVision, CGeoPoint(0, 0), pVision->ourPlayer(0).Vel(), CGeoPoint(1000, 1000), pVision->ball().Vel());

        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            printf("i:  %d , goalie_num:   %d", i, Tick[now].our.goalie_num);
            if (pVision->ourPlayer(i).Valid() && i != Tick[now].our.goalie_num && i != Tick[now].our.defend_player_num1 && i != Tick[now].our.defend_player_num2)
            {

                global_status = global_status + "[" + to_string(Tick[now].task[i].player_num) + "," + Tick[now].task[i].status + "]";
                GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(pVision->ourPlayer(i).Pos().x(), pVision->ourPlayer(i).Pos().y() - 160), "Number: " + to_string(Tick[now].task[i].player_num), 4, 0, 80);
                GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(pVision->ourPlayer(i).Pos().x(), pVision->ourPlayer(i).Pos().y() - 250), "shoot: " + to_string(Tick[now].task[i].confidence_shoot), 8, 0, 80);
                GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(pVision->ourPlayer(i).Pos().x(), pVision->ourPlayer(i).Pos().y() - 340), "Pass: " + to_string(Tick[now].task[i].confidence_pass), 2, 0, 80);
                //                GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(pVision->ourPlayer(i).Pos().x(), pVision->ourPlayer(i).Pos().y() - 430), "Dribbling: " + to_string(Tick[now].task[i].confidence_dribbling), 1, 0, 80);
                //                GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(pVision->ourPlayer(i).Pos().x(), pVision->ourPlayer(i).Pos().y() - 520), "Getball: " + to_string(Tick[now].task[i].confidence_getball), 5, 0, 80);
                //                GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(pVision->ourPlayer(i).Pos().x(), pVision->ourPlayer(i).Pos().y() - 610), "Defene: " + to_string(Tick[now].task[i].confidence_defend), 6, 0, 80);
                //                GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(pVision->ourPlayer(i).Pos().x(), pVision->ourPlayer(i).Pos().y() - 700), "Run: " + to_string(Tick[now].task[i].confidence_run), 7, 0, 80);
                GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(pVision->ourPlayer(i).Pos().x(), pVision->ourPlayer(i).Pos().y() - 430), "Status: " + Tick[now].task[i].status, 3, 0, 80);
            }
        }

        return global_status;
    }
    double ConfidencePass(const CVisionModule *pVision, int dribbling_player_num, int getball_player_num, double getball_player_confidence_shoot)
    {
        // 传球路径安全评分
        double pass_safty_grade = 0;
        // 距离评分
        double pos_to_pos_dist_grade;
        // 方向评分
        double robot_to_pos_dir_grade;
        // 二级被传射门评分
        double pass_shoot_grade;
        double pass_grade;
        double grade;
        CGeoPoint dribbling_player_pos = pVision->ourPlayer(dribbling_player_num).Pos();
        CGeoPoint getball_player_pos = pVision->ourPlayer(getball_player_num).Pos();
        pass_safty_grade = PosSafetyGrade(pVision, dribbling_player_pos, getball_player_pos, "PASS");
        pos_to_pos_dist_grade = PosToPosDistGrade(dribbling_player_pos.x(), getball_player_pos.y(), getball_player_pos.x(), getball_player_pos.y());
        robot_to_pos_dir_grade = PosToPosDirGrade(dribbling_player_pos.x(), dribbling_player_pos.y(), getball_player_pos.x(), getball_player_pos.y(), 4 / PARAM::Math::RADIAN * PARAM::Math::PI, 1);

        pass_grade = 0.2 * pos_to_pos_dist_grade + 0.8 * robot_to_pos_dir_grade;
        grade = 0.2 * pass_grade + 0.2 * pass_safty_grade + 0.6 * getball_player_confidence_shoot;
        //        GDebugEngine::Instance() ->gui_debug_msg(CGeoPoint(-3000,3000),to_string(pass_grade));
        //        GDebugEngine::Instance() ->gui_debug_msg(CGeoPoint(-3000,2000),to_string(pass_safty_grade));
        //        GDebugEngine::Instance() ->gui_debug_msg(CGeoPoint(-3000,1000),to_string(getball_player_confidence_shoot));
        //        GDebugEngine::Instance() ->gui_debug_msg(CGeoPoint(-3000,0),to_string(grade));
        return grade;
    }

    double ConfidenceShoot(const CVisionModule *pVision, int dribbling_num)
    {
        double ball_max_speed = 6;
        double robot_max_speed = 3.5;
        double grade_shoot;
        double safty_grade;
        double grade;
        double their_min_dist = inf;
        double their_min_num = 0;
        CGeoPoint player_pos = pVision->ourPlayer(dribbling_num).Pos();
        // 获取射门点
        CGeoPoint shoot_pos = GetShootPoint(pVision, dribbling_num);
        Tick[now].task[dribbling_num].shoot_pos = shoot_pos;
        grade_shoot = Tick[now].globalData.confidence_shoot;
        // 如果算不到射门点直接返回 0
        if (shoot_pos.y() == -inf || player_pos.x() > PARAM::Field::PITCH_LENGTH / 2 * 0.9)
            return 0;
        CGeoSegment ball_line(player_pos, shoot_pos);
        int count = 0;
        // 获取敌方距离截球点最近的车，过滤在球线以后的车
        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (!pVision->theirPlayer(i).Valid())
                continue;
            // 如果有车在球后 计数
            if (Tick[now].their.goalie_num == i || !ball_line.IsPointOnLineOnSegment(ball_line.projection(pVision->theirPlayer(i).Pos())))
            {
                count++;
                continue;
            }
            double dist = ball_line.projection(pVision->theirPlayer(i).Pos()).dist(pVision->theirPlayer(i).Pos());
            // 当截球点在敌方禁区的时候，新构造一条垂直X轴的线段，求新的截球点
            if (InExclusionZone(ball_line.projection(pVision->theirPlayer(i).Pos())))
            {
                // 新构造一条垂直X轴的线段
                CGeoSegment Segment1(CGeoPoint(pVision->theirPlayer(i).Pos().x(), PARAM::Field::PITCH_WIDTH / 2),
                                     CGeoPoint(pVision->theirPlayer(i).Pos().x(), -1 * PARAM::Field::PITCH_WIDTH / 2));
                // 新的截球点
                CGeoPoint newInterPos = ball_line.segmentsIntersectPoint(Segment1);
                dist = newInterPos.dist(pVision->theirPlayer(i).Pos());
            }
            if (their_min_dist > dist)
                their_min_dist = dist, their_min_num = i;
            count = 0;
        }
        // 如果敌方车子都在球后面，认为安全
        if (count == Tick[now].their.player_num)
        {
            safty_grade = 1;
            grade = 0.75 * grade_shoot + 0.25 * safty_grade;
            //            GDebugEngine::Instance() -> gui_debug_msg(CGeoPoint(-3000,2000),to_string(grade_shoot) + "    " + to_string(safty_grade) + "    " + to_string(grade),3);
            //            GDebugEngine::Instance() -> gui_debug_x(shoot_pos,3);
            return grade;
        }
        // 敌方到截球点的时间
        double enemy_to_ball_time = their_min_dist / robot_max_speed / 1000;
        // 球到截球点的时间
        double ball_to_interpos_time = ball_line.projection(pVision->theirPlayer(their_min_num).Pos()).dist(player_pos) / ball_max_speed / 1000;
        safty_grade = enemy_to_ball_time - ball_to_interpos_time;
        safty_grade = NumberNormalize(safty_grade, 0.15, 0);
        grade = 0.75 * grade_shoot + 0.25 * safty_grade;
        grade = grade - 0.5 * (1 - NumberNormalize(player_pos.x(), 1700, 0));
        //        GDebugEngine::Instance() -> gui_debug_msg(CGeoPoint(-3000,2000),to_string(grade_shoot) + "    " + to_string(safty_grade) + "    " + to_string(grade),3);
        //        GDebugEngine::Instance() -> gui_debug_x(shoot_pos,3);
        return grade;
    }
    double ConfidenceShoot(const CVisionModule *pVision, CGeoPoint player_pos)
    {
        double ball_max_speed = 6;
        double robot_max_speed = 3.5;
        double grade_shoot;
        double safty_grade;
        double grade;
        double their_min_dist = inf;
        double their_min_num = 0;
        // 获取射门点
        CGeoPoint shoot_pos = PosGetShootPoint(pVision, player_pos.x(), player_pos.y());
        grade_shoot = Tick[now].globalData.confidence_shoot;
        // 如果算不到射门点直接返回 0
        if (shoot_pos.y() == -inf)
            return 0;
        CGeoSegment ball_line(player_pos, shoot_pos);
        int count = 0;
        // 获取敌方距离截球点最近的车，过滤在球线以后的车
        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (!pVision->theirPlayer(i).Valid())
                continue;
            // 如果有车在球后 计数
            if (Tick[now].their.goalie_num == i || !ball_line.IsPointOnLineOnSegment(ball_line.projection(pVision->theirPlayer(i).Pos())))
            {
                count++;
                continue;
            }
            double dist = ball_line.projection(pVision->theirPlayer(i).Pos()).dist(pVision->theirPlayer(i).Pos());
            // 当截球点在敌方禁区的时候，新构造一条垂直X轴的线段，求新的截球点
            if (InExclusionZone(ball_line.projection(pVision->theirPlayer(i).Pos())))
            {
                // 新构造一条垂直X轴的线段
                CGeoSegment Segment1(CGeoPoint(pVision->theirPlayer(i).Pos().x(), PARAM::Field::PITCH_WIDTH / 2),
                                     CGeoPoint(pVision->theirPlayer(i).Pos().x(), -1 * PARAM::Field::PITCH_WIDTH / 2));
                // 新的截球点
                CGeoPoint newInterPos = ball_line.segmentsIntersectPoint(Segment1);
                dist = newInterPos.dist(pVision->theirPlayer(i).Pos());
            }
            if (their_min_dist > dist)
                their_min_dist = dist, their_min_num = i;
            count = 0;
        }
        // 如果敌方车子都在球后面，认为安全
        if (count == Tick[now].their.player_num)
        {
            safty_grade = 1;
            grade = 0.75 * grade_shoot + 0.25 * safty_grade;
            //            GDebugEngine::Instance() -> gui_debug_msg(CGeoPoint(-3000,2000),to_string(grade_shoot) + "    " + to_string(safty_grade) + "    " + to_string(grade),3);
            //            GDebugEngine::Instance() -> gui_debug_x(shoot_pos,3);
            return grade;
        }
        // 敌方到截球点的时间
        double enemy_to_ball_time = their_min_dist / robot_max_speed / 1000;
        // 球到截球点的时间
        double ball_to_interpos_time = ball_line.projection(pVision->theirPlayer(their_min_num).Pos()).dist(player_pos) / ball_max_speed / 1000;
        safty_grade = enemy_to_ball_time - ball_to_interpos_time;
        safty_grade = NumberNormalize(safty_grade, 0.15, 0);
        grade = 0.75 * grade_shoot + 0.25 * safty_grade;
        //        grade = grade - 0.5 * (1 - NumberNormalize(player_pos.x(), 2200, 500));
        //        GDebugEngine::Instance() -> gui_debug_msg(CGeoPoint(-3000,2000),to_string(grade_shoot) + "    " + to_string(safty_grade) + "    " + to_string(grade),3);
        //        GDebugEngine::Instance() -> gui_debug_x(shoot_pos,3);
        return grade;
    }
    /**
     * 坐标点关于最佳跑位点的评分
     * @param  {double} x          : x
     * @param  {double} y          : y
     * @param  {double} last_grade :
     * @return {double}            : (x,y)关于最佳跑位点的评分
     */
    double GetAttackGrade(const CVisionModule *pVision, double x, double y, CGeoPoint player_pos, CGeoPoint shoot_pos)
    {
        // 射门评分
        double shoot_grade;
        // 射门方向评分
        double shoot_dir_grade;
        // 射门距离评分
        double shoot_dist_grade;
        // 传球评分
        double pass_grade;
        // 传球方向评分
        double pass_dir_grade;
        // 传球距离评分
        double pass_dist_grade;
        // 传球安全度评分
        double pass_safty_grade;
        double grade = 0.0;
        shoot_dir_grade = PosToPosDirGrade(x, y, shoot_pos.x(), shoot_pos.y(), 4 / PARAM::Math::RADIAN * PARAM::Math::PI);
        shoot_dist_grade = PosToPosDistGrade(x, y, shoot_pos.x(), shoot_pos.y(), -1, "NORMAL");
        shoot_grade = 0.2 * shoot_dir_grade + 0.8 * shoot_dist_grade;
        pass_dir_grade = PosToPosDirGrade(x, y, player_pos.x(), player_pos.y(), 4 / PARAM::Math::RADIAN * PARAM::Math::PI);
        pass_dist_grade = PosToPosDistGrade(x, y, player_pos.x(), player_pos.y());
        pass_safty_grade = PosSafetyGrade(pVision, player_pos, CGeoPoint(x, y));
        pass_grade = 0.5 * pass_dir_grade + 0.5 * pass_dist_grade;

        grade = 0.2 * pass_grade + 0.15 * pass_safty_grade + 0.15 * shoot_dir_grade + 0.5 * shoot_dist_grade;
        ;
        return grade;
    }
    double GetTouchGrade(const CVisionModule *pVision, double x, double y, CGeoPoint player_pos, CGeoPoint shoot_pos)
    {
        // 射门评分
        double shoot_grade;
        // 射门方向评分
        double shoot_dir_grade;
        // 射门距离评分
        double shoot_dist_grade;
        // 传球评分
        double pass_grade;
        // 传球方向评分
        double pass_dir_grade;
        // 传球距离评分
        double pass_dist_grade;
        // 传球安全度评分
        double pass_safty_grade;
        double grade = 0.0;
        shoot_dir_grade = PosToPosDirGrade(x, y, shoot_pos.x(), shoot_pos.y(), 4 / PARAM::Math::RADIAN * PARAM::Math::PI);
        shoot_dist_grade = PosToPosDistGrade(x, y, shoot_pos.x(), shoot_pos.y(), -1, "NORMAL");
        shoot_grade = 0.1 * shoot_dir_grade + 0.9 * shoot_dist_grade;
        pass_dir_grade = PosToPosDirGrade(x, y, player_pos.x(), player_pos.y(), 4 / PARAM::Math::RADIAN * PARAM::Math::PI);
        pass_dist_grade = PosToPosDistGrade(x, y, player_pos.x(), player_pos.y());
        pass_safty_grade = PosSafetyGrade(pVision, player_pos, CGeoPoint(x, y));
        pass_grade = 0.2 * pass_dir_grade + 0.8 * pass_dist_grade;
        grade = 0.4 * shoot_grade + 0.3 * pass_grade + 0.3 * pass_safty_grade;
        return grade;
    }

    CGeoPoint GetTouchPos(const CVisionModule *pVision, CGeoPoint player_pos, double touchAngle, bool double_flag)
    {
        int LENGTH = (PARAM::Field::PITCH_LENGTH / 2) - 400;
        int WIDTH = (PARAM::Field::PITCH_WIDTH / 2) - 350;
        int step = PARAM::Field::PITCH_LENGTH / 2 * 0.085; // 230
        double grade = 0;
        double max_grade = -inf;
        CGeoPoint max_grade_point = CGeoPoint(0, 0);
        CGeoPoint max_shoot_point = CGeoPoint(0, 0);

        for (int x = 1800; x < LENGTH; x += step)
        {
            for (int y = -1 * WIDTH; y < WIDTH; y += step)
            {
                double touch_dir_grade = 0;
                CGeoPoint now_pos = CGeoPoint(x, y);
                CGeoPoint shoot_pos = PosGetShootPoint(pVision, x, y);

                if (shoot_pos.y() == -inf || InExclusionZone(now_pos) || !isValidPass(pVision, now_pos, player_pos))
                    continue;
                // 一传一touch的射门位计算
                if (!double_flag)
                {
                    double shootdir = 90 + (shoot_pos - now_pos).dir() * PARAM::Math::RADIAN;
                    double passdir = 90 + (now_pos - player_pos).dir() * PARAM::Math::RADIAN;
                    double touch_dir = 180 - (passdir - shootdir);
                    touch_dir = now_pos.y() < player_pos.y() ? 360 - touch_dir : touch_dir;
                    if (touch_dir > touchAngle || !isValidPass(pVision, player_pos, now_pos))
                        continue;
                    touch_dir_grade = 1 - NumberNormalize(touch_dir_grade, touchAngle, 0);
                    grade = 0.8 * GetTouchGrade(pVision, x, y, player_pos, shoot_pos) + 0.2 * touch_dir_grade;
                }
                // 一传二touch的射门位计算
                else
                {

                    grade = ConfidenceShoot(pVision, CGeoPoint(x, y));
                }

                if (max_grade < grade)
                {
                    max_grade = grade;
                    max_grade_point = now_pos;
                    max_shoot_point = shoot_pos;
                }
                //                GDebugEngine::Instance()->gui_debug_x(now_pos);
            }
        }

        //        GDebugEngine::Instance() ->gui_debug_msg(CGeoPoint(-2500,2000),to_string(shootdir) + "   " + to_string(passdir) + "   " + to_string(dir));
        GDebugEngine::Instance()->gui_debug_x(max_grade_point, 3);
        GDebugEngine::Instance()->gui_debug_msg(max_grade_point, "bestTouchPos",3);
        //        GDebugEngine::Instance()->gui_debug_x(max_shoot_point, 3);
        return max_grade_point;
    }

    CGeoPoint GetAttackPos(const CVisionModule *pVision, int num)
    {
        // 圆的半径
        int radius = 2000;
        int step = 450;
        // 射门评分
        double shoot_grade;
        // 射门方向评分
        double shoot_dir_grade;
        // 射门距离评分
        double shoot_dist_grade;
        // 传球评分
        double pass_grade;
        // 传球方向评分
        double pass_dir_grade;
        // 传球距离评分
        double pass_dist_grade;
        // 传球安全度评分
        double pass_safty_grade;
        double grade = 0.0;
        double max_grade = -inf;
        double min_dist_to_player = inf;
        CGeoPoint max_grade_pos;
        double grade_avd_ball = 0;
        // 圆心
        CGeoPoint player_pos = pVision->ourPlayer(num).Pos();
        CGeoPoint dribbling_player_pos = pVision->ourPlayer(Tick[now].our.dribbling_num).Pos();
        // 洒点
        for (int x = player_pos.x() - radius; x <= player_pos.x() + radius; x += step)
        {

            for (int y = player_pos.y() - radius; y <= player_pos.y() + radius; y += step)
            {

                CGeoPoint pos(x, y);
                CGeoPoint shoot_pos = PosGetShootPoint(pVision, x, y);
                // 如果 无有效射门点 或 点位在禁区 或 传球路径被挡住 或 射门路径被挡住  跳过该点
                if (!InField(pos) || shoot_pos.y() == -inf || InExclusionZone(pos) || (!isValidPass(pVision, dribbling_player_pos, CGeoPoint(x, y), PARAM::Player::playerBuffer)) || !isValidPass(pVision, pos, shoot_pos, PARAM::Player::playerBuffer))
                    continue;

                if (pos.dist2(player_pos) < radius * radius)
                {
                    double toballdist = player_pos.dist(Tick[now].ball.pos);

                    grade_avd_ball = NumberNormalize(toballdist, 1200, 100);
                    shoot_dir_grade = PosToPosDirGrade(x, y, shoot_pos.x(), shoot_pos.y(), 4 / PARAM::Math::RADIAN * PARAM::Math::PI);
                    shoot_dist_grade = PosToPosDistGrade(x, y, shoot_pos.x(), shoot_pos.y(), -1, "NORMAL");
                    shoot_grade = 0.2 * shoot_dir_grade + 0.8 * shoot_dist_grade;
                    pass_dir_grade = PosToPosDirGrade(x, y, dribbling_player_pos.x(), dribbling_player_pos.y(), 4 / PARAM::Math::RADIAN * PARAM::Math::PI, 1);
                    pass_dist_grade = PosToPosDistGrade(x, y, dribbling_player_pos.x(), dribbling_player_pos.y());
                    pass_safty_grade = PosSafetyGrade(pVision, dribbling_player_pos, CGeoPoint(x, y));
                    pass_grade = 0.5 * pass_dir_grade + 0.5 * pass_dist_grade;
                    if (x < 1000)
                        pass_grade = pass_grade - 0.4 * (1 - NumberNormalize(pVision->ourPlayer(num).Pos().x(), 1000, -500));
                    grade = 0.15 * pass_grade + 0.2 * pass_safty_grade + 0.05 * shoot_dir_grade + 0.6 * shoot_dist_grade + 0.6 * grade_avd_ball;

                    for (int j = 0; j < PARAM::Field::MAX_PLAYER; j++)
                    {
                        if (!pVision->ourPlayer(j).Valid())
                            continue;
                        if (j == Tick[now].our.goalie_num || j == num)
                            continue;
                        double dist = pos.dist(pVision->ourPlayer(j).Pos());
                        if (min_dist_to_player > dist)
                        {
                            min_dist_to_player = dist;
                        }
                    }
                    grade = grade - 0.8 * (1 - NumberNormalize(min_dist_to_player, 1300, 500));
                    grade = grade - 0.8 * (1 - NumberNormalize(x, 1500, 0));
                    //                    std::ostringstream stream;
                    //                    stream << std::fixed << std::setprecision(2) << grade;
                    //                    std::string a_str = stream.str();
                    //                    GDebugEngine::Instance() ->gui_debug_x(CGeoPoint(x,y),3);
                    //                    GDebugEngine::Instance() ->gui_debug_msg(CGeoPoint(x,y),a_str,3,0,80);
                    if (max_grade < grade)
                    {
                        max_grade = grade;
                        max_grade_pos = CGeoPoint(x, y);
                    }

                    //                    GDebugEngine::Instance()->gui_debug_x(pos);
                }
            }
        }
        GDebugEngine::Instance()->gui_debug_x(max_grade_pos, 3);
        GDebugEngine::Instance()->gui_debug_msg(max_grade_pos,"attackPos", 3);
        return max_grade_pos;
    }
    CGeoPoint GetAttackPos(const CVisionModule *pVision, int num, CGeoPoint shootPos, CGeoPoint startPoint, CGeoPoint endPoint, double step, double ballDist)
    {
        double flag = 0;
        double grade = 0;
        double max_grade = -inf;
        CGeoPoint player_pos = pVision->ourPlayer(num).Pos();
        CGeoPoint max_pos = CGeoPoint(0, 0);
        CGeoPoint max_shoot_pos = CGeoPoint(0, 0);
        CGeoPoint ball_pos = Tick[now].ball.pos;
        for (double x = min(startPoint.x(), endPoint.x()); x <= max(startPoint.x(), endPoint.x()); x += step)
        {
            for (double y = min(startPoint.y(), endPoint.y()); y <= max(startPoint.y(), endPoint.y()); y += step)
            {
                CGeoPoint new_local(x, y);
                for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
                    if (pVision->ourPlayer(i).Valid() && i != num)
                        if (pVision->ourPlayer(i).Pos().dist(new_local) < ballDist)
                        {
                            flag = 1;
                            break;
                        }
                if (flag == 1)
                {
                    flag = 0;
                    continue;
                }
                if (!isValidPass(pVision, new_local, shootPos) || !isValidPass(pVision, ball_pos, new_local,50) || new_local.dist(Tick[now].ball.pos) < ballDist || InExclusionZone(new_local,100))
                    continue;
                grade = GetAttackGrade(pVision, new_local.x(), new_local.y(), ball_pos, shootPos);
                GDebugEngine::Instance()->gui_debug_x(new_local);

                if (max_grade < grade)
                {
                    max_grade = grade;
                    max_pos = new_local;
                    max_shoot_pos = shootPos;
                }
            }
        }
        GDebugEngine::Instance()->gui_debug_x(max_pos, 3);
        GDebugEngine::Instance()->gui_debug_msg(max_pos,"attackPos", 3);
        return max_pos;
    }

    /**
     * 坐标点关于最佳射门点的评分
     * @param  {CVisionModule*} pVision : pVsion
     * @param  {double} x               : x
     * @param  {double} y               : y
     * @param  {int} num                : 守门员号码
     * @param  {std::string} model      : FORMULA：仅根据守门员位置进行计算，TRAVERSE：遍历整个可射门点（默认：TRAVERSE）
     * @return {CGeoPoint}              : (x,y)关于最佳射门点的评分
     */
    CGeoPoint PosGetShootPoint(const CVisionModule *pVision, double x, double y)
    {
        double pos_to_pos_dist_grade = 0;
        double pos_to_pos_dir_grade = 0;
        double pos_safety_grade = 0;
        double grade = 0;
        double max_grade = -inf;
        double max_y = -inf;
        double x1 = PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::GOAL_DEPTH / 2;
        for (int y1 = -1 * PARAM::Field::GOAL_WIDTH * 0.4; y1 < PARAM::Field::GOAL_WIDTH * 0.4; y1 += 50)
        {
            if (!isValidPass(pVision, CGeoPoint(x, y), CGeoPoint(PARAM::Field::PITCH_LENGTH / 2, y1), PARAM::Player::playerBuffer))
                continue;
            pos_to_pos_dist_grade = PosToPosDistGrade(x, y, x1, y1, -1, "NORMAL");
            pos_to_pos_dir_grade = PosToPosDirGrade(x, y, x1, y1, 1);
            pos_safety_grade = PosSafetyGrade(pVision, CGeoPoint(x, y), CGeoPoint(x1, y1));
            grade = 0.3 * pos_to_pos_dist_grade + 0.3 * pos_to_pos_dir_grade + 0.4 * pos_safety_grade;
            if (grade > max_grade)
            {
                max_grade = grade;
                max_y = y1;
            }
        }
        Tick[now].globalData.confidence_shoot = max_grade;
        CGeoPoint ShootPoint(PARAM::Field::PITCH_LENGTH / 2, max_y);
        return ShootPoint;
    }

    CGeoPoint GetShootPoint(const CVisionModule *pVision, int num)
    {
        CGeoPoint player_pos = pVision->ourPlayer(num).Pos();
        double x = player_pos.x();
        double y = player_pos.y();
        double pos_to_pos_dist_grade = 0;
        double pos_to_pos_dir_grade = 0;
        double player_to_pos_dir_grade = 0;
        double pos_safety_grade = 0;
        double grade = 0;
        double max_grade = -inf;
        double max_y = -inf;
        double x1 = PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::GOAL_DEPTH / 2;
        for (int y1 = -1 * PARAM::Field::GOAL_WIDTH * 0.35; y1 < PARAM::Field::GOAL_WIDTH * 0.35; y1 += 50)
        {
            if (!isValidPass(pVision, CGeoPoint(x, y), CGeoPoint(PARAM::Field::PITCH_LENGTH / 2, y1), PARAM::Player::playerBuffer))
                continue;
            pos_to_pos_dist_grade = PosToPosDistGrade(x, y, x1, y1, -1, "NORMAL");
            pos_to_pos_dir_grade = PosToPosDirGrade(x, y, x1, y1, 1);
            player_to_pos_dir_grade = RobotToPosDirGrade(pVision, num, player_pos, CGeoPoint(x1, y1));
            pos_safety_grade = PosSafetyGrade(pVision, CGeoPoint(x, y), CGeoPoint(x1, y1));
            grade = 0.3 * pos_to_pos_dist_grade + 0.25 * pos_to_pos_dir_grade + 0.35 * pos_safety_grade + 0.1 * player_to_pos_dir_grade;
            if (grade > max_grade)
            {
                max_grade = grade;
                max_y = y1;
            }
        }
        Tick[now].globalData.confidence_shoot = max_grade;
        CGeoPoint ShootPoint(PARAM::Field::PITCH_LENGTH / 2, max_y);
        GDebugEngine::Instance()->gui_debug_x(ShootPoint, 3);
        GDebugEngine::Instance()->gui_debug_msg(ShootPoint,"shootPos", 3);
        return ShootPoint;
    }
    /**
     * 判断两坐标之间是否存在敌人
     * @param  {CVisionModule*} pVision : pVision
     * @param  {CGeoPoint} start        : 起始坐标
     * @param  {CGeoPoint} end          : 终点坐标
     * @param  {double} buffer          : 缓冲值
     * @param  {bool} ignoreCloseEnemy  :（默 认为 false）
     * @param  {bool} ignoreTheirGuard  : 是否忽略敌方禁区（默认为 false）
     * @return {bool}                   : (true\false)
     */
    bool isValidPass(const CVisionModule *pVision, CGeoPoint start, CGeoPoint end, double buffer)
    {
        CGeoSegment Line(start, end);
        for (int i = 0; i < Tick[now].their.player_num; ++i)
        {
            CGeoPoint player_pos(pVision->theirPlayer(i).Pos());
            CGeoPoint player_projection = Line.projection(player_pos);
            if (!Line.IsPointOnLineOnSegment(player_projection))
                continue;
            if (player_pos.dist(player_projection) < buffer)
                return false;
            //            GDebugEngine::Instance() -> gui_debug_x(Line.projection(player_pos));
        }
        return true;
    }

    /**
     * 坐标到坐标之间的方向评分（GAUSS：可设峰值，NORMAL：越接近2 / Pi 分数越高）
     * @param  {double} x          : x
     * @param  {double} y          : y
     * @param  {double} x1         : x1
     * @param  {double} y1         : y1
     * @param  {int} dir           : dir
     * @param  {std::string} model : 评分方向( 默认为1,参数范围:{-1,1} )
     * @return {double}            : dir > 0 ? [0.0 ～ 1.0] : [1.0 ～ 0]
     */
    double PosToPosDirGrade(double x, double y, double x1, double y1, double peak_pos, int dir)
    {

        CGeoPoint point1(x, y);
        CGeoPoint point2(x1, y1);
        double grade_dir = abs((point1 - point2).dir() * PARAM::Math::RADIAN);
        grade_dir = NumberNormalizeGauss(grade_dir, PARAM::Math::RADIAN * PARAM::Math::PI, 0, peak_pos);
        grade_dir = dir > 0 ? grade_dir : (1 - grade_dir);
        return grade_dir;
    }

    double PosToPosDirGrade(double x, double y, double x1, double y1, int dir)
    {

        CGeoPoint point1(x, y);
        CGeoPoint point2(x1, y1);
        double grade_dir = abs((point1 - point2).dir() * PARAM::Math::RADIAN);
        grade_dir = NumberNormalize(grade_dir, PARAM::Math::RADIAN * PARAM::Math::PI, 0);
        grade_dir = dir > 0 ? grade_dir : (1 - grade_dir);
        return grade_dir;
    }

    double RobotToPosDirGrade(const CVisionModule *pVision, int num, CGeoPoint start, CGeoPoint end)
    {
        CGeoSegment new_segment(start, end);
        double robot_dir = PARAM::Math::RADIAN * pVision->ourPlayer(num).Dir();
        double target_dir = PARAM::Math::RADIAN * (end - start).dir();
        double grade = 1 - NumberNormalize(abs(robot_dir - target_dir), 180, 0);
        return grade;
    }
    /**
     * 坐标到球之间的距离评分
     * @param  {CVisionModule*} pVision :pVision
     * @param  {double} x               : x
     * @param  {double} y               : y
     * @param  {int} dir                : 评分方向( 默认为1,参数范围:{-1,1} )
     * @param  {std::string} model      :（GAUSS：可设峰值（peak_pos），NORMAL：越近分数越高）
     * @return {double}                 : dir > 0 ? [0.0 ～ 1.0] : [1.0 ～ 0]
     */
    double PosToBallDistGrade(CGeoPoint ball_pos, double x, double y, double peak_pos, int dir)
    {
        // PARAM::Field::PITCH_LENGTH / 3.8;
        CGeoPoint pos(x, y);
        double max_data = PARAM::Field::PITCH_LENGTH / 1.4;
        double min_data = 0;
        double distance = (pos - ball_pos).mod();
        double grade = NumberNormalizeGauss(distance, max_data, min_data, peak_pos);
        grade = dir > 0 ? grade : (1 - grade);
        if (distance > PARAM::Field::PITCH_LENGTH / 1.4)
        {
            return 0.0;
        }

        return grade;
    }

    double PosToBallDistGrade(CGeoPoint ball_pos, double x, double y, int dir)
    {
        CGeoPoint pos(x, y);
        double max_data = PARAM::Field::PITCH_LENGTH / 1.4;
        double min_data = 0;
        double distance = (pos - ball_pos).mod();
        double grade = NumberNormalize(distance, max_data, min_data);
        grade = dir > 0 ? grade : (1 - grade);
        if (distance > PARAM::Field::PITCH_LENGTH / 1.4)
        {
            return 0.0;
        }

        return grade;
    }
    /**
     * 坐标到球之间的距离评分
     * @param  {double} x          : x
     * @param  {double} y          : y
     * @param  {double} x1         : x1
     * @param  {double} y1         : y1
     * @param  {int} dir           : 评分方向( 默认为1,参数范围:{-1,1} )
     * @param  {std::string} model :（GAUSS：可设峰值（peak_pos），NORMAL：越近分数越高）
     * @return {double}            : dir > 0 ? [0.0 ～ 1.0] : [1.0 ～ 0]
     */
    double PosToPosDistGrade(double x, double y, double x1, double y1, int dir, std::string model)
    {
        std::string model_type[] = {"GAUSS", "NORMAL"};
        CGeoPoint pos(x, y);
        CGeoPoint pos1(x1, y1);
        double peak_pos = PARAM::Field::PITCH_LENGTH / 3.8;
        double max_data = (CGeoPoint(PARAM::Field::PITCH_LENGTH / 2, PARAM::Field::PITCH_WIDTH / 2) - CGeoPoint(-1 * PARAM::Field::PITCH_LENGTH / 2, -1 * PARAM::Field::PITCH_WIDTH / 2)).mod();
        double min_data = 0;
        double distance = (pos - pos1).mod();
        double grade = model == model_type[0] ? NumberNormalizeGauss(distance, max_data, min_data, peak_pos) : NumberNormalize(distance, max_data, min_data);
        if (distance > PARAM::Field::PITCH_LENGTH / 1.4)
        {
            return 0.0;
        }
        grade = dir > 0 ? grade : (1 - grade);
        return grade;
    }

    /**
     * 高斯归一化
     * @param  {double} data       :待归一化数据
     * @param  {double} max_data   :待归一化数据最大值
     * @param  {double} min_data   :待归一化数据最小值
     * @param  {double} peak_pos   :峰值
     * @param  {std::string} model :SIN: 不可制定峰值，变化均匀、(max_data - min_data) / 2的时候是最大值。
     *                              GAUSS: 可指定峰值，变化比较突然，更服从正态分布。
     *                              DOUBLELINE：可指定峰值，变化均匀。
     * @return {double}            :[0,1]
     */
    double NumberNormalizeGauss(double data, double max_data, double min_data, double peak_pos, std::string model)
    {

        /* modle :
            SIN: 不可制定峰值，变化均匀、(max_data - min_data) / 2的时候是最大值。
            GAUSS: 可指定峰值，变化比较突然，更服从正态分布。
            DOUBLELINE：可指定峰值，变化均匀。
        */

        string modle_type[3] = {
            "SIN",
            "GAUSS",
            "DOUBLELINE"};
        if (model == modle_type[0])
        {
            double normalized_data = NumberNormalize(data, max_data, min_data); // 将数据变换到[0,1]
            return sin(normalized_data);
        }
        else if (model == modle_type[1])
        {
            double sigma = (max_data - min_data) / 8;
            double mu = peak_pos;
            double normalized_data = exp(-pow((data - mu), 2) / (2 * pow(sigma, 2)));
            return normalized_data;
        }
        else
        {
            double normalized_data = NumberNormalize(data, max_data, min_data);
            double rel_peak_pos = NumberNormalize(peak_pos, max_data, min_data);
            CGeoLine befor_line(CGeoPoint(0, 0), CGeoPoint(rel_peak_pos, 1));
            CGeoLine after_line(CGeoPoint(rel_peak_pos, 1), CGeoPoint(1, 0));
            double double_line_vaule = 0.0;
            if (data < peak_pos)
            {
                double_line_vaule = -1 * (befor_line.a() * normalized_data + befor_line.c()) / befor_line.b();
            }
            else
            {
                double_line_vaule = -1 * (after_line.a() * normalized_data + after_line.c()) / after_line.b();
            }
            return double_line_vaule;
        }
    }

    // 返回两个dir的差
    double angleDiff(double angle1, double angle2)
    {
        return std::atan2(std::sin(angle2 - angle1), std::cos(angle2 - angle1));
    }
    /**
     * 归一化
     * @param  {double} data       :待归一化数据
     * @param  {double} max_data   :待归一化数据最大值
     * @param  {double} min_data   :待归一化数据最小值
     * @return {double}            :[0,1]
     */
    double NumberNormalize(double data, double max_data, double min_data)
    {
        double res = (data - min_data) / (max_data - min_data);
        if (res > 1)
            res = 1;
        if (res < 0)
            res = 0;
        return res;
    }

    /**
     * 映射
     * @param  {double} value   :待映射值
     * @param  {double} min_in  :待映射最小值
     * @param  {double} max_in  :待映射最大值
     * @param  {double} min_out :映射后最小值
     * @param  {double} max_out :映射后最大值
     * @return {double}         :
     */
    double map(double value, double min_in, double max_in, double min_out, double max_out)
    {
        return min_out + (max_out - min_out) * (value - min_in) / (max_in - min_in);
    }

    /**
     * 判断是否在敌方禁区
     * @param  {CGeoPoint} Point : 要判断的点
     * @param  {double} buffer   : TODO:
     * @param  {string} dir      :
     * @return {bool}            : 是否在敌方禁区
     */
    bool InExclusionZone(CGeoPoint Point, double buffer, string dir)
    {
        double x = Point.x();
        double y = Point.y();
        if (dir == "our")
        {
            return ((x < (-1 * PARAM::Field::PITCH_LENGTH / 2) + PARAM::Field::PENALTY_AREA_DEPTH + buffer) &&
                    (y > -1 * PARAM::Field::PENALTY_AREA_WIDTH / 2 - buffer && y < PARAM::Field::PENALTY_AREA_WIDTH / 2 + buffer));
        }
        else if (dir == "their")
        {
            return ((x > (PARAM::Field::PITCH_LENGTH / 2) - PARAM::Field::PENALTY_AREA_DEPTH - buffer) &&
                    (y > -1 * PARAM::Field::PENALTY_AREA_WIDTH / 2 - buffer && y < PARAM::Field::PENALTY_AREA_WIDTH / 2 + buffer));
        }
        else
        {
            return (((x < (-1 * PARAM::Field::PITCH_LENGTH / 2) + PARAM::Field::PENALTY_AREA_DEPTH + buffer) ||
                     (x > (PARAM::Field::PITCH_LENGTH / 2) - PARAM::Field::PENALTY_AREA_DEPTH - buffer)) &&
                    (y > -1 * PARAM::Field::PENALTY_AREA_WIDTH / 2 - buffer && y < PARAM::Field::PENALTY_AREA_WIDTH / 2 + buffer));
        }
    }

    /**
     * TODO:
     * @param  {CVisionModule*} pVision :
     * @param  {CGeoPoint} player_pos   :
     * @return {int}                    :
     */
    int GetPointToMinDistEnemyNum(const CVisionModule *pVision, CGeoPoint player_pos)
    {
    }

    /**
     * 判断是否在场地内
     * @param  {CGeoPoint} Point : 要判断的点
     * @return {bool}            : 是否在场地内
     */
    bool InField(CGeoPoint Point)
    {
        double x = Point.x();
        double y = Point.y();
        return ((x > (-1 * PARAM::Field::PITCH_LENGTH / 2) && x < (PARAM::Field::PITCH_LENGTH / 2)) &&
                (y > -1 * PARAM::Field::PITCH_WIDTH / 2 && y < PARAM::Field::PITCH_WIDTH / 2));
    }

    /**
     * 判断球是否在我方半场
     * @param  {CGeoPoint} Point : 要判断的点
     * @return {bool}            : 是否在我方半场
     */
    bool InOurField(CGeoPoint Point)
    {
        double x = Point.x();
        double y = Point.y();
        return ((x > (-1 * PARAM::Field::PITCH_LENGTH / 2) && x < 0) &&
                (y > -1 * PARAM::Field::PITCH_WIDTH / 2 && y < PARAM::Field::PITCH_WIDTH / 2));
    }

    /**
     * 据给定机器人位置，求出偏转方向：哪边地方机器少多往哪边
     * @param  {CVisionModule*} pVision : 视觉模块
     * @param  {int} role               : 目标我方球员编号
     * @param  {double} angle           : 机器人朝向
     * @return {bool}                   : 返回 False = 偏向左边；True = 偏向右边
     */
    // bool CheckSideToTurn(const CVisionModule *pVision, int role, double angle, int type) // NOTE: 如果需要任意的类型再加一个type
    bool CheckSideToTurn(const CVisionModule *pVision, int role, double angle)
    {
        int left = 0;
        int right = 0;

        // 我方球员的位置、方向、射线
        CGeoPoint pos = pVision->ourPlayer(role).Pos();
        double dir = pVision->ourPlayer(role).Dir();
        CGeoLine line(pos, dir);

        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (role == i || role == Tick[now].our.goalie_num || role == Tick[now].their.goalie_num) // 排除自身和守门员
            {
                continue;
            }

            // double anoDir;
            // if (0 == type || 1 == type) // 计算我方
            // {
            //     andDir = CGeoLine(pos, pVision->ourPlayer(i).Pos());
            // }
            // else if (0 == type || 2 == type) // 计算敌方
            // {
            //     anoDir = atan2(pVision->theirPlayer(i).Pos().y - pos.y, pVision->theirPlayer(i).Pos().x - pos.x) * (180.0 / M_PI);
            // }
            double anoDir = atan2(pVision->theirPlayer(i).Y() - pos.y(), pVision->theirPlayer(i).X() - pos.x()) * (180.0 / M_PI);
            dir - anoDir < 0 ? left++ : right++;
        }

        return left > right;
    }

    // Defender

    /**
     * 距离某球员最近的球员
     * @param  {CVisionModule*} pVision : vision
     * @param  {int} role               : 目标球员
     * @param  {int} type               : 类型 0全局 1我方 2敌方
     * @return {int}                    : 球员编号
     */
    int ClosestPlayerToPlayer(const CVisionModule *pVision, int role, int type)
    {
        int res[3] = {-1, -1, -1};
        double minDis[3] = {inf, inf, inf};

        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (role == i || role == Tick[now].our.goalie_num || role == Tick[now].their.goalie_num)
            {
                continue;
            }

            if (pVision->ourPlayer(i).Valid())
            {
                double dist = pVision->ourPlayer(i).Pos().dist(pVision->ourPlayer(role).Pos());
                if (dist < minDis[1])
                {
                    res[1] = i;
                    minDis[1] = dist;
                }
                if (dist < minDis[0])
                {
                    res[0] = i;
                    minDis[0] = dist;
                }
            }
            else if (pVision->theirPlayer(i).Valid())
            {
                double dist = pVision->theirPlayer(i).Pos().dist(pVision->ourPlayer(role).Pos());
                if (dist < minDis[2])
                {
                    res[2] = i;
                    minDis[2] = dist;
                }
                if (dist < minDis[0])
                {
                    res[0] = i;
                    minDis[0] = dist;
                }
            }
        }

        return res[type];
    }

    /**
     * 距离某点最近的球员
     * @param  {CVisionModule*} pVision : vision
     * @param  {CGeoPoint} pos          : 目标位置
     * @param  {int} type               : 类型 0全局 1我方 2敌方
     * @param  {int} role = 1           : （可选）排除的球员编号
     * @return {int}                    : 球员编号
     */
    int ClosestPlayerNoToPoint(const CVisionModule *pVision, CGeoPoint pos, int type, int role)
    {
        int res[3] = {-1, -1, -1};
        double minDis[3] = {inf, inf, inf};

        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (i == role || i == Tick[now].our.goalie_num || i == Tick[now].their.goalie_num) // 实际上也排除了守门员
            {
                continue;
            }

            if (pVision->ourPlayer(i).Valid())
            {
                double dist = pVision->ourPlayer(i).Pos().dist(pos);
                if (dist < minDis[1])
                {
                    res[1] = i;
                    minDis[1] = dist;
                }
                if (dist < minDis[0])
                {
                    res[0] = i;
                    minDis[0] = dist;
                }
            }
            else if (pVision->theirPlayer(i).Valid())
            {
                double dist = pVision->theirPlayer(i).Pos().dist(pos);
                if (dist < minDis[2])
                {
                    res[2] = i;
                    minDis[2] = dist;
                }
                if (dist < minDis[0])
                {
                    res[0] = i;
                    minDis[0] = dist;
                }
            }
        }

        return res[type];
    }

    /**
     * 距离某点最近的球员的位置
     * @param  {CVisionModule*} pVision : vision
     * @param  {CGeoPoint} pos          : 目标位置
     * @param  {int} type               : 类型 0全局 1我方 2敌方
     * @param  {int} role = 1           : （可选）排除的球员编号
     * @return {CGeoPoint}               : 球员位置
     */
    CGeoPoint ClosestPlayerToPoint(const CVisionModule *pVision, CGeoPoint pos, int type, int role)
    {
        int res[3] = {-1, -1, -1};
        double minDis[3] = {inf, inf, inf};

        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (i == role || i == Tick[now].our.goalie_num || i == Tick[now].their.goalie_num) // 实际上也排除了守门员
            {
                continue;
            }

            if (pVision->ourPlayer(i).Valid())
            {
                double dist = pVision->ourPlayer(i).Pos().dist(pos);
                if (dist < minDis[1])
                {
                    res[1] = i;
                    minDis[1] = dist;
                }
                if (dist < minDis[0])
                {
                    res[0] = i;
                    minDis[0] = dist;
                }
            }
            else if (pVision->theirPlayer(i).Valid())
            {
                double dist = pVision->theirPlayer(i).Pos().dist(pos);
                if (dist < minDis[2])
                {
                    res[2] = i;
                    minDis[2] = dist;
                }
                if (dist < minDis[0])
                {
                    res[0] = i;
                    minDis[0] = dist;
                }
            }
        }

        // return res[type];
        return pVision->theirPlayer(res[type]).Pos();
    }

    /**
     * 球方向与禁区边的交点
     * @param  {CVisionModule*} pVision : 视觉模块
     * @param  {CGeoLine} line          : 球的运动方向
     * @return {CGeoPoint}              : 交点；(0, 0) 时表示无交点
     */
    CGeoPoint DEFENDER_ComputeCrossPenalty(const CVisionModule *pVision, CGeoLine line)
    {
        CGeoLineLineIntersection intersection(DEFENDER_FIELD_PENALTYBOR, line); // 获取球运动姿态的交点
        return intersection.Intersectant() ? intersection.IntersectPoint() : CGeoPoint(0, 0);
    }

    /**
     * 根据球的位置动态调整后卫间距离
     * @param  {CGeoPoint} hitPoint : 交点
     * @return {double}             : 两后卫之间距离
     */
    double DEFENDER_ComputeDistance(CGeoPoint hitPoint)
    {
        double ballDist = Tick[now].ball.pos.dist(hitPoint);
        if (ballDist > PARAM::Field::PITCH_WIDTH / 2)
        {
            return DEFAULT_DISTANCE_MAX;
        }
        else if (ballDist < PARAM::Field::PENALTY_AREA_DEPTH)
        {
            return DEFAULT_DISTANCE_MIN;
        }
        else
        {
            return DEFAULT_DISTANCE_MIN + (DEFAULT_DISTANCE_MAX - DEFAULT_DISTANCE_MIN) * (ballDist / (PARAM::Field::PITCH_WIDTH / 2 - PARAM::Field::PENALTY_AREA_DEPTH));
        }
    }

    /*****************************
     *                           *
     *         以下代码均是       *
     *         该文件源代码       *
     *       Open-ssl-china      *
     *****************************/

    double dirDiff(const CVector &v1, const CVector &v2)
    {
        return fabs(Normalize(v1.dir() - v2.dir()));
    }
    double Normalize(double angle)
    {
        if (fabs(angle) > 10)
        {
            cout << angle << " Normalize Error!!!!!!!!!!!!!!!!!!!!" << endl;
            return 0;
        }
        static const double M_2PI = PARAM::Math::PI * 2;
        // 快速粗调整
        angle -= (int)(angle / M_2PI) * M_2PI;

        // 细调整 (-PI,PI]
        while (angle > PARAM::Math::PI)
        {
            angle -= M_2PI;
        }

        while (angle <= -PARAM::Math::PI)
        {
            angle += M_2PI;
        }

        return angle;
    }

    CVector Polar2Vector(double m, double angle)
    {
        return CVector(m * std::cos(angle), m * std::sin(angle));
    }

    double VectorDot(const CVector &v1, const CVector &v2)
    {
        return v1.x() * v2.x() + v1.y() * v2.y();
    }

    bool InBetween(const CGeoPoint &p, const CGeoPoint &p1, const CGeoPoint &p2)
    {
        return p.x() >= (std::min)(p1.x(), p2.x()) && p.x() <= (std::max)(p1.x(), p2.x()) && p.y() >= (std::min)(p1.y(), p2.y()) && p.y() <= (std::max)(p1.y(), p2.y());
    }

    bool InBetween(double v, double v1, double v2)
    {
        return (v > v1 && v < v2) || (v < v1 && v > v2);
    }

    bool InBetween(const CVector &v, const CVector &v1, const CVector &v2, double buffer)
    {

        double d = v.dir(), d1 = v1.dir(), d2 = v2.dir();
        return AngleBetween(d, d1, d2, buffer);
    }

    bool AngleBetween(double d, double d1, double d2, double buffer)
    {
        using namespace PARAM::Math;
        // d, d1, d2为向量v, v1, v2的方向弧度

        // 当v和v1或v2的角度相差很小,在buffer允许范围之内时,认为满足条件
        double error = (std::min)(std::fabs(Normalize(d - d1)), std::fabs(Normalize(d - d2)));
        if (error < buffer)
        {
            return true;
        }

        if (std::fabs(d1 - d2) < PI)
        {
            // 当直接相减绝对值小于PI时, d应该大于小的,小于大的
            return InBetween(d, d1, d2);
        }
        else
        {
            // 化为上面那种情况
            return InBetween(Normalize(d + PI), Normalize(d1 + PI), Normalize(d2 + PI));
        }
    }

    CGeoPoint MakeInField(const CGeoPoint &p, const double buffer)
    {
        auto new_p = p;
        if (new_p.x() < buffer - PARAM::Field::PITCH_LENGTH / 2)
            new_p.setX(buffer - PARAM::Field::PITCH_LENGTH / 2);
        if (new_p.x() > PARAM::Field::PITCH_LENGTH / 2 - buffer)
            new_p.setX(PARAM::Field::PITCH_LENGTH / 2 - buffer);
        if (new_p.y() < buffer - PARAM::Field::PITCH_WIDTH / 2)
            new_p.setY(buffer - PARAM::Field::PITCH_WIDTH / 2);
        if (new_p.y() > PARAM::Field::PITCH_WIDTH / 2 - buffer)
            new_p.setY(PARAM::Field::PITCH_WIDTH / 2 - buffer);
        return new_p;
    }

    // modified by Wang in 2018/3/17
    bool InOurPenaltyArea(const CGeoPoint &p, const double buffer)
    {
        // rectangle penalty
        return (p.x() < -PARAM::Field::PITCH_LENGTH / 2 +
                            PARAM::Field::PENALTY_AREA_DEPTH + buffer &&
                std::fabs(p.y()) <
                    PARAM::Field::PENALTY_AREA_WIDTH / 2 + buffer);
    }

    bool InTheirPenaltyArea(const CGeoPoint &p, const double buffer)
    {
        // rectanlge penalty
        return (p.x() >
                    PARAM::Field::PITCH_LENGTH / 2 -
                        PARAM::Field::PENALTY_AREA_DEPTH - buffer &&
                std::fabs(p.y()) <
                    PARAM::Field::PENALTY_AREA_WIDTH / 2 + buffer);
    }

    bool InTheirPenaltyAreaWithVel(const PlayerVisionT &me, const double buffer)
    {
        CVector vel = me.Vel();
        CGeoPoint pos = me.Pos();
        //        GDebugEngine::Instance()->gui_debug_x(pos + Polar2Vector(pow(vel.mod(), 2) / (2 * 400), vel.dir()));
        if (me.Vel().mod() < 30)
            return InTheirPenaltyArea(me.Pos(), buffer);
        if (InTheirPenaltyArea(pos + Polar2Vector(pow(vel.mod(), 2) / (2 * 400), vel.dir()), buffer))
        {
            return true;
        }
        else
            return false;
    }

    bool IsInField(const CGeoPoint p, double buffer)
    {
        return (p.x() > buffer - PARAM::Field::PITCH_LENGTH / 2 && p.x() < PARAM::Field::PITCH_LENGTH / 2 - buffer &&
                p.y() > buffer - PARAM::Field::PITCH_WIDTH / 2 && p.y() < PARAM::Field::PITCH_WIDTH / 2 - buffer);
    }

    bool IsInFieldV2(const CGeoPoint p, double buffer)
    {
        return (IsInField(p, buffer) && !Utils::InOurPenaltyArea(p, buffer) && !Utils::InTheirPenaltyArea(p, buffer));
    }

    // modified by Wang in 2018/3/21
    CGeoPoint MakeOutOfOurPenaltyArea(const CGeoPoint &p, const double buffer)
    {
        if (WorldModel::Instance()->CurrentRefereeMsg() == "OurBallPlacement")
            return p;
        // rectangle penalty
        // 右半禁区点
        if (p.y() > 0)
        {
            // 距离禁区上边近，取上边投影
            if (-PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PENALTY_AREA_DEPTH - p.x() < PARAM::Field::PENALTY_AREA_WIDTH / 2 - p.y())
                return CGeoPoint(-PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PENALTY_AREA_DEPTH + buffer, p.y());
            // 距离禁区右边近，取右边投影
            else
                return CGeoPoint(p.x(), PARAM::Field::PENALTY_AREA_WIDTH / 2 + buffer);
        }
        // 左半禁区点
        else
        {
            // 距离禁区上边近，取上边投影
            if (-PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PENALTY_AREA_DEPTH - p.x() < p.y() - (-PARAM::Field::PENALTY_AREA_WIDTH / 2))
                return CGeoPoint(-PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PENALTY_AREA_DEPTH + buffer, p.y());
            // 距离禁区左边近，取左边投影
            else
                return CGeoPoint(p.x(), -PARAM::Field::PENALTY_AREA_WIDTH / 2 - buffer);
        }
    }

    // modified by Wang in 2018/3/17
    CGeoPoint MakeOutOfTheirPenaltyArea(const CGeoPoint &p, const double buffer, const double dir)
    {
        // rectangle penalty
        if (WorldModel::Instance()->CurrentRefereeMsg() == "OurBallPlacement")
            return p;
        CGeoPoint newPoint = p;
        if (fabs(dir) < 1e4)
        {
            double normDir = Utils::Normalize(dir);
            double adjustStep = 2.0;
            CVector adjustVec = Polar2Vector(adjustStep, normDir);
            newPoint = newPoint + adjustVec;
            while (InTheirPenaltyArea(newPoint, buffer) && newPoint.x() < PARAM::Field::PITCH_LENGTH / 2)
                newPoint = newPoint + adjustVec;
            if (newPoint.x() > PARAM::Field::PITCH_LENGTH / 2)
                newPoint.setX(PARAM::Field::PITCH_LENGTH / 2);
            if (fabs(newPoint.y()) > PARAM::Field::PENALTY_AREA_WIDTH / 2 ||
                (fabs(newPoint.y()) < PARAM::Field::PENALTY_AREA_WIDTH / 2 && fabs(newPoint.x()) < PARAM::Field::PITCH_LENGTH / 2 - PARAM::Field::PENALTY_AREA_DEPTH))
                return newPoint;
        }

        newPoint = p;
        if (newPoint.x() > PARAM::Field::PITCH_LENGTH / 2)
            newPoint.setX(200);
        // 右半禁区点
        if (newPoint.y() > 0)
        {
            // 距离禁区下边近，取下边投影
            if (newPoint.x() - PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PENALTY_AREA_DEPTH < PARAM::Field::PENALTY_AREA_WIDTH / 2 - newPoint.y())
                return CGeoPoint(PARAM::Field::PITCH_LENGTH / 2 - PARAM::Field::PENALTY_AREA_DEPTH - buffer, newPoint.y());
            // 距离禁区右边近，取右边投影
            else
                return CGeoPoint(newPoint.x(), PARAM::Field::PENALTY_AREA_WIDTH / 2 + buffer);
        }
        // 左半禁区点
        else
        {
            // 距离禁区下边近，取下边投影
            if (newPoint.x() - PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PENALTY_AREA_DEPTH < PARAM::Field::PENALTY_AREA_WIDTH / 2 + newPoint.y())
                return CGeoPoint(PARAM::Field::PITCH_LENGTH / 2 - PARAM::Field::PENALTY_AREA_DEPTH - buffer, newPoint.y());
            // 距离禁区左边近，取左边投影
            else
                return CGeoPoint(newPoint.x(), -PARAM::Field::PENALTY_AREA_WIDTH / 2 - buffer);
        }
    }

    CGeoPoint MakeOutOfCircle(const CGeoPoint &center, const double radius, const CGeoPoint &target, const double buffer, const bool isBack, const CGeoPoint &mePos, const CVector adjustVec)
    {
        CGeoPoint p(target);
        CVector adjustDir;
        if (isBack)
        {
            adjustDir = mePos - target;
        }
        else if (adjustVec.x() < 1e4)
            adjustDir = adjustVec;
        else
        {
            adjustDir = target - center;
            if (adjustDir.mod() < PARAM::Vehicle::V2::PLAYER_SIZE / 2.0)
                adjustDir = mePos - target;
        }

        adjustDir = adjustDir / adjustDir.mod();
        double adjustUnit = 0.5;
        while (p.dist(center) < radius + buffer)
            p = p + adjustDir * adjustUnit;
        return p;
    }

    CGeoPoint MakeOutOfLongCircle(const CGeoPoint &seg_start, const CGeoPoint &seg_end, const double radius, const CGeoPoint &target, const double buffer, const CVector adjustVec)
    {
        CGeoSegment segment(seg_start, seg_end);
        CGeoPoint p(target);
        CGeoPoint nearPoint = (seg_start.dist(target) < seg_end.dist(target) ? seg_start : seg_end);
        CVector adjustDir = target - nearPoint;
        if (adjustDir.x() < 1e4)
            adjustDir = adjustVec;
        adjustDir = adjustDir / adjustDir.mod();
        double adjustUnit = 0.5;
        while (segment.dist2Point(p) < radius + buffer)
            p = p + adjustDir * adjustUnit;
        return p;
    }

    // 针对门柱
    CGeoPoint MakeOutOfRectangle(const CGeoPoint &recP1, const CGeoPoint &recP2, const CGeoPoint &target, const double buffer)
    {
        double leftBound = min(recP1.x(), recP2.x());
        double rightBound = max(recP1.x(), recP2.x());
        double upperBound = max(recP1.y(), recP2.y());
        double lowerBound = min(recP1.y(), recP2.y());
        double middleY = (upperBound + lowerBound) / 2.0;
        double middleX = (leftBound + rightBound) / 2.0;

        CGeoPoint targetNew = target;
        if (targetNew.y() < upperBound + buffer &&
            targetNew.y() > lowerBound - buffer &&
            targetNew.x() > leftBound - buffer &&
            targetNew.x() < rightBound + buffer)
        {
            if (fabs(middleX) < PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::GOAL_DEPTH * 2.0 / 3.0)
            { // 边门柱
                double xInside = copysign(min(fabs(leftBound), fabs(rightBound)), leftBound);
                double yInside = copysign(min(fabs(upperBound), fabs(lowerBound)), lowerBound);
                double yOutside = copysign(max(fabs(upperBound), fabs(lowerBound)), lowerBound);
                if (fabs(targetNew.x()) < fabs(xInside))
                {
                    targetNew.setX(xInside - copysign(buffer, xInside));
                }
                else if (fabs(targetNew.y()) < fabs(yInside))
                {
                    targetNew.setY(yInside - copysign(buffer, yInside));
                }
                else if (fabs(targetNew.y()) > fabs(yOutside))
                {
                    targetNew.setY(yInside + copysign(buffer, yOutside));
                }
                else if (fabs(targetNew.y()) < fabs(middleY))
                { // 后面两种只针对虚拟门柱和仿真，实际不会出现
                    targetNew.setY(yInside - copysign(buffer, yInside));
                }
                else
                {
                    targetNew.setY(yInside + copysign(buffer, yOutside));
                }
            }
            else
            { // 后门柱
                double xInside = copysign(min(fabs(leftBound), fabs(rightBound)), leftBound);
                if (fabs(targetNew.x()) < fabs(xInside))
                {
                    targetNew.setX(xInside - copysign(buffer, xInside));
                }
                else if (targetNew.y() < lowerBound)
                {
                    targetNew.setY(lowerBound - buffer);
                }
                else if (targetNew.y() > upperBound)
                {
                    targetNew.setY(upperBound + buffer);
                }
                else if (targetNew.y() < 0)
                { // 后面两种只针对虚拟门柱和仿真，实际不会出现
                    targetNew.setY(lowerBound - buffer);
                }
                else
                {
                    targetNew.setY(upperBound + buffer);
                }
            }
        }

        return targetNew;
    }

    CGeoPoint MakeOutOfCircleAndInField(const CGeoPoint &center, const double radius, const CGeoPoint &p, const double buffer)
    {
        const CVector p2c = p - center;
        const double dist = p2c.mod();
        if (dist > radius + buffer || dist < 0.01)
        { // 不在圆内
            return p;
        }
        CGeoPoint newPos(center + p2c * (radius + buffer) / dist);
        CGeoRectangle fieldRect(FieldLeft() + buffer, FieldTop() + buffer, FieldRight() - buffer, FieldBottom() - buffer);
        if (!fieldRect.HasPoint(newPos))
        { // 在场外,选择距离最近且不在圆内的场内点
            CGeoCirlce avoidCircle(center, radius + buffer);
            std::vector<CGeoPoint> intPoints;
            for (int i = 0; i < 4; ++i)
            {
                CGeoLine fieldLine(fieldRect._point[i % 4], fieldRect._point[(i + 1) % 4]);
                CGeoLineCircleIntersection fieldLineCircleInt(fieldLine, avoidCircle);
                if (fieldLineCircleInt.intersectant())
                {
                    intPoints.push_back(fieldLineCircleInt.point1());
                    intPoints.push_back(fieldLineCircleInt.point2());
                }
            }
            double minDist = 1000.0;
            CGeoPoint minPoint = newPos;
            for (unsigned int i = 0; i < intPoints.size(); ++i)
            {
                double cDist = p.dist(intPoints[i]);
                if (cDist < minDist)
                {
                    minDist = cDist;
                    minPoint = intPoints[i];
                }
            }
            return minPoint;
        }

        return newPos; // 圆外距离p最近的点
    }

    bool PlayerNumValid(int num)
    {
        if (num >= 0 && num < PARAM::Field::MAX_PLAYER)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    // 给定一个球门线上的点, 一个方向(角度), 找出一个在禁区外防守该方向的
    // 离禁区线较近的点
    CGeoPoint GetOutSidePenaltyPos(double dir, double delta, const CGeoPoint targetPoint)
    {
        // double delta = PARAM::Field::MAX_PLAYER_SIZE + 1.5;
        CGeoPoint pInter = GetInterPos(dir, targetPoint);
        CGeoPoint pDefend = pInter + Polar2Vector(delta, dir);
        return pDefend;
    }

    CGeoPoint GetOutTheirSidePenaltyPos(double dir, double delta, const CGeoPoint &targetPoint)
    {
        CGeoPoint pInter = GetTheirInterPos(dir, targetPoint);
        return (pInter + Polar2Vector(delta, dir));
    }

    CGeoPoint GetInterPos(double dir, const CGeoPoint targetPoint)
    {
        using namespace PARAM::Field;
        // rectangle penalty
        CGeoPoint p1(-PITCH_LENGTH / 2, -PENALTY_AREA_WIDTH / 2);                      // 禁区左下
        CGeoPoint p2(-PITCH_LENGTH / 2 + PENALTY_AREA_DEPTH, -PENALTY_AREA_WIDTH / 2); // 禁区左上
        CGeoPoint p3(-PITCH_LENGTH / 2 + PENALTY_AREA_DEPTH, PENALTY_AREA_WIDTH / 2);  // 禁区右上
        CGeoPoint p4(-PITCH_LENGTH / 2, PENALTY_AREA_WIDTH / 2);                       // 禁区右下
        CGeoLine line1(p1, p2);                                                        // 禁区左边线
        CGeoLine line2(p2, p3);                                                        // 禁区前边线
        CGeoLine line3(p3, p4);                                                        // 禁区右边线
        CGeoLine dirLine(targetPoint, dir);

        CGeoLineLineIntersection inter1(line1, dirLine);
        CGeoLineLineIntersection inter2(line2, dirLine);
        CGeoLineLineIntersection inter3(line3, dirLine);

        CGeoPoint inter_p1 = inter1.IntersectPoint();
        GDebugEngine::Instance()->gui_debug_x(inter_p1, 3); // 黄
        CGeoPoint inter_p2 = inter2.IntersectPoint();
        GDebugEngine::Instance()->gui_debug_x(inter_p2, 4); // 绿
        CGeoPoint inter_p3 = inter3.IntersectPoint();
        GDebugEngine::Instance()->gui_debug_x(inter_p3, 9); // 黑
        CGeoPoint returnPoint = targetPoint;                // 返回值

        // if (targetPoint.x() >= -PITCH_LENGTH / 2 + PENALTY_AREA_DEPTH) {
        if (targetPoint.y() <= 0)
        { // case 1
            if (InOurPenaltyArea(inter_p1, 10))
                returnPoint = inter_p1;
            else
                returnPoint = inter_p2;
        }
        else
        { // case 2
            if (InOurPenaltyArea(inter_p3, 10))
                returnPoint = inter_p3;
            else
                returnPoint = inter_p2; // 随便选的
        }
        GDebugEngine::Instance()->gui_debug_x(returnPoint, 0);
        CGeoPoint p0(-PITCH_LENGTH / 2, 0);
        GDebugEngine::Instance()->gui_debug_line(returnPoint, p0, 0);
        return returnPoint;
    }
    CGeoPoint GetTheirInterPos(double dir, const CGeoPoint &targetPoint)
    {
        using namespace PARAM::Field;
        // rectangle penalty
        CGeoPoint p1(PITCH_LENGTH / 2, -PENALTY_AREA_WIDTH / 2);                      // 禁区左上
        CGeoPoint p2(PITCH_LENGTH / 2 - PENALTY_AREA_DEPTH, -PENALTY_AREA_WIDTH / 2); // 禁区左下
        CGeoPoint p3(PITCH_LENGTH / 2 - PENALTY_AREA_DEPTH, PENALTY_AREA_WIDTH / 2);  // 禁区右下
        CGeoPoint p4(PITCH_LENGTH / 2, PENALTY_AREA_WIDTH / 2);                       // 禁区右上
        CGeoLine line1(p1, p2);                                                       // 禁区左边线
        CGeoLine line2(p2, p3);                                                       // 禁区下边线
        CGeoLine line3(p3, p4);                                                       // 禁区右边线
        CGeoLine dirLine(targetPoint, dir);

        CGeoLineLineIntersection inter1(line1, dirLine);
        CGeoLineLineIntersection inter2(line2, dirLine);
        CGeoLineLineIntersection inter3(line3, dirLine);

        CGeoPoint inter_p1 = inter1.IntersectPoint();
        CGeoPoint inter_p2 = inter2.IntersectPoint();
        CGeoPoint inter_p3 = inter3.IntersectPoint();
        CGeoPoint returnPoint = targetPoint; // 返回值

        if (targetPoint.x() >= PITCH_LENGTH / 2 - PENALTY_AREA_DEPTH)
        {
            if (targetPoint.y() <= 0)
            { // case 1
                if (InOurPenaltyArea(inter_p1, 0))
                    return inter_p1;
                else
                    return p2; // 随便选的
            }
            else
            { // case 2
                if (InOurPenaltyArea(inter_p3, 0))
                    return inter_p3;
                else
                    return p3; // 随便选的
            }
        }
        else if (std::fabs(targetPoint.y()) <= PENALTY_AREA_WIDTH / 2)
        { // case 3
            if (InOurPenaltyArea(inter_p2, 0))
                return inter_p2;
            else
                return p2; // 随便选的
        }
        else
        {
            if (targetPoint.y() <= 0)
            { // case 4
                if (InOurPenaltyArea(inter_p1, 0))
                    return inter_p1;
                else if (InOurPenaltyArea(inter_p2, 0))
                    return inter_p2;
                else
                    return p2; // 随便选的
            }
            else
            { // case 5
                if (InOurPenaltyArea(inter_p2, 0))
                    return inter_p2;
                else if (InOurPenaltyArea(inter_p3, 0))
                    return inter_p3;
                else
                    return p3; // 随便选的
            }
        }
    }
    float SquareRootFloat(float number)
    {
        long i;
        float x, y;
        const float f = 1.5F;

        x = number * 0.5F;
        y = number;
        i = *(long *)&y;
        i = 0x5f3759df - (i >> 1);
        y = *(float *)&i;
        y = y * (f - (x * y * y));
        y = y * (f - (x * y * y));
        return number * y;
    }
    bool canGo(const CVisionModule *pVision, const int vecNumber, const CGeoPoint &target, const int flags, const double avoidBuffer) // 判断是否可以直接到达目标点
    {
        static bool _canGo = true;
        const CGeoPoint &vecPos = pVision->ourPlayer(vecNumber).Pos();
        CGeoSegment moving_seg(vecPos, target);
        const double minBlockDist2 = (PARAM::Field::MAX_PLAYER_SIZE / 2 + avoidBuffer) * (PARAM::Field::MAX_PLAYER_SIZE / 2 + avoidBuffer);
        for (int i = 0; i < PARAM::Field::MAX_PLAYER * 2; ++i)
        { // 看路线上有没有人
            if (i == vecNumber || !pVision->allPlayer(i).Valid())
            {
                continue;
            }
            const CGeoPoint &obs_pos = pVision->allPlayer(i).Pos();
            if ((obs_pos - target).mod2() < minBlockDist2)
            {
                _canGo = false;
                return _canGo;
            }
            CGeoPoint prj_point = moving_seg.projection(obs_pos);
            if (moving_seg.IsPointOnLineOnSegment(prj_point))
            {
                const double blockedDist2 = (obs_pos - prj_point).mod2();
                if (blockedDist2 < minBlockDist2 && blockedDist2 < (obs_pos - vecPos).mod2())
                {
                    _canGo = false;
                    return _canGo;
                }
            }
        }
        if (_canGo && (flags & PlayerStatus::DODGE_BALL))
        { // 躲避球
            const CGeoPoint &obs_pos = pVision->ball().Pos();
            CGeoPoint prj_point = moving_seg.projection(obs_pos);
            if (obs_pos.dist(prj_point) < avoidBuffer + PARAM::Field::BALL_SIZE && moving_seg.IsPointOnLineOnSegment(prj_point))
            {
                _canGo = false;
                return _canGo;
            }
        }
        if (_canGo && (flags & PlayerStatus::DODGE_OUR_DEFENSE_BOX))
        { // 避免进入本方禁区
            if (PARAM::Rule::Version == 2003)
            { // 2003年的规则禁区是矩形
                CGeoRectangle defenseBox(-PARAM::Field::PITCH_LENGTH / 2, -PARAM::Field::PENALTY_AREA_WIDTH / 2 - avoidBuffer, -PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PENALTY_AREA_WIDTH + avoidBuffer, PARAM::Field::PENALTY_AREA_WIDTH / 2 + avoidBuffer);
                CGeoLineRectangleIntersection intersection(moving_seg, defenseBox);
                if (intersection.intersectant())
                {
                    if (moving_seg.IsPointOnLineOnSegment(intersection.point1()) || moving_seg.IsPointOnLineOnSegment(intersection.point2()))
                    {
                        _canGo = false; // 要经过禁区
                        return _canGo;
                    }
                }
            }
            else if (PARAM::Rule::Version == 2004)
            { // 2004年的规则禁区是半圆形
                CGeoCirlce defenseBox(CGeoPoint(-PARAM::Field::PITCH_LENGTH / 2, 0), PARAM::Field::PENALTY_AREA_WIDTH / 2 + avoidBuffer);
                CGeoLineCircleIntersection intersection(moving_seg, defenseBox);
                if (intersection.intersectant())
                {
                    if (moving_seg.IsPointOnLineOnSegment(intersection.point1()) || moving_seg.IsPointOnLineOnSegment(intersection.point2()))
                    {
                        _canGo = false; // 要经过禁区
                        return _canGo;
                    }
                }
            }
            else
            { // 2018年的规则禁区是矩形
                CGeoRectangle defenseBox(-PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PENALTY_AREA_DEPTH + avoidBuffer, -PARAM::Field::PENALTY_AREA_WIDTH / 2 - avoidBuffer, -PARAM::Field::PITCH_LENGTH / 2, PARAM::Field::PENALTY_AREA_WIDTH / 2 + avoidBuffer);
                CGeoLineRectangleIntersection intersection(moving_seg, defenseBox);
                if (intersection.intersectant())
                {
                    if (moving_seg.IsPointOnLineOnSegment(intersection.point1()) || moving_seg.IsPointOnLineOnSegment(intersection.point2()))
                    {
                        _canGo = false; // 要经过禁区
                        return _canGo;
                    }
                }
            }
        }
        return _canGo;
    }

    // 判断能否传球的角度限制
    bool isValidFlatPass(const CVisionModule *pVision, CGeoPoint start, CGeoPoint end, bool isShoot, bool ignoreCloseEnemy, bool ignoreTheirGuard)
    {
        static const double CLOSE_ANGLE_LIMIT = 8 * PARAM::Math::PI / 180;
        static const double FAR_ANGLE_LIMIT = 12 * PARAM::Math::PI / 180;
        static const double CLOSE_THRESHOLD = 50;
        static const double THEIR_ROBOT_INTER_THREADHOLD = 30;
        static const double SAFE_DIST = 50;
        static const double CLOSE_ENEMY_DIST = 50;

        bool valid = true;
        // 使用平行线进行计算，解决近距离扇形计算不准问题
        CGeoSegment BallLine(start, end);
        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (!pVision->theirPlayer(i).Valid())
                continue;
            if (ignoreCloseEnemy && pVision->theirPlayer(i).Pos().dist(start) < CLOSE_ENEMY_DIST)
                continue;
            if (ignoreTheirGuard && Utils::InTheirPenaltyArea(pVision->theirPlayer(i).Pos(), 30))
                continue;
            CGeoPoint targetPos = pVision->theirPlayer(i).Pos();
            double dist = BallLine.dist2Point(targetPos);
            if (dist < THEIR_ROBOT_INTER_THREADHOLD)
            {
                valid = false;
                break;
            }
        }
        return valid;
    }

    // 判断能否传球的角度限制
    bool isValidChipPass(const CVisionModule *pVision, CGeoPoint start, CGeoPoint end)
    {
        static const double ANGLE_LIMIT = 5 * PARAM::Math::PI / 180;
        static const double CLOSE_SAFE_DIST = 50;
        static const double FAR_SAFE_DIST = 50;
        static const double FRONT_SAFE_DIST = 30;

        bool valid = true;
        // 使用扇形进行计算
        CVector passLine = end - start;
        double passDir = passLine.dir();
        for (int i = 0; i < PARAM::Field::MAX_PLAYER; ++i)
        {
            if (pVision->theirPlayer(i).Valid())
            {
                CGeoPoint enemyPos = pVision->theirPlayer(i).Pos();
                CVector enemyLine = enemyPos - start;
                double enemyDir = enemyLine.dir();
                // 计算敌方车与传球线路的差角
                double diffAngle = fabs(enemyDir - passDir);
                diffAngle = diffAngle > PARAM::Math::PI ? 2 * PARAM::Math::PI - diffAngle : diffAngle;
                // 计算补偿角
                double compensateAngle = fabs(atan2(PARAM::Vehicle::V2::PLAYER_SIZE + PARAM::Field::BALL_SIZE, start.dist(enemyPos)));
                //            qDebug() << "compensate angle: " << enemyPos.x() << enemyPos.y() << enemyDir << passDir << compensateAngle;
                if (diffAngle - compensateAngle < ANGLE_LIMIT && ((enemyPos.dist(start) < end.dist(start) + FAR_SAFE_DIST && enemyPos.dist(start) > end.dist(start) - CLOSE_SAFE_DIST) || enemyPos.dist(start) < FRONT_SAFE_DIST))
                {
                    valid = false;
                    break;
                }
            }
        }
        return valid;
    }
}
