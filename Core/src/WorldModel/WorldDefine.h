#ifndef _WORLD_DEFINE_H_
#define _WORLD_DEFINE_H_
#include <geometry.h>
#include <chrono>
/************************************************************************/
/*                       ObjectPoseT                                    */
/************************************************************************/
class ObjectPoseT {
  public:
    ObjectPoseT() : _valid(false), _pos(CGeoPoint(-9999, -9999)) { }
    const CGeoPoint& Pos() const {
        return _pos;
    }
    void SetPos(double x, double y) {
        _pos = CGeoPoint(x, y);
    }
    void SetPos(const CGeoPoint& pos) {
        _pos = pos;
    }
    double X() const {
        return _pos.x();
    }
    double Y() const {
        return _pos.y();
    }
    void SetVel(double x, double y) {
        _vel = CVector(x, y);
    }
    void SetVel(const CVector& vel) {
        _vel = vel;
    }
    void SetRawVel(double x, double y) {
        _rawVel = CVector(x, y);
    }
    void SetRawVel(const CVector& vel) {
        _rawVel = vel;
    }
    void SetAcc(double x, double y) {
        _acc = CVector(x, y);
    }
    void SetAcc(const CVector& acc) {
        _acc = acc;
    }
    const CVector& Vel() const {
        return _vel;
    }
    const CVector& RawVel() const {
        return _rawVel;
    }
    const CVector& Acc() const {
        return _acc;
    }
    double VelX() const {
        return _vel.x();
    }
    double VelY() const {
        return _vel.y();
    }
    double AccX() const {
        return _acc.x();
    }
    double AccY() const {
        return _acc.y();
    }
    void SetValid(bool v) {
        _valid = v;
    }
    bool Valid() const {
        return _valid;
    }
  private:
    CGeoPoint _pos;
    CVector _vel;
    CVector _rawVel;
    CVector _acc;
    bool _valid;
};
/************************************************************************/
/*                      VisionObjectT                                   */
/************************************************************************/
class VisionObjectT {
  public:
    VisionObjectT() : _rawPos(CGeoPoint(-9999, -9999)) { }
    const CGeoPoint& RawPos() const {
        return _rawPos;
    }
    const CGeoPoint& ChipPredictPos() const {
        return _chipPredict;
    }
    double RawDir() const {
        return _rawDir;
    }
    void SetChipPredict(const CGeoPoint& chipPos) {
        _chipPredict = chipPos;
    }
    void SetChipPredict(double x, double y) {
        _chipPredict =  CGeoPoint(x, y);
    }
    void SetRawPos(double x, double y) {
        _rawPos = CGeoPoint(x, y);
    }
    void SetRawPos(const CGeoPoint& pos) {
        _rawPos = pos;
    }
    void SetRawDir(double rawdir) {
        _rawDir = rawdir;
    }
  private:
    CGeoPoint _rawPos; // 视觉的原始信息，没有经过预测
    CGeoPoint _chipPredict; //挑球预测
    double _rawDir;
};
/************************************************************************/
/*                       MobileVisionT                                  */
/************************************************************************/
class MobileVisionT : public ObjectPoseT, public VisionObjectT {

};
/************************************************************************/
/*                        机器人姿态数据结构                               */
/************************************************************************/
struct PlayerPoseT : public ObjectPoseT { // 目标信息
  public:
    PlayerPoseT() : _dir(0), _rotVel(0) { }
    double Dir() const {
        return _dir;
    }
    void SetDir(double d) {
        _dir = d;
    }
    double RotVel() const {
        return _rotVel;
    }
    void SetRotVel(double d) {
        _rotVel = d;
    }
    double RawRotVel() const {
        return _rawRotVel;
    }
    void SetRawRotVel(double d) {
        _rawRotVel = d;
    }
  private:
    double _dir; // 朝向
    double _rotVel; // 旋转速度
    double _rawRotVel;
};


/************************************************************************/
/*                      GlobalTick                                     */
/************************************************************************/
//struct GlobalTick {
//    double ball_vel = 1;
//    double ball_last_vel = 1;
//    double ball_acc = 1;
//    double ball_last_acc = 1;
//    double ball_last_vel_dir = 1;
//    CGeoPoint ball_pos = CGeoPoint(0,0);
//    CGeoPoint ball_last_pos = CGeoPoint(0,0);
//    CGeoPoint ball_pos_move_befor = CGeoPoint(0,0);
//    std::chrono::high_resolution_clock::time_point time;
//    std::chrono::high_resolution_clock::time_point last_time;
//    double ball_avg_vel = 0;
//    double ball_vel_dir = 1;
//    double ball_max_vel_move_befor = 0;
//    double acc_count = 0;
//    int tick_count = 0;
//    int tick_key = 0;
//    bool change_move = false;
//    double data = 0;
//    double delta_time = 0;

//};

struct GlobalTick{
    //球相关
    double ball_vel = 1; // 球速度
    double ball_acc = 1; // 球加速度
    CGeoPoint ball_pos = CGeoPoint(0,0); // 球位置
    CGeoPoint ball_pos_move_befor = CGeoPoint(0,0); // 球运动之前的位置
    double ball_predict_vel_max = 0; // 预测的最大速度
    double ball_avg_vel = 0; // 球平均速度
    double ball_vel_dir = 0; // 球速度方向
    int ball_rights = 0; // 球权 [-1：敌方, 0:无人, 1:我方, 2:顶牛(双方处于纠缠的状况，无法判断具体球权属于谁)]
    int ball_our_min_dist_num = 0; // 我方距离球最近的车号
    int ball_their_min_dist_num = 0; // 敌方距离球最近的车号
    //我方相关
    int our_player [16] = {}; // 我方机器人数组
    int our_player_num = 6; // 我方玩家数目
    int our_goalie_num = 0; // 我方守门员号码
    int our_dribbling_num = -1;
    double delta_time = 1; // 与上一帧的时间间隔
    //敌方相关
    int their_player [16]; // 敌方机器人数组
    int their_player_num = 6; // 敌方玩家数目
    int their_goalie_num = 0; // 敌方守门员号码
    int their_dribbling_num = -1;

    //其他
    int tick_count = 0; // 帧计数
    int tick_key = 0; // 关键帧
    std::chrono::high_resolution_clock::time_point time; // 时间
};

/************************************************************************/
/*                      PlayerTypeT                                     */
/************************************************************************/
class PlayerTypeT {
  public:
    PlayerTypeT(): _type(0) {}
    void SetType(int t) {
        _type = t;
    }
    int Type() const {
        return _type;
    }
  private:
    int _type;
};
/************************************************************************/
/*                       PlayerVisionT                                  */
/************************************************************************/
class PlayerVisionT : public PlayerPoseT, public VisionObjectT, public PlayerTypeT {

};

/************************************************************************/
/*                        机器人能力数据结构                               */
/************************************************************************/
struct PlayerCapabilityT {
    PlayerCapabilityT(): maxAccel(0), maxSpeed(0), maxAngularAccel(0), maxAngularSpeed(0), maxDec(0), maxAngularDec(0) {}
    double maxAccel; // 最大加速度
    double maxSpeed; // 最大速度
    double maxAngularAccel; // 最大角加速度
    double maxAngularSpeed; // 最大角速度
    double maxDec;          // 最大减速度
    double maxAngularDec;   // 最大角减速度
};
#endif // _WORLD_DEFINE_H_
