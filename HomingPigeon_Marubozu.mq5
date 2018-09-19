//+-----------------------------------------------------------------+
//|                                      HomingPigeon_Marubozu.mq5 |
//|                      Copyright 2018, InvestDataSystems@Yahoo.Com|
//|                            https://ichimoku-expert.blogspot.com |
//+-----------------------------------------------------------------+

#property copyright "Copyright 2018, Investdata Systems"
#property link      "https://tradingbot.wixsite.com/trading-bot"
#property version   "1.03"

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

CAccountInfo accountInfo;
double initialEquity = 0;
double currentEquity = 0;

//input bool exportPrices=false;
int file_handle=INVALID_HANDLE; // File handle
input int scanPeriod=5;

string appVersion="1.0";
string versionInfo="Scans for identical past candlesticks.";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//CloseAllPositions();

   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0')+":"+IntegerToString(mqd.sec,2,'0');

   string output="";
   output = timestamp + " Starting " + StringSubstr(__FILE__,0,StringLen(__FILE__)-4);
   output = output + " App version : " + appVersion + " Investdata Systems";
   output = output + " Version info : " + versionInfo;
   output = output + " https://ichimoku-expert.blogspot.com/";
   printf(output);
//SendNotification(output);

   ObjectsDeleteAll(0,"",-1,-1);

   EventSetTimer(scanPeriod); // 30 secondes pour tout (pas seulement marketwatch)

   initialEquity=accountInfo.Equity();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   EventKillTimer();

  }

ENUM_TIMEFRAMES workingPeriod=Period();
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   return;
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
datetime allowed_until=D'2018.12.15 00:00';
bool expiration_notified=false;
bool done=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(done==false)
     {
      Scan();
      done=true;
     }
  }

static int BARS;

bool first_run_done;

static datetime LastBarTime=-1;

int maxhisto=4096;

bool initdone=false;

double open_array[];
double high_array[];
double low_array[];
double close_array[];

