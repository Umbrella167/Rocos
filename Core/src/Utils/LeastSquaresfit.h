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

class LeastSquaresfit
{
public:
    LeastSquaresfit();
    ~LeastSquaresfit();
    double* Fit(double array1[], double array2[]); //擬合函數
    void GetFitData(GlobalTick* Tick); //採集訓練數據
    ofstream outfile;
    CGeoPoint GetBallPrePos(double ball_v, CGeoPoint ball_pos, double ball_dir,double time);
    double* Funckey;

private:
    double Em[6][4];
    string GetNewDataFilename();
    string NewDataFilename;
};
#endif // LEASTSQUARESFIT_H
