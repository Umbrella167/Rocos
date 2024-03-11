#include "utils.h"
#include "WorldModel.h"
#include "staticparams.h"
#include <GDebugEngine.h>
#include <iostream>
#include <unistd.h>
/*
            C++ 传数据到 Lua 总结
        1.utils.cpp        写好功能
        2.utils.h          定义好函数
        3.到 utils.pkg 仿照相应的函数定义
        4.重新构建

@ data   : 20240205
@ author : Umbrella
*/
GlobalTick Tick[PARAM::Tick::TickLength];

namespace Utils
{
    // 没写完 START

    // TODO: 你们检查一下写的注释对不对，对的话帮我这行TODO删了
    /**
     * 计算全局位置
     * @param  {CVisionModule*} pVision : 视觉模块
     * @param  {CGeoPoint} p            : 位置
     * @return {string}                 : 计算出的位置
     */
    string GlobalComputingPos(const CVisionModule *pVision, const CGeoPoint &p)
    {
        UpdataTickMessage(pVision);
        int step = 100;
        int half_length = PARAM::Field::PITCH_LENGTH / 2;
        int half_width = PARAM::Field::PITCH_WIDTH / 2;
        int field_x = 0;
        int field_y = 0;
        GetShootPoint(pVision, pVision->ball().X(), pVision->ball().Y(), 5, "TRAVERSE");
        double a = PosToPosDirGrade(0, 0, pVision->ball().X(), pVision->ball().Y(), 1, "NORMAL");
        return to_string(a); // FIXME: 字符串可能还是抽象了点，到时候看看修一下
    }

    //    void UpdataTickMessage(const CVisionModule *pVision){
    //        // last give
    //        Tick.ball_last_acc = Tick.ball_acc;
    //        Tick.last_time = Tick.time;
    //        Tick.ball_last_vel = Tick.ball_vel;
    //        Tick.ball_last_vel_dir = Tick.ball_vel_dir;
    //        // get now
    //        Tick.tick_count += 1;
    //        Tick.ball_vel = pVision -> ball().Vel().mod() / 1000;
    //        Tick.time = std::chrono::high_resolution_clock::now();
    //        Tick.delta_time = (double)std::chrono::duration_cast<std::chrono::microseconds>(Tick.time - Tick.last_time).count() / 1000000;  // 计算时间差，单位为微秒
    //        // static record
    //        if (Tick.ball_vel > 0){
    //            Tick.acc_count+=1;
    //        }
    //        else {
    //            Tick.acc_count =0;
    //            Tick.ball_acc = 0;
    //            Tick.ball_avg_vel = 0;
    //        }
    //        if (Tick.acc_count > 2 && Tick.acc_count <= 7){
    //            Tick.ball_max_vel_move_befor = pVision ->ball().Vel().mod() / 1000;
    //            Tick.ball_acc = (Tick.ball_vel - Tick.ball_last_vel) / Tick.delta_time;
    //            Tick.ball_avg_vel += Tick.ball_vel / 6.3;
    //        }
    //        Tick.ball_vel_dir = pVision ->ball().Vel().dir();
    //        if(pVision ->ball().Vel().mod() == 0 || abs(Tick.ball_last_vel_dir - Tick.ball_vel_dir) > 0.05){
    //            Tick.ball_pos_move_befor = pVision ->ball().Pos();
    //            Tick.change_move = true;
    //        }
    //        else{
    //            Tick.change_move = false;
    //        }
    //    }

