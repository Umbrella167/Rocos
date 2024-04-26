/**
 * @file utils.h
 * 此文件为一些工具函数的声明.
 * @date $Date: 2004/05/04 04:11:49 $
 * @version $Revision: 1.20 $
 * @author peter@mail.ustc.edu.cn
 */
#ifndef _UTILS_H_
#define _UTILS_H_
#include <geometry.h>
#include "staticparams.h"
#include <WorldDefine.h>

#define EPSILON (1.0E-10)

#ifdef STD_DEBUG_ENABLE
#define STD_DEBUG_OUT(header, content) \
    std::cout << header << " : " << content << std::endl;
#else
#define STD_DEBUG_OUT(header, content)
#endif

// add by mark
#ifdef _WIN32
#define finite _finite
#define isnan _isnan
#endif

class CVisionModule;
struct PlayerPoseT;
struct GlobalTick;
namespace Utils
{
    /* =============== HuRocos 2024 =============== */
    extern std::string GlobalComputingPos(const CVisionModule *pVision);                           // 计算所有点位
    extern double map(double value, double min_in, double max_in, double min_out, double max_out); // 映射
    extern bool InField(CGeoPoint Point);                                                          // 判断点是否在场地内
    extern bool InExclusionZone(CGeoPoint Point, double buffer = 0, std::string dir = "all");      // 判断点是否在禁区内
    extern bool InOurField(CGeoPoint Point);
    extern double NumberNormalize(double data, double max_data, double min_data); // [0,1] 标准化
    extern bool isValidPass(const CVisionModule *pVision, CGeoPoint start, CGeoPoint end, double buffer = 120);
    extern GlobalTick UpdataTickMessage(const CVisionModule *pVision, int goalie_num, int defend_player_num1, int defend_player_num2); // 获取帧信息
    extern CGeoPoint GetInterPos(const CVisionModule *pVision, CGeoPoint player_pos, double velocity);                                 // 获取最佳截球点
    extern CGeoSegment PredictBallLine(const CVisionModule *pVision);
    extern double PosToPosTime(CGeoPoint start_pos, CGeoPoint end_pos, double velocity);

    /* =============== 小工具 =============== */
    extern CGeoPoint GetBallMaxPos(const CVisionModule *pVision);
    extern double angleDiff(double angle1, double angle2); // 返回两个dir的差
    extern double ShowDribblingGrade(const CVisionModule *pVision, CGeoPoint run_pos, CGeoPoint player_pos, CGeoPoint target_pos);
    extern CGeoPoint GetShowDribblingPos(const CVisionModule *pVision, CGeoPoint player_pos, CGeoPoint target_pos);
    extern int GetPointToMinDistEnemyNum(const CVisionModule *pVision, CGeoPoint player_pos);                                  // 获取距离某坐标最进的敌人位置
    extern CGeoPoint PosGetShootPoint(const CVisionModule *pVision, double x, double y);                                       // 获取某坐标而言对方守门员的空位
    extern CGeoPoint GetShootPoint(const CVisionModule *pVision, int num);                                                     // 获取某坐标而言对方守门员的空位 + 持球员朝向
    extern double GetAttackGrade(const CVisionModule *pVision, double x, double y, CGeoPoint player_pos, CGeoPoint shoot_pos); // 计算某坐标点的跑位分
    extern CGeoPoint GetAttackPos(const CVisionModule *pVision, int num);                                                      // 计算已某玩家为圆心，半径，范围圆内 最佳跑位点
    extern CGeoPoint GetAttackPos(const CVisionModule *pVision, int num, CGeoPoint shootPos, CGeoPoint startPoint, CGeoPoint endPoint, double step, double ballDist = 1000);
    extern CGeoPoint GetTouchPassPos(const CVisionModule *pVision, CGeoPoint touch_pos);
    extern CGeoPoint GetTouchPos(const CVisionModule *pVision, CGeoPoint player_pos, double touchAngle, bool double_flag = false);
    extern double GetTouchGrade(const CVisionModule *pVision, double x, double y, CGeoPoint player_pos, CGeoPoint shoot_pos);
    extern double ConfidenceShoot(const CVisionModule *pVision, int num);
    extern double ConfidenceShoot(const CVisionModule *pVision, CGeoPoint player_pos);
    extern double ConfidencePass(const CVisionModule *pVision, int dribbling_player_num, int getball_player_num, double getball_player_confidence_shoot);
    extern double RobotToPosDirGrade(const CVisionModule *pVision, int num, CGeoPoint start, CGeoPoint end);
    extern double GlobalConfidence(const CVisionModule *pVision, int attack_flag = 0);
    extern std::string GlobalStatus(const CVisionModule *pVision, int attack_flag = 0);
    extern bool CheckSideToTurn(const CVisionModule *pVision, int role, double angle);
    // 多模式
    extern double PosToPosDirGrade(double x, double y, double x1, double y1, int dir = -1);
    extern double PosToPosDirGrade(double x, double y, double x1, double y1, double peak_pos, int dir = -1);                              // = 4 / PARAM::Math::RADIAN * PARAM::Math::PI
    extern double PosToBallDistGrade(CGeoPoint ball_pos, double x, double y, int dir = 1);                                                // 坐标到球的距离评分
    extern double PosToBallDistGrade(CGeoPoint ball_pos, double x, double y, double peak_pos, int dir = 1);                               // 坐标到球的距离评分
    extern double PosToPosDistGrade(double x, double y, double x1, double y1, int dir = 1, std::string model = "GAUSS");                  // 坐标到坐标的距离评分
    extern double NumberNormalizeGauss(double data, double max_data, double min_data, double peak_pos, std::string model = "DOUBLELINE"); // [0,1] 高斯归一化
    extern double PosSafetyGrade(const CVisionModule *pVision, CGeoPoint start, CGeoPoint end, std::string model = "SHOOT");              // 路径安全性评分
    extern CGeoPoint GetBestInterPos(const CVisionModule *pVision, CGeoPoint playerPos, double playerVel, int flag, int permissions);
    /* =============== Defence =============== */
    /* 球场信息 */
    /* 己方半场信息 */
    const int DEFENDER_FIELD_X_MIN = -PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PENALTY_AREA_DEPTH + 50;
    const int DEFENDER_FIELD_Y_BOR = PARAM::Field::PENALTY_AREA_WIDTH / 2;
    const CGeoLine DEFENDER_FIELD_PENALTYBOR({DEFENDER_FIELD_X_MIN, PARAM::Field::PENALTY_AREA_WIDTH / 2}, {DEFENDER_FIELD_X_MIN, -PARAM::Field::PENALTY_AREA_WIDTH / 2}); // 禁区直线
    /* 禁区信息 */