int handle;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Scan()
  {
   int numO=-1,numH=-1,numL=-1,numC=-1;

   ArraySetAsSeries(open_array,true);
   numO=CopyOpen(Symbol(),workingPeriod,0,maxhisto,open_array);

   ArraySetAsSeries(high_array,true);
   numH=CopyHigh(Symbol(),workingPeriod,0,maxhisto,high_array);

   ArraySetAsSeries(low_array,true);
   numL=CopyLow(Symbol(),workingPeriod,0,maxhisto,low_array);

   ArraySetAsSeries(close_array,true);
   numC=CopyClose(Symbol(),workingPeriod,0,maxhisto,close_array);

/*if(open_array[1]<close_array[1])
     {
      FindIdenticalBullishCandlestick(open_array[1],close_array[1],high_array[1],low_array[1]);
     }*/

//FindBullishMarubozu();

   FindBullishHomingPigeon();

   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   IndicatorRelease(handle);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FindBullishHomingPigeon()
  {
   int start=0; // bar index
   int count=maxhisto; // number of bars
   datetime tm[]; // array storing the returned bar time
   ArraySetAsSeries(tm,true);
   CopyTime(Symbol(),workingPeriod,start,count,tm);
   
   for(int i=1;i<maxhisto-1;i++)
     {
      //printf(i+" : "+tm[i]);
      if (close_array[i+1]>open_array[i+1] && close_array[i]>open_array[i])
      {
         if (close_array[i+1]>close_array[i] && open_array[i+1]<open_array[i])
         {
            printf("Homing Pigeon (HP) found at " + tm[i+1] + " and " + tm[i]); 
         }         
      }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void FindBullishMarubozu()
  {
//rechercher les bougies haussières antérieures qui n'ont pas de mèches hautes ni basses
   for(int i=1;i<maxhisto;i++)
     {
      if(close_array[i]>open_array[i])
        {
         if(high_array[i]==close_array[i] && open_array[i]==low_array[i])
           {
            //--- variables for function parameters
            int start=0; // bar index
            int count=maxhisto; // number of bars
            datetime tm[]; // array storing the returned bar time
            ArraySetAsSeries(tm,true);
            //--- copy time 
            CopyTime(Symbol(),workingPeriod,start,count,tm);
            //--- output result
            printf("une bougie Marubozu Haussière a été trouvée : "+tm[i]);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// Recherche toutes les bougies antérieures à la bougie précédente qui ont les mêmes caractéristiques que la bougie précédente
void FindIdenticalBullishCandlestick(double open,double close,double high,double low)
  {
//rechercher les bougies haussières antérieures identiques
   double diff_high_close = high-close;
   double diff_close_open = close-open;
   double diff_open_low=open-low;
   for(int i=2;i<maxhisto;i++)
     {
      double diff_high_close_i = high_array[i]-close_array[i];
      double diff_close_open_i = close_array[i]-open_array[i];
      double diff_open_low_i=open_array[i]-low_array[i];

      if(diff_high_close==diff_high_close_i && diff_close_open==diff_close_open_i && diff_open_low==diff_open_low_i)
        {
         //--- variables for function parameters
         int start=0; // bar index
         int count=maxhisto; // number of bars
         datetime tm[]; // array storing the returned bar time
         ArraySetAsSeries(tm,true);
         //--- copy time 
         CopyTime(Symbol(),workingPeriod,start,count,tm);
         //--- output result
         printf("une bougie antérieure identique a été trouvée : "+tm[i]+" identique à la bougie précédente de : "+tm[1]);
         printf("open_i="+NormalizeDouble(open_array[i],5)+" close_i="+NormalizeDouble(close_array[i],5)+" high_i="+NormalizeDouble(high_array[i],5)+" low_i="+NormalizeDouble(low_array[i],5));
         printf("diff_high_close_i="+NormalizeDouble(diff_high_close_i,5)+" diff_close_open_i="+NormalizeDouble(diff_close_open_i,5)+" diff_open_low_i="+NormalizeDouble(diff_open_low_i,5));
         printf("open="+NormalizeDouble(open,5)+" close="+NormalizeDouble(close,5)+" high="+NormalizeDouble(high,5)+" low="+NormalizeDouble(low,5));
         printf("diff_high_close="+NormalizeDouble(diff_high_close,5)+" diff_close_open="+NormalizeDouble(diff_close_open,5)+" diff_open_low="+NormalizeDouble(diff_open_low,5));
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getTimestamp()
  {
   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp=string(mqd.year)+"-"+IntegerToString(mqd.mon,2,'0')+"-"+IntegerToString(mqd.day,2,'0')+" "+IntegerToString(mqd.hour,2,'0')+":"+IntegerToString(mqd.min,2,'0');//+":"+IntegerToString(mqd.sec,2,'0')+":"+GetTickCount();
   return timestamp;
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---

  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//---

  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
   double ret=0.0;
   return(ret);
  }
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit()
  {
  }
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass()
  {
  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
  }
//+------------------------------------------------------------------+

/*void Scan()
  {

   datetime ThisBarTime=(datetime)SeriesInfoInteger(Symbol(),workingPeriod,SERIES_LASTBAR_DATE);
   if(ThisBarTime==LastBarTime)
     {
      //printf("Same bar time ("+Symbol()+")");
     }
   else
     {
      if(LastBarTime==-1)
        {
         //printf("First bar ("+Symbol()+")");
         LastBarTime=ThisBarTime;
        }
      else
        {
         //printf("New bar time ("+Symbol()+")");
         LastBarTime=ThisBarTime;

         int numO=-1,numH=-1,numL=-1,numC=-1;

         ArraySetAsSeries(open_array,true);
         numO=CopyOpen(Symbol(),workingPeriod,0,maxhisto,open_array);

         ArraySetAsSeries(high_array,true);
         numH=CopyHigh(Symbol(),workingPeriod,0,maxhisto,high_array);

         ArraySetAsSeries(low_array,true);
         numL=CopyLow(Symbol(),workingPeriod,0,maxhisto,low_array);

         ArraySetAsSeries(close_array,true);
         numC=CopyClose(Symbol(),workingPeriod,0,maxhisto,close_array);

         if(open_array[1]<close_array[1])
           {
            FindIdenticalBullishCandlestick(open_array[1],close_array[1],high_array[1],low_array[1]);
           }

        }
     }

   ArrayFree(open_array);
   ArrayFree(close_array);
   ArrayFree(high_array);
   ArrayFree(low_array);

   IndicatorRelease(handle);

  }
*/
//+------------------------------------------------------------------+
