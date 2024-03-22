#ifndef LEASTSQUARESFIT_H
#define LEASTSQUARESFIT_H
#include <cstring>
#include <vector>

using namespace std;

class LeastSquaresfit
{
public:
    LeastSquaresfit();
    double* Fit(double array1[], double array2[]);
private:
    double sum(vector<double> Vnum, int n);
    double MutilSum(vector<double> Vx, vector<double> Vy, int n);
    double RelatePow(vector<double> Vx, int n, int ex);
    double RelateMutiXY(vector<double> Vx, vector<double> Vy, int n, int ex);
    void CalEquation(int exp, double coefficient[]);
    void EMatrix(vector<double> Vx, vector<double> Vy, int n, int ex, double coefficient[]);
    double F(double c[],int l,int m);
    double Em[6][4];
};
#endif // LEASTSQUARESFIT_H
