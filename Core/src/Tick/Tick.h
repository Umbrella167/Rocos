#ifndef _TICK_H_
#define _TICK_H_

#include "staticparams.h"
#include <geometry.h>
#include <chrono>
#include "WorldModel.h"

using namespace std;

/**
 * @file Tick.h
 * @date 24/5/12
 * @brief 把我们（ZJHU）自己常用的数据更新写到一块去
 */

namespace
{
    struct balls
    {
    public:
        bool valid = true;
        double vel = 1;                                  // 球速度
        double acc = 1;                                  // 球加速度
        CGeoPoint pos = CGeoPoint(0, 0);                 // 球位置
        CGeoPoint pos_move_befor = CGeoPoint(0, 0);      // 球运动之前的位置
        CGeoPoint first_dribbling_pos = CGeoPoint(0, 0); // 第一次带球位置
        double predict_vel_max = 0;                      // 预测的最大速度
        double avg_vel = 0;                              // 球平均速度
        double vel_dir = 0;                              // 球速度方向
        int rights = 0;                                  // 球权 [-1：敌方, 0:无人, 1:我方, 2:顶牛(双方处于纠缠的状况，无法判断具体球权属于谁)]
        int our_min_dist_num = 0;                        // 我方距离球最近的车号
        int their_min_dist_num = 0;                      // 敌方距离球最近的车号
    };

    // 我方相关
    struct ours
    {
    public:
        int player_num = 6;          // 我方玩家数目
        int goalie_num = -1;         // 我方守门员号码
        int dribbling_num = -1;      // 带球的机器人编号
        int to_balldist_min_num = 0; // 距离球最近的机器人
        int defend_player_num1 = 0;
        int defend_player_num2 = 0;
    };

    // 敌方相关
    struct theirs
    {
    public:
        int player_num = 6;          // 敌方玩家数目
        int goalie_num = -1;         // 敌方守门员号码
        int dribbling_num = -1;      // 带球的机器人编号
        int to_balldist_min_num = 0; // 距离球最近的机器人
    };

    // 任务列表
    struct tasks
    {
    public:
        int player_num = -1;             // 当前机器人编号
        double confidence_pass = 0;      // 传球置信度
        double confidence_shoot = 0;     // 射门置信度
        double confidence_dribbling = 0; // 带球置信度
        double confidence_run = 0;       // 跑位置信度
        double confidence_defend = 0;    // 防守置信度
        double confidence_getball = 0;   // 抢球、接球置信度
        double max_confidence = 0;       // 最大的置信度
        int max_confidence_pass_num = 0; // 被传球概率最大的机器人号码
        int infrared_count = 0;
        int infrared_off_count = 0;
        CGeoPoint shoot_pos = CGeoPoint(0, 0); // 射门点
        std::string status = "NOTING";         // -1异常 0传球 1射门 2带球 3跑位 4防守 5抢球、接球
    };

    // 时间、其他相关
    struct times
    {
    public:
        double delta_time = 1;                               // 与上一帧的时间间隔
        int tick_count = 0;                                  // 帧计数
        int tick_key = 0;                                    // 关键帧
        std::chrono::high_resolution_clock::time_point time; // 时间
    };

    struct golobalDatas
    {
    public:
        double confidence_shoot = 1; // 与上一帧的时间间隔
    };

}

class CTick
{
public:
    CTick();
    ~CTick(void);

    void updateTick(const CVisionModule *pVision, int goalie_num, int defend_player_num1, int defend_player_num2);
    times time() const { return _time; }
    balls ball() const { return _ball; }
    ours our() const { return _our; }
    theirs their() const { return _their; }
    tasks task() const { return _task; }
    golobalDatas globalData() const { return _globalData; }

private:
    times _time;
    balls _ball;
    ours _our;
    theirs _their;
    tasks _task[PARAM::Field::MAX_PLAYER];
    golobalDatas _globalData;
};

typedef Singleton<CTick> Tick;

#endif // _TICK_H_