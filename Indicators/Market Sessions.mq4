/*
   ________________________________________________________________________________
   
   NAME: Market Sessions.mq4
   
   AUTHOR: Adam Jowett
   VERSION: 1.3
   DATE: 26 July 2014
   METAQUOTES LANGUAGE VERSION: 4.0
   UPDATES & MORE DETAILED DOCUMENTATION AT: 
   http://adamjowett.com/category/trading/downloads/
   ________________________________________________________________________________

   The MIT License (MIT)

   Copyright (c) 2014 Adam Jowett
   
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
   
   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
*/

#property copyright "Copyright © 2014, Adam Jowett"
#property link      "http://adamjowett.com"

#property indicator_chart_window

extern string     __ = "Times in 24hr GMT time. Enter -1 to disable a line";
extern string     sydney = "22:00";
extern string     tokyo = "23:00";
extern string     london = "8:00";
extern string     newyork = "12:00";
extern int        gmtServerOffset = 0;
extern bool       showFutureSessions = true;
extern bool       showOpenPrice = true;
extern bool       showPreviousRange = true;
extern int        maxTimeframe = PERIOD_M15;
extern color      tokyoColour = DeepSkyBlue;
extern color      sydneyColour = Plum;
extern color      londonColour = Magenta;
extern color      newYorkColour = Gold;
extern color      futureSessionColour = DimGray;

string prefix = "market_sessions_";
int lastSydneySession = -1;
int lastTokyoSession = -1;
int lastLondonSession = -1;
int lastNewYorkSession = -1;
int sessionLength = 0;
double gmtOffset = 0;
int oneHour = 3600; // 60 seconds x 60 minutes = 1 hour
int oneDay = 86400; // oneHour * 24;
int sydneyHour;
int tokyoHour;
int newyorkHour;
int londonHour;
int sydneyMinute;
int tokyoMinute;
int nyMinute;
int londonMinute;

int init()
{
   sessionLength = Period() * 60 * ((60 / Period()) * 9);
   
   sydneyHour = getHour(sydney);
   tokyoHour = getHour(tokyo);
   newyorkHour = getHour(newyork);
   londonHour = getHour(london);
   
   sydneyMinute = getMinute(sydney);
   tokyoMinute = getMinute(tokyo);
   londonMinute = getMinute(london);
   nyMinute = getMinute(newyork);
   
   if (sydneyHour > -1)
   {
      sydneyHour = sydneyHour + gmtServerOffset;
      if (sydneyHour > 23) sydneyHour = sydneyHour - 24;
      if (sydneyHour < 0) sydneyHour = sydneyHour + 24;
   }
   
   if (tokyoHour > -1)
   {
      tokyoHour = tokyoHour + gmtServerOffset;
      if (tokyoHour > 23) tokyoHour = tokyoHour - 24;
      if (tokyoHour < 0) tokyoHour = tokyoHour + 24;
   }
   
   if (londonHour > -1)
   {
      londonHour = londonHour + gmtServerOffset;
      if (londonHour > 23) londonHour = londonHour - 24;
      if (londonHour < 0) londonHour = londonHour + 24;
   }
   
   if (newyorkHour > -1)
   {
      newyorkHour = newyorkHour + gmtServerOffset;
      if (newyorkHour > 23) newyorkHour = newyorkHour - 24;
      if (newyorkHour < 0) newyorkHour = newyorkHour + 24;
   }
   
   return(0);
}

int deinit()
{
   clearScreen(prefix, true, NULL);
   return(0);
}

