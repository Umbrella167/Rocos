#ifndef LEASTSQUARESFIT_H
#define LEASTSQUARESFIT_H
#include <iostream>
#include <vector>
#include <cmath>
#include <cstring>
using namespace std;

class LeastSquaresfit
{
public:
    LeastSquaresfit();
    int Fit();
private:
    double sum(vector<double> Vnum, int n);
    double MutilSum(vector<double> Vx, vector<double> Vy, int n);
    double RelatePow(vector<double> Vx, int n, int ex);
    double RelateMutiXY(vector<double> Vx, vector<double> Vy, int n, int ex);
    void CalEquation(int exp, double coefficient[]);
    void EMatrix(vector<double> Vx, vector<double> Vy, int n, int ex, double coefficient[]);
    double F(double c[],int l,int m);

};
#endif // LEASTSQUARESFIT_H
