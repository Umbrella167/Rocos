#ifndef LEASTSQUARESFIT_H
#define LEASTSQUARESFIT_H
#include "geometry.h"
#include "staticparams.h"
#include "WorldModel.h"
#include <cstring>
#include <vector>
#include <map>

using namespace std;

class LeastSquaresfit
{
public:
    LeastSquaresfit(bool reBuild);
    double* Fit(double array1[], double array2[]); //擬合函數
    void GetFitData(GlobalTick* Tick); //採集訓練數據


    CGeoPoint GetBallPrePos(double ball_v, CGeoPoint ball_pos, double ball_dir,double time);
    double* Funckey;

private:
    double sum(vector<double> Vnum, int n);
    double MutilSum(vector<double> Vx, vector<double> Vy, int n);
    double RelatePow(vector<double> Vx, int n, int ex);
    double RelateMutiXY(vector<double> Vx, vector<double> Vy, int n, int ex);
    void CalEquation(int exp, double coefficient[]);
    void EMatrix(vector<double> Vx, vector<double> Vy, int n, int ex, double coefficient[]);
    double F(double c[],int l,int m);
    double Em[6][4];
    string GetDataFilename();
    string DataFilename;
};
#endif // LEASTSQUARESFIT_H