int start()
{
   if (Bars <= 10) return(0);
   
   if (Period() > maxTimeframe) {
      clearScreen(prefix, true, NULL);
      Comment("Market Sessions will only show on " + maxTimeframe + " or lower");
      return(0);
   }

   int counted = IndicatorCounted();
   if (counted < 0) return(-1);
   if (counted > 0) counted--;
   
   int i = Bars - counted;
   int timeRange = 0;
   double rangeHigh = 0;
   double rangeLow = 0;
   double rangeMid = 0;
   
   while (i >= 0)
   {
      int currentTime = Time[i];
      int dayNumber = TimeDayOfWeek(currentTime) + 1;
      
      if (TimeHour(currentTime) == sydneyHour && TimeMinute(currentTime) == sydneyMinute)
      {
         ObjectDelete(prefix + "future_line" + lastSydneySession);
         lastSydneySession = currentTime;
         
         drawVerticalLine(prefix + "sydneyTimeOpen"+i, currentTime, 1, sydneyColour, 3, true, "Sydney open  [" + sydney + " + " + gmtServerOffset + "]");
         if (showOpenPrice) drawTrendLine(prefix +"sydneyopen" + i, currentTime, currentTime + sessionLength, Open[i], Open[i], 1, sydneyColour, 4, true, false, DoubleToStr(Open[i], Digits));
         if (showPreviousRange) {
            timeRange = iBarShift(NULL, 0, lastNewYorkSession) - iBarShift(NULL, 0, currentTime) - 1;
            rangeHigh = High[iHighest(NULL, 0, MODE_HIGH, timeRange, i + 1)];
            rangeLow = Low[iLowest(NULL, 0, MODE_LOW, timeRange, i + 1)];
			   rangeMid = rangeLow + (rangeHigh - rangeLow) / 2;
            
            drawTrendLine(prefix + "nyRangeHigh" + i, currentTime, currentTime + sessionLength, rangeHigh, rangeHigh, 1, DimGray, 2, true, false, "");
            drawTrendLine(prefix + "nyRangeLow" + i, currentTime, currentTime + sessionLength, rangeLow, rangeLow, 1, DimGray, 2, true, false, ""); 
         }
      } 
      else if (TimeHour(currentTime) == tokyoHour && TimeMinute(currentTime) == tokyoMinute)
      {
         ObjectDelete(prefix + "future_line" + lastTokyoSession);
         lastTokyoSession = currentTime;

         drawVerticalLine(prefix + "line"+i, currentTime, 1, tokyoColour, 3, true, "Tokyo open  [" + tokyo + " + " + gmtServerOffset + "]");
         if (showOpenPrice) drawTrendLine(prefix +"tokyoopen" + i, currentTime, currentTime + sessionLength, Open[i], Open[i], 1, tokyoColour, 4, true, false, DoubleToStr(Open[i], Digits));
      }
      else if (TimeHour(currentTime) == londonHour && TimeMinute(currentTime) == londonMinute)
      {
         ObjectDelete(prefix + "future_line" + lastLondonSession);
         lastLondonSession = currentTime;
         
         drawVerticalLine(prefix + "line"+i, currentTime, 1, londonColour, 3, true, "London open  [" + london + " + " + gmtServerOffset + "]");
         if (showOpenPrice) drawTrendLine(prefix +"londonoopen" + i, currentTime, currentTime + sessionLength, Open[i], Open[i], 1, londonColour, 4, true, false, DoubleToStr(Open[i], Digits));
         if (showPreviousRange) {
            timeRange = iBarShift(NULL, 0, lastSydneySession) - iBarShift(NULL, 0, currentTime) - 1;
            rangeHigh = High[iHighest(NULL, 0, MODE_HIGH, timeRange, i + 1)];
            rangeLow = Low[iLowest(NULL, 0, MODE_LOW, timeRange, i + 1)];
            
            drawTrendLine(prefix + "asianRangeHigh" + i, currentTime, currentTime + sessionLength, rangeHigh, rangeHigh, 1, DimGray, 2, true, false, "");
            drawTrendLine(prefix + "asianRangeLow" + i, currentTime, currentTime + sessionLength, rangeLow, rangeLow, 1, DimGray, 2, true, false, ""); 
         }
      }
      else if (TimeHour(currentTime) == newyorkHour && TimeMinute(currentTime) == nyMinute)
      {
         ObjectDelete(prefix + "future_line" + lastNewYorkSession);
         lastNewYorkSession = currentTime;
 
         drawVerticalLine(prefix + "line"+i, currentTime, 1, newYorkColour, 3, true, "New York open  [" + newyork + " + " + gmtServerOffset + "]");
         if (showOpenPrice) drawTrendLine(prefix +"newyorkopen" + i, currentTime, currentTime + sessionLength, Open[i], Open[i], 1, newYorkColour, 4, true, false, DoubleToStr(Open[i], Digits));
         if (showPreviousRange) {
            timeRange = iBarShift(NULL, 0, lastLondonSession) - iBarShift(NULL, 0, currentTime) - 1;
            rangeHigh = High[iHighest(NULL, 0, MODE_HIGH, timeRange, i + 1)];
            rangeLow = Low[iLowest(NULL, 0, MODE_LOW, timeRange, i + 1)];
            
            drawTrendLine(prefix + "ukRangeHigh" + i, currentTime, currentTime + sessionLength, rangeHigh, rangeHigh, 1, DimGray, 2, true, false, "");
            drawTrendLine(prefix + "ukRangeLow" + i, currentTime, currentTime + sessionLength, rangeLow, rangeLow, 1, DimGray, 2, true, false, ""); 
         }
      }
      
      i--;      
   }
   
   if (showFutureSessions) {
      if (DayOfWeek() == 1) { // if on a Monday, weekends throw things out
         drawFutureSession(lastSydneySession + oneDay, "Sydney open  [" + sydney + " + " + gmtServerOffset + "]");
         drawFutureSession(lastTokyoSession + oneDay - oneHour * (MathAbs(sydneyHour - tokyoHour)), "Tokyo open  [" + tokyo + " + " + gmtServerOffset + "]");
         drawFutureSession(lastLondonSession + oneDay - oneHour * (MathAbs(sydneyHour - londonHour)), "London open  [" + london + " + " + gmtServerOffset + "]");
         drawFutureSession(lastSydneySession + oneDay - oneHour * (MathAbs(sydneyHour - newyorkHour)), "New York open  [" + newyork + " + " + gmtServerOffset + "]");
      } else {
         drawFutureSession(lastSydneySession + oneDay, "Sydney open  [" + sydney + " + " + gmtServerOffset + "]");
         drawFutureSession(lastTokyoSession + oneDay, "Tokyo open  [" + tokyo + " + " + gmtServerOffset + "]");
         drawFutureSession(lastLondonSession + oneDay, "London open  [" + london + " + " + gmtServerOffset + "]");
         drawFutureSession(lastNewYorkSession + oneDay, "New York open  [" + newyork + " + " + gmtServerOffset + "]");
      } 
   }

   return(0);
}

