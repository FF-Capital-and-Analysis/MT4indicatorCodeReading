//+------------------------------------------------------------------+
//|                                                  Custom MACD.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Moving Averages Convergence/Divergence"
#property strict

#include <MovingAverages.mqh>

//--- indicator settings 指标属性的设置
#property  indicator_separate_window    //独立窗口，副图显示
#property  indicator_buffers 2			//2个缓冲区分配内存,有方向指向意义（最多为8个[0,7]）
#property  indicator_color1  Silver		//银色	
#property  indicator_color2  Red        //红色
#property  indicator_width1  2 			//线宽
//--- indicator parameters 指标参数
input int InpFastEMA=12;   // Fast EMA Period 快线
input int InpSlowEMA=26;   // Slow EMA Period 慢线
input int InpSignalSMA=9;  // Signal SMA Period 平均信号周期
//--- indicator buffers 2个缓冲数组变量定义
double    ExtMacdBuffer[];           //线数组，第1个缓冲区,索引为0
double    ExtSignalBuffer[];         //柱数组，第2个缓冲区,索引为1
//--- right input parameters flag 	 //输入参数标志
bool      ExtParameters=false; 		 //初始化拓展参数=假

//+-------------------------------------------------------------------+
//| Custom indicator initialization function 自定义指标初始化功能 代码区 |
//+-------------------------------------------------------------------+
int OnInit(void)
  {
   IndicatorDigits(Digits+1);   //指标精度格式（小数点后的位数计数），当前标的的小数位数+1，货币为5或3，黄金原油为2，后+1
//--- drawing settings 为指标在副图上画线设置相关参数，包括类型、样式、宽度和颜色
   SetIndexStyle(0,DRAW_HISTOGRAM);      //第1个，0号索引位，绘制柱状
   SetIndexStyle(1,DRAW_LINE);           //第2个，1号索引位，绘制曲线
   SetIndexDrawBegin(1,InpSignalSMA);	 //设置指标线起始位置，从左向右根据K线画，第2个，从左边第9根K线向当前K线画,这里InpSignalSMA=9
//--- indicator buffers mapping 为指标画线与缓冲区连接映射
   SetIndexBuffer(0,ExtMacdBuffer);      //第1个缓冲区,索引为0,绑定第1个，0号索引位，绘制柱状
   SetIndexBuffer(1,ExtSignalBuffer);    //第2个缓冲区,索引为1,绑定第2个，1号索引位，绘制曲线
//--- name for DataWindow and indicator subwindow label   //副图窗口设置命名和指标实时参数的标签
   IndicatorShortName("MACD("+IntegerToString(InpFastEMA)+","+IntegerToString(InpSlowEMA)+","+IntegerToString(InpSignalSMA)+")");  //指标窗口命名显示，并转换成字符串拼接起来,如MACD(12,26,9)
   SetIndexLabel(0,"MACD");   		//第1个缓冲区,索引为0,绑定第1个，0号索引位，绘制柱状将标签为MCAD
   SetIndexLabel(1,"Signal"); 		//第2个缓冲区,索引为1,绑定第2个，1号索引位，绘制曲线将标签为Signal
//--- check for input parameters 	//检查输入的初始参数
   if(InpFastEMA<=1 || InpSlowEMA<=1 || InpSignalSMA<=1 || InpFastEMA>=InpSlowEMA)  //快、慢、信号线不能小于等于1，快线不能大于等于慢线（时间短，反应快;时间长，反应慢）
     {
      Print("Wrong input parameters"); //日志栏输出Wrong input parameters
      ExtParameters=false; 		//初始化拓展参数还是=假
      return(INIT_FAILED);      //返回初始化失败
     }
   else
      ExtParameters=true;        //初始化拓展参数还是=真
//--- initialization done		 //初始参数通过
   return(INIT_SUCCEEDED);		 //返回初始化成功
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence 移动平均聚散               |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,      //当前图形上K线的总个数
                 const int prev_calculated,  //上次计算到第几根K线了
                 const datetime& time[],	 //内置时间数组
                 const double& open[],		 //内置开盘价数组
                 const double& high[],		 //内置最高价数组
                 const double& low[],		 //内置最低价数组
                 const double& close[],		 //内置收盘价数组
                 const long& tick_volume[],	 //内置单位时间内的Tciku时序数组
                 const long& volume[],		 //内置成交量数组
                 const int& spread[])		 //内置点差数组
  {
   int i,limit;   //初始化i,limit
//---
   if(rates_total<=InpSignalSMA || !ExtParameters)  //图表上显示的K线总数<=InpSignalSMA９时或ExtParameters为假时，返回最后的K线数量
      return(0);
//--- last counted bar will be recounted   //返回最后被计算的K线数量  --->> K线是一根根的产生的,如果不动图表窗口,limit始终为1
   limit=rates_total-prev_calculated;      //图表上显示的K线总数-前面已经计算过的数量=得出剩下将要计算的K线数量
   if(prev_calculated>0)				   //前面已经计算过的数量存在且大于0时，要计算的K线始终循环进行
      limit++;
//--- macd counted in the 1-st buffer      //第1个缓冲区MACD计算
   for(i=0; i<limit; i++)  				   //循环还在计算的K线数量limit值，并存入缓冲区冲  —->>借助MA均线计算函数来计算
      ExtMacdBuffer[i]=iMA(NULL,0,InpFastEMA,0,MODE_EMA,PRICE_CLOSE,i)-     //当前标的、当前时间框架、12根K线的、不平移、指数平均算法、应用收盘价、0索引为当前
                    iMA(NULL,0,InpSlowEMA,0,MODE_EMA,PRICE_CLOSE,i);
//--- signal line counted in the 2-nd buffer    //12大于9，所以在前面ExtMacdBuffer的基础上进行计算
   SimpleMAOnBuffer(rates_total,prev_calculated,0,InpSignalSMA,ExtMacdBuffer,ExtSignalBuffer);   //SimpleMAOnBuffer函数引用自<MovingAverages.mqh>，将来自 price[] 数组的简单移动平均线的值输出到数组 ExtSignalBuffer[]中
//--- done
   return(rates_total);    //返回K线总量
  }
//+------------------------------------------------------------------+
