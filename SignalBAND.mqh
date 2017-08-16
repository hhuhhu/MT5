//+------------------------------------------------------------------+
//|                                                   SignalBAND.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <Indicators\Trend.mqh>
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals of oscillator 'Band'                               |
//| Type=SignalAdvanced                                              |
//| Name=BAND                                                        |
//| ShortName=BAND                                                   |
//| Class=CSignalBAND                                                |
//| Page=signal_BAND                                                 |
//| Parameter=BandsPeriod,int,20,period for average line calculation |
//| Parameter=BandsShift,int,0 , horizontal shift of the indicator   |
//| Parameter=Deviation,double,2.0,  number of standard deviation    |
//| Parameter=Applied,ENUM_APPLIED_PRICE,PRICE_CLOSE,Prices series   |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CSignalBAND.                                               |
//| Purpose: Class of generator of trade signals based on            |
//|          the 'Moving Average Convergence/Divergence' oscillator. |
//| Is derived from the CExpertSignal class.                         |
//+------------------------------------------------------------------+
class CSignalBAND : public CExpertSignal
  {
protected:
   CiBands           m_BAND;           // object-oscillator
   CiDEMA            d_DEMA;
   CiClose           b_close;

   CiOpen            b_open;
   //--- adjusted parameters
   int               bands_period;    // the "period for average line calculation" parameter of the oscillator
   int               bands_shift;    // the "horizontal shift of the indicator" parameter of the oscillator
   double            deviation;  // the "number of standard deviation" parameter of the oscillator
   int               dema_period;
   ENUM_APPLIED_PRICE m_applied;       // the "price series" parameter of the oscillator
   //--- "weights" of market models (0-100)
   int               m_pattern_0;      // model 0 "the oscillator has required direction"
   int               m_pattern_1;      // model 1 "reverse of the oscillator to required direction"
   int               m_pattern_2;      // model 2 "crossing of main and signal line"
   int               m_pattern_3;      // model 3 "crossing of main line an the zero level"
   int               m_pattern_4;      // model 4 "divergence of the oscillator and price"
   int               m_pattern_5;      // model 5 "double divergence of the oscillator and price"
   //--- variables  

public:
                     CSignalBAND(void);
                    ~CSignalBAND(void);
   //--- methods of setting adjustable parameters
   void              BandsPeriod(int value) { bands_period=value;           }
   void              BandsShift(int value) { bands_shift=value;           }
   void              Deviation(double value) { deviation=value;         }
   void DemaPeriod(int value){dema_period=value;}
   void              Applied(ENUM_APPLIED_PRICE value) { m_applied=value;               }
   //--- methods of adjusting "weights" of market models
   void              Pattern_0(int value)              { m_pattern_0=value;             }
   void              Pattern_1(int value)              { m_pattern_1=value;             }
   void              Pattern_2(int value)              { m_pattern_2=value;             }
   void              Pattern_3(int value)              { m_pattern_3=value;             }
   void              Pattern_4(int value)              { m_pattern_4=value;             }
   void              Pattern_5(int value)              { m_pattern_5=value;             }
   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);
   virtual bool      CheckCloseLong(double &price);
   virtual bool      CheckCloseShort(double &price);

protected:
   //--- method of initialization of the oscillator
   bool              InitBAND(CIndicators *indicators);
   //--- methods of getting data
   double            Upper(int ind) { return(m_BAND.Upper(ind));      }
   double            Lower(int ind) { return(m_BAND.Lower(ind));    }
   double            Base(int ind){return(m_BAND.Base(ind));}
   double Dema(int ind){return d_DEMA.Main(ind);}
   double            Close(int ind){return b_close.GetData(ind);}
   double            Open(int ind){return b_open.GetData(ind);}
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalBAND::CSignalBAND(void) : bands_period(20),
                                 bands_shift(0),
                                 deviation(2.0),
                                 m_applied(PRICE_CLOSE),
                                 m_pattern_0(100),
                                 m_pattern_1(100),
                                 m_pattern_2(80),
                                 m_pattern_3(50),
                                 m_pattern_4(60),
                                 m_pattern_5(100)
  {
//--- initialization of protected data
   m_used_series=USE_SERIES_HIGH+USE_SERIES_LOW;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalBAND::~CSignalBAND(void)
  {
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalBAND::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- initial data checks

//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalBAND::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer is performed in the method of the parent class
//---
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- create and initialize BAND oscilator
   if(!InitBAND(indicators))
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Initialize BAND oscillators.                                     |
//+------------------------------------------------------------------+
bool CSignalBAND::InitBAND(CIndicators *indicators)
  {
//--- add object to collection
   if(!indicators.Add(GetPointer(m_BAND)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
//--- initialize object
   if(!m_BAND.Create(m_symbol.Name(),PERIOD_M30,bands_period,bands_shift,deviation,m_applied))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   if(!indicators.Add(GetPointer(d_DEMA)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
   if(!d_DEMA.Create(m_symbol.Name(),PERIOD_D1,dema_period,0,m_applied))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   if(!indicators.Add(GetPointer(b_close)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
   if(!b_close.Create(m_symbol.Name(),m_period))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }
   if(!indicators.Add(GetPointer(b_open)))
     {
      printf(__FUNCTION__+": error adding object");
      return(false);
     }
   if(!b_open.Create(m_symbol.Name(),m_period))
     {
      printf(__FUNCTION__+": error initializing object");
      return(false);
     }

//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Check of the oscillator state.                                   |
//+------------------------------------------------------------------+
//
//+------------------------------------------------------------------+
//| "Voting" that price will grow.                                   |
//+------------------------------------------------------------------+
int temp1=0,temp2=0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CSignalBAND::LongCondition(void)
  {
   int result=0;
   int   idx=StartIndex();
//---White (bull) candle crossed the Lower Band from below to above and DEMA is growing up
   if(Lower(idx)<Close(idx+1) && Open(idx+1)<Lower(idx) && Dema(idx)>Dema(idx+1) && Dema(1)>Dema(idx+2))
     {
      result=m_pattern_0;
     }
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
//| "Voting" that price will fall.                                   |
//+------------------------------------------------------------------+
int CSignalBAND::ShortCondition(void)
  {
   int result=0;
   int idx   =StartIndex();
//--- // Black (bear) candle crossed the Upper Band from above to below and DEMA is growing up
   if(Upper(idx)>Close(idx+1) && Open(idx+1)>Upper(idx) && Dema(idx)<Dema(idx+1) && Dema(idx+1)<Dema(idx+2))
     {
      //--- main line is directed downwards, confirming a possibility of falling of price
      result=m_pattern_1;

     }
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
// Black candle crossed the Upper Band from above to below
bool  CSignalBAND::CheckCloseLong(double &price)
  {
   bool   result=false;
   int idx=StartIndex();
   if(Close(idx+1)<Upper(idx) && Open(idx+1)>Upper(idx))
     {
      result=true;
      //--- try to get the level of closing
      if(!CloseShortParams(price))
         result=false;
     }
//--- zeroize the base price
   m_base_price=0.0;
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// White candle crossed the Lower Band from below to above
bool  CSignalBAND::CheckCloseShort(double &price)
  {
   bool   result=false;
   int   idx=StartIndex();
   if(Close(idx+1)>Lower(idx) && Open(idx+1)<Lower(idx))
     {
      result=true;
      //--- try to get the level of closing
      if(!CloseShortParams(price))
         result=false;
     }
//--- zeroize the base price
   m_base_price=0.0;
//--- return the result
   return(result);
  }
//+------------------------------------------------------------------+