    /* 球员默认站位信息 */
    const CGeoPoint DEFAULT_STAND_POS(DEFENDER_FIELD_X_MIN, PARAM::Field::PENALTY_AREA_WIDTH / 2);
    const double DEFAULT_STAND_DIR = 0;
    const double DEFAULT_DISTANCE_MAX = PARAM::Field::PENALTY_AREA_WIDTH; // 两个后卫之间的最大距离
    const double DEFAULT_DISTANCE_MIN = 300.0;                            // 两个后卫之间的最小距离

    extern int ClosestPlayerToPlayer(const CVisionModule *pVision, int role, int type);
    extern CGeoPoint ClosestPlayerToPoint(const CVisionModule *pVision, CGeoPoint pos, int type, int role = -1);
    extern int ClosestPlayerNoToPoint(const CVisionModule *pVision, CGeoPoint pos, int type, int role = -1);

    extern CGeoPoint DEFENDER_ComputeCrossPenalty(const CVisionModule *pVision, CGeoLine line);
    extern double DEFENDER_ComputeDistance(CGeoPoint hitPoint);

    /* =============== Robocup-SSL-China =============== */
    extern double Normalize(double angle);               ///< 把角度规范化到(-PI,PI]
    extern CVector Polar2Vector(double m, double angle); ///< 极坐标转换到直角坐标
    extern double doubleToluaTemplate(double n);         ///< 极坐标转换到直角坐标

