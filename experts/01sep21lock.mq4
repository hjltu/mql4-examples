//+------------------------------------------------------------------+
//|                                                  01sep21lock.mq4 |
//|                                             Copyright 2021,hjltu |
//|                                                      hjltu@ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,hjltu"
#property link      "hjltu@ya.ru"
#property version   "1.00"
#property strict
#property description   "Inputs:\n"
                        "   magik: magik number(11)\n"
                        "   lot: order's volume(0.01)\n"
                        "   tick: Exec by tick or by timer(true)\n"
                        "   close_loss: Close orders with loss(true)\n"
                        "   close_profit: Close orders with profit(false)\n"
                        "   period: timeframe, minutes(60)\n"
                        "   depth: number of the candles to find medial(22)"
int             ext_magik = 11;
extern double   ext_lot = 0.01;
extern bool     ext_tick = true;
extern bool     ext_close_loss = false;
extern bool     ext_close_profit = false;
extern string   ext_period = (string)PERIOD_H1;
extern int      ext_depth = 33;
class Lock {
    private:
        int magik;
        double lot,depth;
        string period;
    public:
        double medial,mdist,ufrac,lfrac;
        double buy_price, buy_profit, buy_max_loss;
        double sell_price, sell_profit, sell_max_loss;
        int orders_all, orders_buy, orders_sell, orders_buy_stop, orders_sell_stop;

    bool get_medial() {
        RefreshRates();
        double _sum=0;medial=0;ufrac=0;lfrac=0;
        for(int i=0; i<depth; i++) {
            if(ufrac == 0)
                ufrac = iFractals(Symbol(), (int)period, MODE_UPPER, i);
            if(lfrac == 0)
                lfrac = iFractals(Symbol(), (int)period, MODE_LOWER, i);
            _sum += iHigh(Symbol(), (int)period, i) - iLow(Symbol(), (int)period, i);
        }
        medial = MathAbs(NormalizeDouble(_sum/depth, Digits));
        if(medial > 0 && ufrac > 0 && lfrac > 0)
            return true;
        return false;
    }

    bool get_orders() {
        RefreshRates();
        orders_all=0;orders_sell=0;orders_buy=0;orders_buy_stop=0;orders_sell_stop=0;
        for(int i=0; i<OrdersTotal(); i++)
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
        if(OrderSymbol() == Symbol() && OrderMagicNumber() == magik) {
            orders_all++;
            if(OrderType() == OP_BUY) {
                orders_buy++;
                buy_price = OrderOpenPrice();
                buy_profit=OrderProfit();
                if(OrderProfit() < buy_max_loss)
                    buy_max_loss=OrderProfit();
            }
            if(OrderType() == OP_BUYSTOP) {
                orders_buy_stop++;
                buy_price = OrderOpenPrice();
                buy_profit=0; buy_max_loss=0;
            }
            if(OrderType() == OP_SELL) {
                orders_sell++;
                sell_price = OrderOpenPrice();
                sell_profit=OrderProfit();
                if(OrderProfit() < sell_max_loss)
                    sell_max_loss=OrderProfit();
            }
            if(OrderType() == OP_SELLSTOP) {
                orders_sell_stop++;
                sell_price = OrderOpenPrice();
                sell_profit=0; sell_max_loss=0;
            }
        }
    return true;
    }

    bool open_order(string operation, double price) {
        if(operation == "BUY")
            if(OrderSend(Symbol(), OP_BUYSTOP, lot, price, 6, 0, 0, " ", magik))
                {Sleep(999); return true;}
        if(operation == "SELL")
            if(OrderSend(Symbol(), OP_SELLSTOP, lot, price, 6, 0, 0, " ", magik))
                {Sleep(999); return true;}
        return false;
    }

    bool close_order(string operation) {
        for(int i=0; i<OrdersTotal(); i++)
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
        if(OrderSymbol() == Symbol() && OrderMagicNumber() == magik) {
            if(operation == "BUY") {
                if(OrderType() == OP_BUY)
                    if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(Symbol(), MODE_BID), 50, 0))
                        {Sleep(999); return true;}
                if(OrderType() == OP_BUYSTOP)
                    if(OrderDelete(OrderTicket()))
                        {Sleep(999); return true;}
            }
            if(operation == "SELL") {
                if(OrderType() == OP_SELL)
                    if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(Symbol(), MODE_ASK), 50, 0))
                        return true;
                if(OrderType() == OP_SELLSTOP)
                    if(OrderDelete(OrderTicket()))
                        return true;
            }
        }
        return false;
    }

    Lock(double my_lot, int my_depth, string my_period, int my_magik) {
        lot=my_lot;depth=my_depth;period=my_period;magik=my_magik;
        Print("Lock init: ", get_medial()," ",get_orders());
        mdist = MarketInfo(Symbol(), MODE_SPREAD)*Point;

    }
};

