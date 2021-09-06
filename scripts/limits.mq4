//+------------------------------------------------------------------+
//|                                                          limits.mq4 |
//|                                             Copyright 2021,hjltu |
//|                                                      hjltu@ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,hjltu"
#property link      "hjltu@ya.ru"
#property version   "1.00"
#property strict

int     magik = 12;
double  my_gap = 2;
double  my_lot = 0.01;
int     my_depth = 33;
int     my_profit = 3;
class Order {
    protected:
        double  current_price, gap;
        double get_medium_candle(int _depth) {
            double _low =0, _high = 0, _medium;
            for(int i=0; i<_depth; i++) {
                _low += iLow(Symbol(), PERIOD_CURRENT, i);
                _high += iHigh(Symbol(), PERIOD_CURRENT, i);
                }
            _medium = MathAbs(NormalizeDouble((_high-_low)/_depth, Digits));
            return _medium;
            }

    public:
        int order_type;
        double  order_price, mdist, medium, stop_loss, take_profit;
        string symbol;
        string place_order(bool _sandbox, int _order_type) {
            string _comment = "Order was opened ";
            PrintFormat("Sandbox is: %d. Open order type = %d, where 2: BuyLimit, 3: SellLimit", _sandbox, _order_type);
            if(_sandbox == false)
                if(OrderSend(Symbol(), _order_type, my_lot, order_price, 3, stop_loss, take_profit, NULL, magik) == -1)
                    _comment = StringConcatenate("Order was not opened, Err: ", GetLastError(), ". ");
            Sleep(999);
            return _comment;
            }

        Order(double _gap, int _depth, int _profit) {
            Print("Init...");
            gap = _gap;
            symbol = Symbol();
            mdist = MarketInfo(symbol, MODE_SPREAD)*Point;
            order_price = WindowPriceOnDropped();
            current_price = iClose(Symbol(), PERIOD_CURRENT, 0);
            medium = get_medium_candle(_depth);
            if(order_price < current_price) {
                order_type = OP_BUYLIMIT;  
                stop_loss = MathAbs(NormalizeDouble(order_price - medium, Digits));
                take_profit = MathAbs(NormalizeDouble(order_price + medium*_profit, Digits));
                }
            if(order_price > current_price) {
                order_type = OP_SELLLIMIT;  
                stop_loss = order_price + medium;
                take_profit = order_price - medium*_profit;
                }
        }
    };

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
    {
    Print("Start");
    RefreshRates();
    Order order(my_gap, my_depth, my_profit);
    string res = order.place_order(false, order.order_type);
    Comment(res, "at ", TimeToStr(TimeCurrent(), TIME_DATE), " ", TimeToStr(TimeCurrent(), TIME_SECONDS), " by price: ", order.order_price);
    Print("TheEnd");
    }
//+------------------------------------------------------------------+
