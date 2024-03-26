#include "LeastSquaresfit.h"
#include <cmath>


namespace{
    double Em[6][4] = {0};
}

LeastSquaresfit::LeastSquaresfit()
{
    NewDataFilename = GetNewDataFilename();
    cout << NewDataFilename << endl;
    outfile.open(NewDataFilename);

    ifstream infile;
    infile.open("fitfunctions/data.txt", ios::in);
    if (!infile.is_open())
    {
        cout << "读取文件失败" << endl;
        return;
    }

    string buf;
    int l = 0;
    double train_t[PARAM::Tick::TickLength];
    double train_d[PARAM::Tick::TickLength];

    while (getline(infile,buf))
    {
        stringstream ss(buf);
        double d, t, label;
        ss >> d >> t;
        if(l == PARAM::Tick::TickLength-1) {
            // TODO:將擬合好的數據存入到類中，現在缺少一個長度來初始化數組。
            train_t[l] = t;
            train_d[l] = d;
            label = train_d[3];
            double* func = Fit(train_t, train_d);
//                FitFunctions.insert(t_d, {func[0], func[1], func[2]});
            cout << "label:" << label << endl;
            cout << func[0] << " " << func[1] << " " << func[2] <<endl;
            l = 0;
        }
        else{
            cout << "l: " << l << endl;
            train_t[l] = t;
            train_d[l++] = d;
            cout << "d: " << d << " ";
            cout << "t: " << t << " ";
        } 
    }
    infile.close();

}

LeastSquaresfit::~LeastSquaresfit(){
    outfile.close();
}

//累加
double sum(vector<double> Vnum, int n)
{
    double dsum=0;
    for (int i=0; i<n; i++)
    {
        dsum+=Vnum[i];
    }
    return dsum;
}

//乘积和
double MutilSum(vector<double> Vx, vector<double> Vy, int n)
{
    double dMultiSum=0;
    for (int i=0; i<n; i++)
    {
        dMultiSum+=Vx[i]*Vy[i];
    }
    return dMultiSum;
}

//ex次方和
double RelatePow(vector<double> Vx, int n, int ex)
{
    double ReSum=0;
    for (int i=0; i<n; i++)
    {
        ReSum+=pow(Vx[i],ex);
    }
    return ReSum;
}

//x的ex次方与y的乘积的累加
double RelateMutiXY(vector<double> Vx, vector<double> Vy, int n, int ex)
{
    double dReMultiSum=0;
    for (int i=0; i<n; i++)
    {
        dReMultiSum+=pow(Vx[i],ex)*Vy[i];
    }
    return dReMultiSum;
}

//供CalEquation函数调用
double F(double c[],int l,int m)
{
    double sum=0;
    for(int i=l;i<=m;i++)
        sum+=Em[l-1][i]*c[i];
    return sum;
}

//求解方程
void CalEquation(int exp, double coefficient[])
{
    for(int k=1;k<exp;k++) //消元过程
    {
        for(int i=k+1;i<exp+1;i++)
        {
            double p1=0;

            if(Em[k][k]!=0)
                p1=Em[i][k]/Em[k][k];

            for(int j=k;j<exp+2;j++)
                Em[i][j]=Em[i][j]-Em[k][j]*p1;
        }
    }
    coefficient[exp]=Em[exp][exp+1]/Em[exp][exp];
    for(int l=exp-1;l>=1;l--)   //回代求解
        coefficient[l]=(Em[l][exp+1]-F(coefficient,l+1,exp))/Em[l][l];
}

//计算方程组的增广矩阵
void EMatrix(vector<double> Vx, vector<double> Vy, int n, int ex, double coefficient[])
{
    for (int i=1; i<=ex; i++)
    {
        for (int j=1; j<=ex; j++)
        {
            Em[i][j]=RelatePow(Vx,n,i+j-2);
        }
        Em[i][ex+1]=RelateMutiXY(Vx,Vy,n,i-1);
    }
    Em[1][1]=n;
    CalEquation(ex,coefficient);
}

//拟合函數
double* LeastSquaresfit::Fit(double arry1[], double arry2[])
{
//    double arry1[5]={1, 2, 3, 4, 5};
//    double arry2[5]={1.2, 3.5, 7.2, 12.1, 18.3};
    double coefficient[5];
    memset(coefficient,0,sizeof(double)*5);
    vector<double> vx,vy;
    for (int i=0; i<PARAM::Tick::TickLength; i++)
    {
        vx.push_back(arry1[i]);
        vy.push_back(arry2[i]);
    }
    EMatrix(vx,vy,PARAM::Tick::TickLength,3,coefficient);
//    printf("拟合方程为：y = %lf + %lfx + %lfx^2 \n",coefficient[1],coefficient[2],coefficient[3]);
    double* result = new double[3];
    result[0] = coefficient[1];
    result[1] = coefficient[2];
    result[2] = coefficient[3];

    return result;
}

// 採集訓練數據
void LeastSquaresfit::GetFitData(GlobalTick* Tick)
{
    if (Tick[1].ball_vel > 0 && Tick[0].ball_vel == 0)
    {
        double t = 0;
//        ofstream outfile(NewDataFilename);
        for (int i = 0; i < PARAM::Tick::TickLength;i++)
        {
            t += Tick[i].delta_time;
            // 写入内容
            outfile << to_string((Tick[i].ball_pos - Tick[0].ball_pos).mod()) + " " + to_string(t) << endl;

        }
//        outfile.close();
    }
}
// 獲取文件名
string LeastSquaresfit::GetNewDataFilename()
{
    int i = 0;
    string filename;
    while (true)
    {
        i++;
        filename = "fitfunctions/fitdata" + to_string(i) +".txt";
        ifstream infile;
        infile.open(filename, ios::in);
        if(!infile.is_open())
            break;
    }
    return filename;
}