Lock lock(ext_lot, ext_depth, ext_period, ext_magik);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
    EventSetTimer(33);
    my_comment();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
    EventKillTimer();
    //Print("deinit");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(ext_tick) {
        my_comment();
        if(lock.get_medial() && lock.get_orders()) {
            close_order();
            open_order();
        }
        else my_err_zero();
    }
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    if(ext_tick==false) {
        //Print("timer");
        my_comment();
        if(lock.get_medial() && lock.get_orders()) {
            close_order();
            open_order();
        }
        else my_err_zero();
    }
    return;
}
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
    double ret=0.0;

    Print("tester");
    while(true) {
        int err = GetLastError();
        if(err) Print("ERROR! Return code: ", err, " https://docs.mql4.com/constants/errorswarnings/enum_trade_return_codes");
    }
    return(ret);
  }
//+------------------------------------------------------------------+
void close_order() {
    lock.get_orders();
    if(ext_close_profit && lock.buy_profit > 0)
    if(lock.buy_price < lock.ufrac-lock.medial && lock.ufrac > Ask+lock.mdist)
        lock.close_order("BUY");
    if(ext_close_loss && lock.buy_profit < 0)
    if(lock.sell_profit < 0 && lock.buy_profit > lock.sell_profit)
    if(lock.buy_price > lock.ufrac+lock.medial && lock.ufrac > Ask+lock.mdist)
        lock.close_order("BUY");
    if(lock.orders_buy == 0 && lock.orders_buy_stop > 0)
        if(lock.ufrac > Ask+lock.medial && lock.buy_price > lock.ufrac+lock.medial)
            lock.close_order("BUY");
    lock.get_orders();
    if(ext_close_profit && lock.sell_profit > 0)
    if(lock.sell_price > lock.lfrac+lock.medial && lock.lfrac < Bid-lock.mdist)
        lock.close_order("SELL");
    if(ext_close_loss && lock.sell_profit < 0)
    if(lock.buy_profit < 0 && lock.buy_profit < lock.sell_profit)
    if(lock.sell_price < lock.lfrac-lock.medial && lock.lfrac < Bid-lock.mdist)
        lock.close_order("SELL");
    if(lock.orders_sell == 0 && lock.orders_sell_stop > 0)
        if(lock.lfrac < Bid-lock.medial && lock.sell_price < lock.lfrac-lock.medial)
            lock.close_order("SELL");
}

void open_order() {
    lock.get_orders();
    if(lock.orders_buy+lock.orders_buy_stop < lock.orders_sell+lock.orders_sell_stop || lock.orders_all == 0) {
        if(lock.ufrac > Ask+lock.mdist)
            if(lock.open_order("BUY", lock.ufrac+lock.mdist))
                lock.get_orders();
        if(lock.ufrac < Ask+lock.mdist)
            if(lock.open_order("BUY", Ask+lock.medial))
                lock.get_orders();
    }
    if(lock.orders_buy+lock.orders_buy_stop > lock.orders_sell+lock.orders_sell_stop || lock.orders_all == 0) {
        if(lock.lfrac < Bid-lock.mdist) 
            if(lock.open_order("SELL", lock.lfrac-lock.mdist))
                lock.get_orders();
        if(lock.lfrac > Bid-lock.mdist) 
            if(lock.open_order("SELL", Bid-lock.medial))
                lock.get_orders();
    }
}

void my_comment() {
    Comment("Time: ",TimeToStr(TimeCurrent(), TIME_DATE), " ", TimeToStr(TimeCurrent(), TIME_SECONDS),
        "\nmagik: ",ext_magik," lot: ",ext_lot," depth: ",ext_depth," period: ",ext_period,
        "\ntick: ",ext_tick," close_loss: ",ext_close_loss," close_profit: ",ext_close_profit,
        "\nb/s: ",lock.orders_buy+lock.orders_buy_stop,"/",lock.orders_sell+lock.orders_sell_stop,
        " uf/lf: ",lock.ufrac,"/",lock.lfrac," md/med: ",lock.mdist,"/",lock.medial);
    int err = GetLastError();
    if(err) Print("ERROR! Return code: ", err, " https://docs.mql4.com/constants/errorswarnings/enum_trade_return_codes");

}

void my_err_zero() {
    Print("ERROR! zero: mdist=",lock.mdist," ufrac=",lock.ufrac," lfrac=",lock.lfrac);
}