    extern double VectorDot(const CVector &v1, const CVector &v2);                       // 向量点乘
    extern double dirDiff(const CVector &v1, const CVector &v2);                         // { return fabs(Normalize(v1.dir() - v2.dir()));}
    extern bool InBetween(const CGeoPoint &p, const CGeoPoint &p1, const CGeoPoint &p2); // 判断p是否在p1,p2之间
    extern bool InBetween(double v, double v1, double v2);                               // 判断v是否在v1和v2之间
    // 三个均为向量的方向弧度, 判断是否满足v的方向夹在v1和v2之间
    // 如果v和v1或v2中的任意一个夹角小于buffer, 则也认为满足条件.
    extern bool AngleBetween(double d, double d1, double d2, double buffer = PARAM::Math::PI / 30);
    inline CGeoPoint CenterOfTwoPoint(const CGeoPoint &p1, const CGeoPoint &p2)
    {
        return CGeoPoint((p1.x() + p2.x()) / 2, (p1.y() + p2.y()) / 2);
    }
    // 判断三个共起点向量, v的方向是否夹在v1和v2之间,
    // buffer表示余量, 表示当v不在v1,v2之间时,
    // 如果v和v1或v2中的任意一个夹角小于buffer, 则也认为满足条件.
    extern bool InBetween(const CVector &v, const CVector &v1, const CVector &v2, double buffer = PARAM::Math::PI / 30);
    /*@brief	判断一个浮点数是否在其余两个浮点数之间*/
    inline bool CBetween(float v, float v1, float v2)
    {
        return (v > v1 && v < v2) || (v < v1 && v > v2);
    }
    /*@brief	计算点到直线的距离*/
    inline double pointToLineDist(const CGeoPoint &p, const CGeoLine &l)
    {
        return p.dist(l.projection(p));
    }
    inline double Deg2Rad(double angle)
    {
        return angle * PARAM::Math::PI / 180;
    }
    inline double Rad2Deg(double angle)
    {
        return angle * 180 / PARAM::Math::PI;
    }
    extern CGeoPoint MakeInField(const CGeoPoint &p, const double buffer = 0); // 让点在场内
    extern bool IsInField(const CGeoPoint p, double buffer = 0);               // 判断点是否在场地内, 第二个参数为边界缓冲
    extern bool IsInFieldV2(const CGeoPoint p, double buffer = 0);             // 判断点是否在场地内, 且不在禁区内， 第二个参数为边界缓冲
    inline double FieldLeft()
    {
        return -PARAM::Field::PITCH_LENGTH / 2 + PARAM::Field::PITCH_MARGIN;
    }
    inline double FieldRight()
    {
        return PARAM::Field::PITCH_LENGTH / 2 - PARAM::Field::PITCH_MARGIN;
    }
    inline double FieldTop()
    {
        return -PARAM::Field::PITCH_WIDTH / 2 + PARAM::Field::PITCH_MARGIN;
    }
    inline double FieldBottom()
    {
        return PARAM::Field::PITCH_WIDTH / 2 - PARAM::Field::PITCH_MARGIN;
    }
    inline CGeoPoint LeftTop()
    {
        return CGeoPoint(FieldLeft(), FieldTop());
    }
    inline CGeoPoint RightBottom()
    {
        return CGeoPoint(FieldRight(), FieldBottom());
    }
    inline int Sign(double d)
    {
        return (d >= 0) ? 1 : -1;
    }
    extern CGeoPoint MakeOutOfOurPenaltyArea(const CGeoPoint &p, const double buffer);
    extern CGeoPoint MakeOutOfTheirPenaltyArea(const CGeoPoint &p, const double buffer, const double dir = -1e8);
    extern CGeoPoint MakeOutOfCircleAndInField(const CGeoPoint &center, const double radius, const CGeoPoint &p, const double buffer); // 确保点在圆外
    extern CGeoPoint MakeOutOfCircle(const CGeoPoint &center, const double radius, const CGeoPoint &target, const double buffer, const bool isBack = false, const CGeoPoint &mePos = CGeoPoint(1e8, 1e8), const CVector adjustVec = CVector(1e8, 1e8));
    extern CGeoPoint MakeOutOfLongCircle(const CGeoPoint &seg_start, const CGeoPoint &seg_end, const double radius, const CGeoPoint &target, const double buffer, const CVector adjustVec = CVector(1e8, 1e8));
    extern CGeoPoint MakeOutOfRectangle(const CGeoPoint &recP1, const CGeoPoint &recP2, const CGeoPoint &target, const double buffer);

    extern bool InOurPenaltyArea(const CGeoPoint &p, const double buffer);
    extern bool InTheirPenaltyArea(const CGeoPoint &p, const double buffer);
    extern bool InTheirPenaltyAreaWithVel(const PlayerVisionT &me, const double buffer);
    extern bool PlayerNumValid(int num);
    extern CGeoPoint GetOutSidePenaltyPos(double dir, double delta, const CGeoPoint targetPoint = CGeoPoint(-(PARAM::Field::PITCH_LENGTH) / 2, 0));
    extern CGeoPoint GetOutTheirSidePenaltyPos(double dir, double delta, const CGeoPoint &targetPoint);
    extern CGeoPoint GetInterPos(double dir, const CGeoPoint targetPoint = CGeoPoint(-(PARAM::Field::PITCH_LENGTH) / 2, 0));
    extern CGeoPoint GetTheirInterPos(double dir, const CGeoPoint &targetPoint);
    extern float SquareRootFloat(float number);
    extern bool canGo(const CVisionModule *pVision, const int num, const CGeoPoint &target, const int flag, const double avoidBuffer);
    extern bool isValidFlatPass(const CVisionModule *pVision, CGeoPoint start, CGeoPoint end, bool isShoot = false, bool ignoreCloseEnemy = false, bool ignoreTheirGuard = false);
    extern bool isValidChipPass(const CVisionModule *pVision, CGeoPoint start, CGeoPoint end);
}
#endif
