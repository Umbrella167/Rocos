# 代码规范以及基础框架

* 随笔：
  * C++层写算法，Lua层写逻辑
  * 将框架内所有计算好的数据都塞进一个世界函数内，lua按需拿数据
  * 一切算法与写法都得考虑效率
  * 所有参数、模型一个放在同一个文件调节
  * 关于防守点位：应该更倾向于能 够截球 + 进攻转换的点位
  * 跑位点与传球点应该考虑未来
  * 合理利用敌方惯性思维，比敌人多算一步
  * 合理使用战术解球，控球没有机会时可以尝试让敌方犯规
  * 所有的物理模型都是为了建立时间模型
  * shoot_confidence 
  * PosLife = PosSafety + PosFeasibility 
  * 敌方平均速度、我方平均速度、在某种速度的条件下、获取点位
  * 最佳射门点：距离射门位置越进越好、射门角度越接近90度越好、越安全越好（安全：起点到终点构成的线段被敌人影响的...）
* 命名规则：
  * Lua
    * 函数： 小驼峰命名法
    * 变量：小写 + 下划线命名法
    
  * C++
    * 函数：大驼峰命名法
    * 变量：小写 + 下划线命名法
* 函数介绍（待定）：
  * C++
    * 全局函数
      * GlobalComputingPos()       --遍历全图并计算所有数据打包发给lua
    
    * 获取类(算点)
      * GetAttackGrade(pos)      --返回坐标关于跑位点的评分并记录
      * GetShootConfidence(pos)  --返回某坐标射门成功的置信度
      * GetDefineGrade(pos)      --返回某坐标关于防守点的评分并记录
      * GetInterceptPos(pos)     --返回最佳截球点坐标
      * GetShootPos(pos)	  --返回某坐标的最佳射门点
    * 获取类(工具函数)
      * GetPosLife(pos)          --评估坐标寿命
      * GetPosToPosTime(player_pos,pos,velocity)  --获取坐标到坐标的时间

    * 几何规则评分类
      * PosToEnemyDistGrade(pos,dir)    --返回坐标与敌人距离的评分
      * PosToBallDistGrade(pos,dir)     --返回坐标与球距离的评分
      * PosShootDirGrade(pos,dir)       --返回坐标的射门角度的评分
      
      
    * detial
      NumberNormalize(double data, double max_data,double min_data); // [0,1] 标准化
      NumberNormalizeGauss(double data, double max_data, double min_data, double peak_pos, std::string model = "DOUBLELINE"); // [0,1] 高斯归一化
      map(double value, double min_in, double max_in, double min_out, double max_out); // 映射
      IsExclusionZone(double x,double y); // 判断点是否在禁区内
      PosToBallDistGrade(const CVisionModule *pVision,double x, double y,int dir); // 坐标到球的距离评分
* 物理公式：
  * $$t = x / v$$
  * $$v = (v_0^2 - 2ax) ^ {(1/2)}$$
  * $$v^2 = 2ax$$
