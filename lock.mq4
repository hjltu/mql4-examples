//+------------------------------------------------------------------+
//|                                                          lock.mq4 |
//|                                             Copyright 2021,hjltu |
//|                                                      hjltu@ya.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,hjltu"
#property link      "hjltu@ya.ru"
#property version   "1.00"
#property strict

int     magik = 12;
double  my_lot = 0.01;

class Order {
    protected:
        double  current_price;

    public:
        int order_type;
        double  order_price, mdist;
        string symbol;
        string place_order(bool _sandbox, int _order_type) {
            string _comment = "Order was opened. ";
            PrintFormat("Sandbox is: %d. Open order type = %d, where 2: BuyLimit, 3: SellLimit", _sandbox, _order_type);
            if(_sandbox == false)
                if(OrderSend(Symbol(), _order_type, my_lot, order_price, 3, 0, 0, NULL, magik) == -1)
                    _comment = StringConcatenate("Order was not opened, Err: ", GetLastError(), ". ");
            Sleep(999);
            return _comment;
            }

        Order() {
            Print("Init...");
            symbol = Symbol();
            mdist = MarketInfo(symbol, MODE_SPREAD)*Point;
            order_price = WindowPriceOnDropped();
            current_price = iClose(Symbol(), PERIOD_CURRENT, 0);
            if(order_price > current_price)
                order_type = OP_BUYSTOP;  
            if(order_price < current_price)
                order_type = OP_SELLSTOP;
        }
    };

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
    {
    Print("Start");
    RefreshRates();
    Order order();
    string res = order.place_order(false, order.order_type);
    Comment(res, "at ", TimeToStr(TimeCurrent(), TIME_DATE), " ", TimeToStr(TimeCurrent(), TIME_SECONDS), " by price: ", order.order_price);
    Print("TheEnd");
    }
//+------------------------------------------------------------------+
