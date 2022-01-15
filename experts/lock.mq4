//+------------------------------------------------------------------+
//|                                                  lock.mq4 |
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
                        "   close_stop: Close stop orders(false)\n"
                        "   close_loss: Close orders with loss(false)\n"
                        "   close_profit: Close orders with profit(false)\n"
                        "   modify_order: Add stoploss to open order(false)\n"
                        "   period: timeframe, minutes(60,240,1440)\n"
                        "   depth: number of the candles to find medial(33)\n"
                        "   pause: timer pause, sec(66)"
int             ext_magik = 11;
extern double   ext_lot = 0.01;
extern bool     ext_tick = true;
extern bool     ext_close_stop = false;
extern bool     ext_close_loss = false;
extern int      ext_profit = 0;
extern string   ext_period = (string)PERIOD_H1;

int     fix_mdist = 3;
int     candles_depth=33;
int     timer_pause=66;

class Lock {
    public:
        int magik, sell_ticket, buy_ticket;
        double lot;
        string period;
        double spread,medial,mdist;
        double buy_price, buy_profit, buy_stoploss;
        double sell_price, sell_profit, sell_stoploss;
        int orders_all, orders_buy, orders_sell, orders_buy_stop, orders_sell_stop;

    bool get_medial() {
        RefreshRates();
        double _sum=0;
        for(int i=0; i<candles_depth; i++) {
            _sum += iHigh(Symbol(), (int)period, i) - iLow(Symbol(), (int)period, i);
        }
        spread = MathAbs(NormalizeDouble(MarketInfo(Symbol(), MODE_SPREAD)*Point, Digits));
        mdist = MathAbs(NormalizeDouble(spread*fix_mdist, Digits));
        medial = MathAbs(NormalizeDouble(_sum/candles_depth, Digits));
        if(mdist > 0 && medial > 0)
            return true;
        return false;
    }

    bool get_orders() {
        RefreshRates();
        orders_all=0;orders_sell=0;orders_buy=0;
        orders_buy_stop=0;orders_sell_stop=0;
        for(int i=0; i<OrdersTotal(); i++)
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
        if(OrderSymbol() == Symbol() && OrderMagicNumber() == magik) {
            orders_all++;
            if(OrderType() == OP_BUY) {
                orders_buy++;
                buy_price = OrderOpenPrice();
                buy_profit=OrderProfit();
                buy_stoploss=OrderStopLoss();
                buy_ticket=OrderTicket();
            }
            if(OrderType() == OP_BUYSTOP) {
                orders_buy_stop++;
                buy_price = OrderOpenPrice();
                buy_ticket=OrderTicket();
                buy_profit=0; buy_stoploss=0;
            }
            if(OrderType() == OP_SELL) {
                orders_sell++;
                sell_price = OrderOpenPrice();
                sell_profit=OrderProfit();
                sell_stoploss=OrderStopLoss();
                sell_ticket=OrderTicket();
            }
            if(OrderType() == OP_SELLSTOP) {
                orders_sell_stop++;
                sell_price = OrderOpenPrice();
                sell_ticket=OrderTicket();
                sell_profit=0; sell_stoploss=0;
            }
        }
    return true;
    }
    bool open_order(string operation, double price, double stoploss) {
        if(operation == "BUYSTOP")
            if(OrderSend(Symbol(), OP_BUYSTOP, lot, price, 6, stoploss, 0, " ", magik))
                {Sleep(999); return true;}
        if(operation == "SELLSTOP")
            if(OrderSend(Symbol(), OP_SELLSTOP, lot, price, 6, stoploss, 0, " ", magik))
                {Sleep(999); return true;}
        return false;
    }

    bool modify_order(int ticket, double price, double stoploss) {
        if(OrderModify(ticket, price, stoploss, 0, NULL))
            {Sleep(999); return true;}
        return false;
    }