int getHour (string timeString) {
   string result[];
   string needle = ":";
   string u_needle = StringGetCharacter(needle,0);
   int k = StringSplit(timeString, u_needle, result);
   
   if (k > 0) return result[0];
   
   return -1;
}

int getMinute (string timeString) {
   string result[];
   string needle = ":";
   string u_needle = StringGetCharacter(needle,0);
   int k = StringSplit(timeString, u_needle, result);
   
   if (k > 0) {
      if (StringLen(result[1]) > 0 ) {
         return result[1];
      } else {
         return 0;
      }
   }
}

void drawFutureSession(datetime prevSession, string label) 
{
   datetime futureTime = prevSession;
   drawVerticalLine(prefix + "future_line" + prevSession, futureTime, 1, futureSessionColour, 4, true, label);
}

void drawVerticalLine(string name, datetime time, int thickness, color colour, int style, bool background, string label = "") 
{ 
   long current_chart_id=ChartID();
   
   if (ObjectFind(name) != 0) 
   {
      ObjectCreate(current_chart_id, name, OBJ_VLINE, 0, time, 0);
   } 
   else 
   { 
      ObjectSet(name, OBJPROP_TIME1, time);
   }
   
   ObjectSet(name,OBJPROP_COLOR, colour);
   ObjectSet(name,OBJPROP_WIDTH, thickness);
   ObjectSet(name, OBJPROP_BACK, background);
   ObjectSet(name, OBJPROP_STYLE, style);
   
   ObjectSetText(name, label, 8, "Arial", colour);
}

void drawTrendLine(string name, double time1, double time2, double price1, double price2, int thickness, color colour, int style, bool background, bool ray, string label = "") 
{
   if (ObjectFind(name) != 0) 
   {
      ObjectCreate(name, OBJ_TREND, 0, time1, price1, time2, price2);
      ObjectSet(name,OBJPROP_RAY,ray);
   
   } 
   else 
   {
      ObjectSet(name, OBJPROP_TIME1, time1);
      ObjectSet(name, OBJPROP_TIME2, time2);
      ObjectSet(name, OBJPROP_PRICE1, price1);
      ObjectSet(name, OBJPROP_PRICE2, price2);
   }

   ObjectSet(name,OBJPROP_COLOR, colour);
   ObjectSet(name,OBJPROP_WIDTH, thickness);
   ObjectSet(name,OBJPROP_BACK, background);
   ObjectSet(name,OBJPROP_STYLE, style);  
   ObjectSetText(name, label, 8);
}

string getDayName(int dayNumber)
{
   string days[7] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
   return (days[dayNumber]);
}

void clearScreen(string pref, bool clearComments, string exception)
{   
   if (clearComments) Comment("");
   
   int i;
   string name = "";

   for (i = ObjectsTotal(); i >= 0; i--) 
   {
      name = ObjectName(i);
      if (StringFind(name, pref, 0) > -1) 
      {
         if (exception == "0" || StringFind(name, exception,0) == -1) ObjectDelete(name);
      } 
   }
}