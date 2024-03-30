#ifndef LEASTSQUARESFIT_H
#define LEASTSQUARESFIT_H
#include "geometry.h"
#include "staticparams.h"
#include "WorldModel.h"
#include <cstring>
#include <vector>
#include <map>
#include <iostream>
#include <fstream>

using namespace std;

struct Function{
    double label;
    double a;
    double b;
    double c;
};

class LeastSquaresfit
{
public:
    LeastSquaresfit();
    ~LeastSquaresfit();
    double* Fit(double array1[], double array2[]); //擬合函數
    void GetFitData(GlobalTick* Tick); //採集訓練數據
    void FitFromFile(string filename);
    int GetClosestLabelIndex(double label); // 得到距离标签最接近的拟合函数下标
    double GetPreDist(double label, double time); // 输入标签和时间预测距离
    double GetPreTime(double label, double d); // 输入标签和距离预测时间
//    CGeoPoint GetBallPrePos(double ball_v, CGeoPoint ball_pos, double ball_dir,double time);

private:
    int Len;
    double Em[6][4];
    ofstream outfile;
    Function* Functions;
    string GetNewDataFilename();
    string NewDataFilename;
};
#endif // LEASTSQUARESFIT_H
