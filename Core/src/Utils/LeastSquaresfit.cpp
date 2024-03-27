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

    FitFromFile("fitfunctions/data.txt");
    GetClosestLabelIndex(100);
}

LeastSquaresfit::~LeastSquaresfit(){
    outfile.close();
}
// 从文件中拟合函数
void LeastSquaresfit::FitFromFile(string filename) {
    ifstream infile;
    infile.open(filename, ios::in);
    if (!infile.is_open())
    {
        cout << "读取文件失败" << endl;
        return;
    }

    // 获取训练的速度数量
    ifstream t(filename, ios::in);
    Len = 0;
    string buf;
    while (getline(t, buf)) {
        Len++;
    }
    Len = Len / PARAM::Tick::TickLength;

    Function tFunctions[Len];
    int l = 0;
    int ll = 0;
    double train_t[PARAM::Tick::TickLength];
    double train_d[PARAM::Tick::TickLength];
    // 拟合不同速度下的函数
    while (getline(infile,buf))
    {
        stringstream ss(buf);

        double d, t;
        ss >> d >> t;
        if(l == PARAM::Tick::TickLength-1) {
            train_t[l] = t;
            train_d[l] = d;

            double* func = Fit(train_t, train_d);
            tFunctions[ll].label = train_d[PARAM::Fit::FitLabel];
            tFunctions[ll].c = func[0];
            tFunctions[ll].b = func[1];
            tFunctions[ll++].a = func[2];

            l = 0;
        }
        else{
            train_t[l] = t;
            train_d[l++] = d;
        }
    }

    Functions = tFunctions;
    for(int i=0;i<Len;i++){
        cout<< Functions[i].label << endl;
        cout<< Functions[i].a << " " << Functions[i].b << " " << Functions[i].c << endl;
    }
    infile.close();
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
        for (int i = 0; i < PARAM::Tick::TickLength;i++)
        {
            t += Tick[i].delta_time;
            // 写入内容
            outfile << to_string((Tick[i].ball_pos - Tick[0].ball_pos).mod()) + " " + to_string(t) << endl;
        }
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
// 得到距离标签最接近的拟合函数下标
int LeastSquaresfit::GetClosestLabelIndex(double label) {
    double minDiff = 1e9;
    double minIndex = 0;
    for(int i=0;i<Len;i++){
        cout << Functions[i].label << endl;
        if(abs(label - Functions[i].label) < minDiff){
            minDiff = abs(label - Functions[i].label);
            minIndex = i;
        }
    }

    cout << "res: " << minIndex << endl;
    return minIndex;
}