    bool close_order(string operation) {
        for(int i=0; i<OrdersTotal(); i++)
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == true)
        if(OrderSymbol() == Symbol() && OrderMagicNumber() == magik) {
            if(operation == "BUY")
                if(OrderType() == OP_BUY)
                    if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(Symbol(), MODE_BID), 50, 0))
                        {Sleep(999); return true;}
            if(operation == "BUYSTOP")
                if(OrderType() == OP_BUYSTOP)
                    if(OrderDelete(OrderTicket()))
                        {Sleep(999); return true;}

            if(operation == "SELL")
                if(OrderType() == OP_SELL)
                    if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(Symbol(), MODE_ASK), 50, 0))
                        {Sleep(999); return true;}
            if(operation == "SELLSTOP")
                if(OrderType() == OP_SELLSTOP)
                    if(OrderDelete(OrderTicket()))
                        {Sleep(999); return true;}

        }
        return false;
    }

    Lock() {}
};

Lock lock();
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
    EventSetTimer(timer_pause);
    my_comment();
    lock.lot = ext_lot;
    lock.period = ext_period;
    lock.magik = ext_magik;
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
    if(ext_tick)
        my_run();
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    if(ext_tick==false)
        my_run();;
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
void my_run() {
    my_comment();
    if(lock.get_medial() && lock.get_orders()) {
        if(ext_close_stop)
            close_stop_order();
        if(ext_profit)
            close_profit_order();
        if(ext_close_loss)
            close_loss_order();
        open_order();
    }
    else {my_err(); Sleep(timer_pause*1000);}
}

void close_stop_order() {
    //Print("close_stop_order");
    lock.get_orders();
    if(lock.orders_buy_stop && lock.buy_price > Ask+lock.medial)
        lock.close_order("BUYSTOP");
    lock.get_orders();
    if(lock.orders_sell_stop && lock.sell_price < Bid-lock.medial)
        lock.close_order("SELLSTOP");
}

void close_profit_order() {
    //Print("close_profit_order");
    lock.get_orders();
    if(lock.buy_profit > ext_profit)
        lock.close_order("BUY");
    lock.get_orders();
    if(lock.sell_profit > ext_profit)
        lock.close_order("SELL");
}

void close_loss_order() {
    //Print("close_loss_order");
    lock.get_orders();
    if(lock.buy_price > Ask+lock.medial)
        lock.close_order("BUY");
    lock.get_orders();
    if(lock.sell_price < Bid-lock.medial)
        lock.close_order("SELL");
}

void open_order() {
    lock.get_orders();
    if(lock.orders_buy+lock.orders_buy_stop == 0) {
        lock.open_order("BUYSTOP", Ask+lock.medial, 0);
    }
    lock.get_orders();
    if(lock.orders_sell+lock.orders_sell_stop == 0) {
        lock.open_order("SELLSTOP", Bid-lock.medial, 0);
    }
}

void my_comment() {
    Comment("Time: ",TimeToStr(TimeCurrent(), TIME_DATE), " ", TimeToStr(TimeCurrent(), TIME_SECONDS),
        "\nmagik/lot: ",ext_magik,"/",lock.lot," per/fix/dep/ps: ",
        lock.period,"/",fix_mdist,"/",candles_depth,"/",timer_pause,
        "\nb/s: ",lock.orders_buy+lock.orders_buy_stop,"/",lock.orders_sell+lock.orders_sell_stop,
        " md/me: ",StringFormat("%.4f",lock.mdist),"/",StringFormat("%.4f",lock.medial),
        "\ntick: ",ext_tick,
        "\nstop: ",ext_close_stop,
        "\nloss: ",ext_close_loss,
        "\nprof: ",ext_profit);
    int err = GetLastError();
    if(err) Print("ERROR! Return code: ", err, " https://docs.mql4.com/constants/errorswarnings/enum_trade_return_codes");

}

void my_err() {
    Print("ERROR! my: mdist=",lock.mdist," medial=",lock.medial, " sleep=",timer_pause);
}