    /**
     * 更新帧信息
     * @param  {CVisionModule*} pVision : 视觉模块
     */
    void UpdataTickMessage(const CVisionModule *pVision)
    {
        int now = 1;
        int last = 0;
        Tick[last] = Tick[now];
        Tick[now].ball_pos = pVision->ball().Pos();
        Tick[now].ball_vel = pVision->ball().Vel().mod() / 1000;
        Tick[now].time = std::chrono::high_resolution_clock::now();
        Tick[now].tick_count += 1;
        Tick[now].delta_time = (double)std::chrono::duration_cast<std::chrono::microseconds>(Tick[now].time - Tick[last].time).count() / 1000000;

        Tick[now].ball_vel_dir = pVision->ball().Vel().dir();
        if (Tick[now].ball_vel == 0 || abs(Tick[last].ball_vel_dir - Tick[now].ball_vel_dir) > 0.05)
        {
            Tick[now].ball_avg_vel = Tick[now].ball_vel;
            // Tick[now].ball_pos_move_befor = Tick[now].ball_pos;
        }

        GDebugEngine::Instance()->gui_debug_line(Tick[now].ball_pos_move_befor, Tick[now].ball_pos);
        GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(-3000, 2000), to_string(Tick[now].ball_avg_vel));
    }

    /**
     * TODO: 补全
     * @param  {CVisionModule*} pVision :
     * @param  {CGeoPoint} start        :
     * @param  {CGeoPoint} end          :
     * @return {double}                 :
     */
    double PosSafetyGrade(const CVisionModule *pVision, CGeoPoint start, CGeoPoint end)
    {
        CGeoSegment BallLine(start, end);
        for (int i = 0; i < PARAM::Field::MAX_PLAYER; i++)
        {
            if (!pVision->theirPlayer(i).Valid())
                continue;
            pVision->ball().Vel();
        }
    }

    /**
     * TODO: 补全
     * @param  {CVisionModule*} pVision :
     * @param  {CGeoPoint} player_pos   :
     * @param  {double} velocity        :
     * @return {CGeoPoint}              :
     */
    CGeoPoint GetInterPos(const CVisionModule *pVision, CGeoPoint player_pos, double velocity)
    {
        /* double buffer = 0;
        UpdataTickMessage(pVision);
        CGeoSegment ball_Segment = PredictBallLine(pVision);
        CGeoLine ball_line(Tick.ball_pos_move_befor, Tick.ball_vel_dir);
        CGeoPoint InterPos = ball_line.projection(player_pos);
        if (!ball_Segment.IsPointOnLineOnSegment(InterPos))
        {
            InterPos = ball_Segment.end();
        }
        InterPos = CGeoPoint(0, 0);
        double dist = 0;
        for (dist = (ball_Segment.end() - Tick.ball_pos_move_befor).mod(); dist > 0; dist -= 200)
        {
            CGeoPoint newInterPos = ball_Segment.end() + Polar2Vector(-dist, pVision->ball().Vel().dir());
            // GDebugEngine::Instance() ->gui_debug_x(newInterPos);
            // GDebugEngine::Instance() ->gui_debug_msg(CGeoPoint(-4000,dist),to_string(Tick.ball_max_vel_move_befor) + "   " + to_string(newInterPos.x()) + "   " + to_string(PosToPosTime(Tick.ball_pos_move_befor,newInterPos,Tick.ball_max_vel_move_befor * 1000)));
            // GDebugEngine::Instance() ->gui_debug_msg(CGeoPoint(2000,dist),to_string(velocity) + "   " + to_string(newInterPos.x()) + "   " + to_string(PosToPosTime(newInterPos,player_pos,velocity * 1000)));
            if (PosToPosTime(Tick.ball_pos_move_befor, newInterPos, Tick.ball_max_vel_move_befor) - PosToPosTime(player_pos, newInterPos, velocity) > buffer)
            {
                InterPos = newInterPos;
                InterPos = ball_Segment.projection(InterPos);
                break;
            }
        }

        // GDebugEngine::Instance() ->gui_debug_msg(CGeoPoint(-4000,2000),to_string(Tick.ball_max_vel_move_befor));
        GDebugEngine::Instance()->gui_debug_x(InterPos, 5);
        return InterPos; */
    }

    /**
     * TODO: 补全
     * @param  {CGeoPoint} start_pos :
     * @param  {CGeoPoint} end_pos   :
     * @param  {double} velocity     :
     * @return {double}              :
     */
    double PosToPosTime(CGeoPoint start_pos, CGeoPoint end_pos, double velocity)
    {
        return (start_pos - end_pos).mod() / velocity;
    }

    /**
     * TODO: 补全
     * @param  {CVisionModule*} pVision :
     * @return {CGeoSegment}            :
     */
    CGeoSegment PredictBallLine(const CVisionModule *pVision)
    {
        //        double ball_x = Tick.ball_acc == 0?0:(Tick.ball_avg_vel * Tick.ball_avg_vel / 2 * PARAM::Field::BALL_DECAY)*10000;
        //        GDebugEngine::Instance() ->gui_debug_line(Tick.ball_pos_move_befor,Tick.ball_pos_move_befor + Polar2Vector(-ball_x,PARAM::Math::PI + pVision->ball().Vel().dir()),3);
        //        return CGeoSegment(Tick.ball_pos_move_befor,Tick.ball_pos_move_befor + Polar2Vector(-ball_x,PARAM::Math::PI + pVision->ball().Vel().dir()));
    }

    /**
     * TODO: 补全
     * @param  {double} x          :
     * @param  {double} y          :
     * @param  {double} last_grade :
     * @return {double}            :
     */
    double GetAttackGrade(double x, double y, double last_grade)
    {
    }

    /**
     * TODO: 补全
     * @param  {CVisionModule*} pVision :
     * @param  {double} x               :
     * @param  {double} y               :
     * @param  {int} num                :
     * @param  {std::string} model      :
     * @return {CGeoPoint}              :
     */
    CGeoPoint GetShootPoint(const CVisionModule *pVision, double x, double y, int num, std::string model)
    {
        string model_type[2] = {
            "FORMULA",
            "TRAVERSE",
        };
        if (model == model_type[0])
        {
            if (num == -1)
            {
                CGeoPoint shoot_point(PARAM::Field::PITCH_LENGTH / 2, 0);
                GDebugEngine::Instance()->gui_debug_x(shoot_point, 3);
                return shoot_point;
            }
            else
            {
                double y = pVision->theirPlayer(num).Pos().y();
                y = y >= 0 ? y - (y + (PARAM::Field::GOAL_WIDTH / 2)) / 2 : y + ((PARAM::Field::GOAL_WIDTH / 2) - y) / 2;
                // double yf= y > 0 ? y + (PARAM::Field::GOAL_WIDTH / 2 - y) / 2:y - (PARAM::Field::GOAL_WIDTH / 2 + y) / 2;
                y = (y > PARAM::Field::GOAL_WIDTH / 2) || (y < -1 * PARAM::Field::GOAL_WIDTH / 2) ? 0 : y;
                GDebugEngine::Instance()->gui_debug_x(CGeoPoint(PARAM::Field::PITCH_LENGTH / 2, y), 3);
                return CGeoPoint(PARAM::Field::PITCH_LENGTH / 2, y);
            }
        }
        else
        {
            double pos_to_pos_dist_grade = 0;
            double pos_to_pos_dir_grade = 0;
            double pos_life = 0;
            double grade = 0;
            double max_grade = -999;
            double max_y = 0;
            for (int y1 = -1 * PARAM::Field::GOAL_WIDTH * 0.4; y1 < PARAM::Field::GOAL_WIDTH * 0.4; y1 += 50)
            {
                if (!isValidPass(pVision, CGeoPoint(x, y), CGeoPoint(PARAM::Field::PITCH_LENGTH / 2, y1), PARAM::Player::playerBuffer))
                    continue;
                pos_to_pos_dist_grade = PosToPosDistGrade(x, y, PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::GOAL_DEPTH / 2, y1, -1, "NORMAL");
                pos_to_pos_dir_grade = PosToPosDirGrade(x, y, PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::GOAL_DEPTH / 2, y1, 1, "NORMAL");
                grade = 0.5 * pos_to_pos_dist_grade + 0.5 * pos_to_pos_dir_grade;
                if (grade > max_grade)
                {
                    max_grade = grade;
                    max_y = y1;
                }
            }
            CGeoPoint ShootPoint(PARAM::Field::PITCH_LENGTH / 2, max_y);
            GDebugEngine::Instance()->gui_debug_msg(CGeoPoint(0, 1000), to_string(max_grade), 3);
            GDebugEngine::Instance()->gui_debug_x(ShootPoint, 3);
            return ShootPoint;
        }
    }

    /**
     * TODO: 补全
     * TODO: 没写完 END
     * @param  {CVisionModule*} pVision :
     * @param  {CGeoPoint} start        :
     * @param  {CGeoPoint} end          :
     * @param  {double} buffer          :
     * @param  {bool} ignoreCloseEnemy  :
     * @param  {bool} ignoreTheirGuard  :
     * @return {bool}                   :
     */
    bool isValidPass(const CVisionModule *pVision, CGeoPoint start, CGeoPoint end, double buffer, bool ignoreCloseEnemy, bool ignoreTheirGuard)
    {
        // 判断能否传球的角度限制
        static const double CLOSE_ANGLE_LIMIT = 8 * PARAM::Math::PI / 180;
        static const double FAR_ANGLE_LIMIT = 12 * PARAM::Math::PI / 180;
        static const double CLOSE_THRESHOLD = 50;

        static const double SAFE_DIST = 50;
        static const double CLOSE_ENEMY_DIST = 50;

        bool valid = true;
        // 使用平行线进行计算，解决近距离扇形计算不准问题
        CGeoSegment BallLine(start, end);
        for (int i = 0; i < PARAM::Field::MAX_PLAYER; i++)
        {
            if (!pVision->theirPlayer(i).Valid())
                continue;
            if (ignoreCloseEnemy && pVision->theirPlayer(i).Pos().dist(start) < CLOSE_ENEMY_DIST)
                continue;
            if (ignoreTheirGuard && Utils::InTheirPenaltyArea(pVision->theirPlayer(i).Pos(), 30))
                continue;
            CGeoPoint targetPos = pVision->theirPlayer(i).Pos();
            double dist = BallLine.dist2Point(targetPos);
            if (dist < buffer)
            {
                valid = false;
                break;
            }
        }
        return valid;
    }

    /**
     * TODO: 补全
     * @param  {double} x          :
     * @param  {double} y          :
     * @param  {double} x1         :
     * @param  {double} y1         :
     * @param  {int} dir           :
     * @param  {std::string} model :
     * @return {double}            :
     */
    double PosToPosDirGrade(double x, double y, double x1, double y1, int dir, std::string model)
    {
        std::string model_type[] = {"GAUSS", "NORMAL"};
        CGeoPoint point1(x, y);
        CGeoPoint point2(x1, y1);
        double grade_dir = abs((point1 - point2).dir() * PARAM::Math::RADIAN);
        grade_dir = model_type[1] == model ? NumberNormalize(grade_dir, PARAM::Math::RADIAN * PARAM::Math::PI, 0) : NumberNormalizeGauss(grade_dir, PARAM::Math::RADIAN * PARAM::Math::PI, 0, 4 / PARAM::Math::RADIAN * PARAM::Math::PI);
        return grade_dir;
    }

    /**
     * TODO: 补全
     * @param  {CVisionModule*} pVision :
     * @param  {double} x               :
     * @param  {double} y               :
     * @param  {int} dir                :
     * @param  {std::string} model      :
     * @return {double}                 :
     */
    double PosToBallDistGrade(const CVisionModule *pVision, double x, double y, int dir, std::string model)
    {
        std::string model_type[] = {"GAUSS", "NORMAL"};
        CGeoPoint pos(x, y);
        CGeoPoint ball_pos(pVision->ball().Pos());
        double peak_pos = PARAM::Field::PITCH_LENGTH / 3.8;
        double max_data = PARAM::Field::PITCH_LENGTH / 1.4;
        double min_data = 0;
        double distance = (pos - ball_pos).mod();
        double grade = model == model_type[0] ? NumberNormalizeGauss(distance, max_data, min_data, peak_pos) : NumberNormalize(distance, max_data, min_data);
        if (distance > PARAM::Field::PITCH_LENGTH / 1.4)
        {
            grade = dir > 0 ? grade : (1 - grade);
            return 0.0;
        }
        return grade;
    }

    /**
     * TODO: 补全
     * @param  {double} x          :
     * @param  {double} y          :
     * @param  {double} x1         :
     * @param  {double} y1         :
     * @param  {int} dir           :
     * @param  {std::string} model :
     * @return {double}            :
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
     * TODO: 补全
     * @param  {double} data       :
     * @param  {double} max_data   :
     * @param  {double} min_data   :
     * @param  {double} peak_pos   :
     * @param  {std::string} model :
     * @return {double}            :
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
    double NumberNormalize(double data, double max_data, double min_data)
    {
        return (data - min_data) / (max_data - min_data);
    }
    double map(double value, double min_in, double max_in, double min_out, double max_out)
    {
        return min_out + (max_out - min_out) * (value - min_in) / (max_in - min_in);
    }
    bool InExclusionZone(double x, double y)
    {
        if (((x < (-1 * PARAM::Field::PITCH_LENGTH / 2) + PARAM::Field::PENALTY_AREA_DEPTH + PARAM::Player::playerRadiusr) ||
             (x > (PARAM::Field::PITCH_LENGTH / 2) - PARAM::Field::PENALTY_AREA_DEPTH - PARAM::Player::playerRadiusr)) &&
            (y > -1 * PARAM::Field::PENALTY_AREA_WIDTH / 2 - PARAM::Player::playerRadiusr && y < PARAM::Field::PENALTY_AREA_WIDTH / 2 + PARAM::Player::playerRadiusr))
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    // Open-ssl-china

    double dirDiff(const CVector &v1, const CVector &v2) { return fabs(Normalize(v1.dir() - v2.dir())); }
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
    // modified by Wang in 2018/3/17
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

    // GetDefendPos的处理细节
    // 给定点和方向求它和禁区线的交点
    // 给定点需在禁区内
    // modified by Wang in 2018/3/17
    CGeoPoint GetInterPos(double dir, const CGeoPoint targetPoint)
    {
        using namespace PARAM::Field;
        if (IF_USE_ELLIPSE)
        {
            // ellipse penalty
            // 禁区的两段圆弧,用圆来表示
            CGeoCirlce c1(CGeoPoint(-PITCH_LENGTH / 2, PENALTY_AREA_L / 2), PENALTY_AREA_R);
            CGeoCirlce c2(CGeoPoint(-PITCH_LENGTH / 2, -PENALTY_AREA_L / 2), PENALTY_AREA_R);
            CGeoPoint targetPointInstead = targetPoint;
            if (dir >= PARAM::Math::PI / 2 - 5 / 180 * PARAM::Math::PI && dir <= PARAM::Math::PI)
                return CGeoPoint(-PITCH_LENGTH / 2, PENALTY_AREA_L / 2 + PENALTY_AREA_R);
            else if (dir <= -PARAM::Math::PI / 2 + 5 / 180 * PARAM::Math::PI && dir >= -PARAM::Math::PI)
                return CGeoPoint(-PITCH_LENGTH / 2, -PENALTY_AREA_L / 2 - PENALTY_AREA_R);

            // 连接两段圆弧的直线(pLine),用直线来表示
            CGeoPoint pend1(-PITCH_LENGTH / 2 + PENALTY_AREA_R, PENALTY_AREA_L / 2);
            CGeoPoint pend2(-PITCH_LENGTH / 2 + PENALTY_AREA_R, -PENALTY_AREA_L / 2);
            CGeoLine pLine(pend1, pend2);
            // 过给定的点和方向, 作一条直线
            CGeoLine dirLine(targetPointInstead, dir);

            // 求该直线和c1的交点
            if (targetPoint.y() == c1.Center().y())
            {
                if (dir >= 0 && dir < PARAM::Math::PI / 2)
                {
                    CGeoPoint p = c1.Center() + Polar2Vector(PENALTY_AREA_R, dir);
                    return p;
                }
            }
            else
            {
                CGeoLineCircleIntersection dirLine_c1_inter(dirLine, c1);
                if (dirLine_c1_inter.intersectant())
                {
                    CGeoPoint p1 = dirLine_c1_inter.point1();
                    CGeoPoint p2 = dirLine_c1_inter.point2();
                    double dir1 = Normalize((p1 - c1.Center()).dir());
                    double dir2 = Normalize((p2 - c1.Center()).dir());
                    if (dir1 >= 0 && dir1 <= PARAM::Math::PI / 2)
                    {
                        return p1;
                    }
                    else if (dir2 >= 0 && dir2 <= PARAM::Math::PI / 2)
                    {
                        return p2;
                    }
                }
            }

            // 求该直线和c2的交点
            if (targetPoint.y() == c2.Center().y())
            {
                if (dir <= 0 && dir > (-PARAM::Math::PI / 2))
                {
                    CGeoPoint p = c2.Center() + Polar2Vector(PENALTY_AREA_R, dir);
                    return p;
                }
            }
            else
            {
                CGeoLineCircleIntersection dirLine_c2_inter(dirLine, c2);
                if (dirLine_c2_inter.intersectant())
                {
                    CGeoPoint p1 = dirLine_c2_inter.point1();
                    CGeoPoint p2 = dirLine_c2_inter.point2();
                    double dir1 = Normalize((p1 - c2.Center()).dir());
                    double dir2 = Normalize((p2 - c2.Center()).dir());
                    if (dir1 >= (-PARAM::Math::PI / 2) && dir1 <= 0)
                    {
                        return p1;
                    }
                    else if (dir2 >= (-PARAM::Math::PI / 2) && dir2 <= 0)
                    {
                        return p2;
                    }
                }
            }
            // 求该直线和连接两条圆弧的线段pLine的交点
            CGeoLineLineIntersection pline_dirline_inter(pLine, dirLine);
            if (pline_dirline_inter.Intersectant())
            {
                CGeoPoint p = pline_dirline_inter.IntersectPoint();
                if (p.y() <= pend1.y() && p.y() >= pend2.y())
                {
                    return p;
                }
            }
            //// 返回一个默认点,禁区顶部的中点
            //            std::cout<<"our default pos!!"<<std::endl;
            return CGeoPoint(-PITCH_LENGTH / 2 + PENALTY_AREA_R, 0);
        }
        else
        {
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
        //}
        /*
        else if (std::fabs(targetPoint.y()) <= PENALTY_AREA_WIDTH / 2) {//case 3
            if (InOurPenaltyArea(inter_p2, 0)) return inter_p2;
            else return p2;//随便选的
        }
        else {
            if (targetPoint.y() <= 0) {//case 4
                if (InOurPenaltyArea(inter_p1, 0)) return inter_p1;
                else if (InOurPenaltyArea(inter_p2, 0)) return inter_p2;
                else return p2;//随便选的
            }
            else {//case 5
                if (InOurPenaltyArea(inter_p2, 0)) return inter_p2;
                else if (InOurPenaltyArea(inter_p3, 0)) return inter_p3;
                else return p3;//随便选的
            }
        }
        */
    }
    // modified by Wang in 2018/3/17
    CGeoPoint GetTheirInterPos(double dir, const CGeoPoint &targetPoint)
    {
        using namespace PARAM::Field;
        if (IF_USE_ELLIPSE)
        {
            // ellipse penalty
            // 禁区的两段圆弧,用圆来表示
            CGeoCirlce c1(CGeoPoint(-PITCH_LENGTH / 2, PENALTY_AREA_L / 2), PENALTY_AREA_R);
            CGeoCirlce c2(CGeoPoint(-PITCH_LENGTH / 2, -PENALTY_AREA_L / 2), PENALTY_AREA_R);
            CGeoPoint targetPointInstead = targetPoint;
            if (dir >= PARAM::Math::PI / 2 - 5 / 180 * PARAM::Math::PI && dir <= PARAM::Math::PI)
                return CGeoPoint(-PITCH_LENGTH / 2, PENALTY_AREA_L / 2 + PENALTY_AREA_R);
            else if (dir <= -PARAM::Math::PI / 2 + 5 / 180 * PARAM::Math::PI && dir >= -PARAM::Math::PI)
                return CGeoPoint(-PITCH_LENGTH / 2, -PENALTY_AREA_L / 2 - PENALTY_AREA_R);

            // 连接两段圆弧的直线(pLine),用直线来表示
            CGeoPoint pend1(-PITCH_LENGTH / 2 + PENALTY_AREA_R, PENALTY_AREA_L / 2);
            CGeoPoint pend2(-PITCH_LENGTH / 2 + PENALTY_AREA_R, -PENALTY_AREA_L / 2);
            CGeoLine pLine(pend1, pend2);
            // 过给定的点和方向, 作一条直线
            CGeoLine dirLine(targetPointInstead, dir);

            // 求该直线和c1的交点
            if (targetPoint.y() == c1.Center().y())
            {
                if (dir >= 0 && dir < PARAM::Math::PI / 2)
                {
                    CGeoPoint p = c1.Center() + Polar2Vector(PENALTY_AREA_R, dir);
                    return p;
                }
            }
            else
            {
                CGeoLineCircleIntersection dirLine_c1_inter(dirLine, c1);
                if (dirLine_c1_inter.intersectant())
                {
                    CGeoPoint p1 = dirLine_c1_inter.point1();
                    CGeoPoint p2 = dirLine_c1_inter.point2();
                    double dir1 = Normalize((p1 - c1.Center()).dir());
                    double dir2 = Normalize((p2 - c1.Center()).dir());
                    if (dir1 >= 0 && dir1 <= PARAM::Math::PI / 2)
                    {
                        return p1;
                    }
                    else if (dir2 >= 0 && dir2 <= PARAM::Math::PI / 2)
                    {
                        return p2;
                    }
                }
            }

            // 求该直线和c2的交点
            if (targetPoint.y() == c2.Center().y())
            {
                if (dir <= 0 && dir > (-PARAM::Math::PI / 2))
                {
                    CGeoPoint p = c2.Center() + Polar2Vector(PENALTY_AREA_R, dir);
                    return p;
                }
            }
            else
            {
                CGeoLineCircleIntersection dirLine_c2_inter(dirLine, c2);
                if (dirLine_c2_inter.intersectant())
                {
                    CGeoPoint p1 = dirLine_c2_inter.point1();
                    CGeoPoint p2 = dirLine_c2_inter.point2();
                    double dir1 = Normalize((p1 - c2.Center()).dir());
                    double dir2 = Normalize((p2 - c2.Center()).dir());
                    if (dir1 >= (-PARAM::Math::PI / 2) && dir1 <= 0)
                    {
                        return p1;
                    }
                    else if (dir2 >= (-PARAM::Math::PI / 2) && dir2 <= 0)
                    {
                        return p2;
                    }
                }
            }
            // 求该直线和连接两条圆弧的线段pLine的交点
            CGeoLineLineIntersection pline_dirline_inter(pLine, dirLine);
            if (pline_dirline_inter.Intersectant())
            {
                CGeoPoint p = pline_dirline_inter.IntersectPoint();
                if (p.y() <= pend1.y() && p.y() >= pend2.y())
                {
                    return p;
                }
            }
            //// 返回一个默认点,禁区顶部的中点
            //            std::cout<<"our default pos!!"<<std::endl;
            return CGeoPoint(-PITCH_LENGTH / 2 + PENALTY_AREA_R, 0);
        }
        else
        {
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
            // 2019, china open, ellipse penalty
            else if (PARAM::Rule::Version == 2019 &&
                     PARAM::Field::IF_USE_ELLIPSE)
            {
                CGeoCirlce c1(CGeoPoint(-PARAM::Field::PITCH_LENGTH / 2,
                                        PARAM::Field::PENALTY_AREA_L / 2),
                              PARAM::Field::PENALTY_AREA_R + avoidBuffer);
                CGeoCirlce c2(CGeoPoint(-PARAM::Field::PITCH_LENGTH / 2,
                                        -PARAM::Field::PENALTY_AREA_L / 2),
                              PARAM::Field::PENALTY_AREA_R + avoidBuffer);
                CGeoRectangle defenseBox(
                    -PARAM::Field::PITCH_LENGTH / 2 +
                        PARAM::Field::PENALTY_AREA_R +
                        avoidBuffer,
                    -PARAM::Field::PENALTY_AREA_L / 2,
                    -PARAM::Field::PITCH_LENGTH / 2,
                    PARAM::Field::PENALTY_AREA_L / 2);
                CGeoLineCircleIntersection intersection1(moving_seg, c1);
                CGeoLineCircleIntersection intersection2(moving_seg, c2);
                CGeoLineRectangleIntersection intersection3(moving_seg,
                                                            defenseBox);
                if (intersection1.intersectant() ||
                    intersection2.intersectant() ||
                    intersection3.intersectant())
                {
                    if (moving_seg.IsPointOnLineOnSegment(intersection1.point1()) ||
                        moving_seg.IsPointOnLineOnSegment(intersection1.point2()) ||
                        moving_seg.IsPointOnLineOnSegment(intersection2.point1()) ||
                        moving_seg.IsPointOnLineOnSegment(intersection2.point2()) ||
                        moving_seg.IsPointOnLineOnSegment(intersection3.point1()) ||
                        moving_seg.IsPointOnLineOnSegment(intersection3.point2()))
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
    /**
     * 判断能否传球的角度限制 TODO: 补全
     * @param  {CVisionModule*} pVision :
     * @param  {CGeoPoint} start        :
     * @param  {CGeoPoint} end          :
     * @param  {bool} isShoot           :
     * @param  {bool} ignoreCloseEnemy  :
     * @param  {bool} ignoreTheirGuard  :
     * @return {bool}                   :
     */
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
        for (int i = 0; i < PARAM::Field::MAX_PLAYER; i++)
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

    /**
     * 判断能否传球的角度限制 TODO: 补全
     * @param  {CVisionModule*} pVision :
     * @param  {CGeoPoint} start        :
     * @param  {CGeoPoint} end          :
     * @return {bool}                   :
     */
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
