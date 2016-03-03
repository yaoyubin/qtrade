function [AveRet MaxMaxDrawD] = TradingMA_BS(PriceData, BuyPeriod, SellPeriod)
% for MATLAB or Octave
% Note: I had to remove some font params in cmds like legend/text 
%       because Octave doesn't support some matlab syntax 
% TODO: add more feature into strategy to improve (return/max_drawdown)

% -------------------------------------------------------
% Strategy Setting
% -------------------------------------------------------
% Mode: MA20, Bias, DingTou
%mode = 'DingTou';
mode = 'MA20';

% use_ma5=0: close price vs ma20 (default)
% use_ma5=1: ma5 vs ma20
use_ma5=0;

% no_short=0:  can do long or short
% no_short=1:  only do long (default)
no_short=1;

% DingTou
dingtou_freq = 22;

% -------------------------------------------------------
% Parameter Setting
% -------------------------------------------------------
% Cost: commission 0.1%, spread 0.3%
%fee = 0;
fee = 0.001 + 0.003;

% if plot trade action on diagram
do_plot=0;

% use which MA in strategy
ma_period=20;  

% Select which stock
%FileName = '74_XOP.txt';     % XOP
%FileName = '27_HSI.txt';     % Heng Sheng Zhi Shu
%FileName = '27_HZ5014.txt';   % Heng Sheng Guo Qi Zhi Shu
%FileName = 'SZ_399006.txt';  % Chuang Ye Ban Zhi
%FileName = 'SH_510660.txt';  % Yi Yao Hang Ye
%FileName = 'SH_518880.txt';     % XOP
FileName = 'SZ_399905.txt';  % Zhong Zheng 500

% How many trade day one year have
trade_days = 244;  % average from 2008-2011

% bias thethold
bias_up=3.5;  
bias_dn=-3.5;  

% -------------------------------------------------------
% Prepare Data:
% -------------------------------------------------------

% Set Test Period
firstday=1;
lastday=size(PriceData,1);
%firstday=1000;
%lastday=2000;

Price=PriceData(firstday:lastday,2);

% MA Calculation
ShortLen = 5;
if (strcmp(mode, 'DingTou'))
    LongLen = 2;
else
    LongLen = 20;
end
%[MA5, MA20] = movavg(Price, ShortLen, LongLen);
%MA5(1:ShortLen-1) = Price(1:ShortLen-1);
%MA20(1:LongLen-1) = Price(1:LongLen-1);
MA5  = MA(Price, 5);
MA20 = MA(Price, 20);
MAx  = MA(Price, ma_period);
MAxB  = MA(Price, BuyPeriod);
MAxS  = MA(Price, SellPeriod);

if (strcmp(mode, 'Bias'))
    % Bias, use MA5
    Bias = zeros(length(Price),1);
    Bias(ma_period:end) = 100 * (Price(ma_period:end)-MA5(ma_period:end)) ./ MA5(ma_period:end);
end

% -------------------------------------------------------
% Generate Buy/Sell Signal 
% -------------------------------------------------------
% Postion Strategy: 
% Always 100% and no leverage
% Pos= 
% 1:  long 1
% 0:  no position 
% -1: short

Pos = zeros(length(Price),1);
lastbuy=0;

% Initilal Money 
InitialE = 5e6;

if (strcmp(mode, 'DingTou'))
    dingtou_rounds = floor(length(Price)/dingtou_freq);
    dingtou_e = InitialE/dingtou_rounds;
end

% Daily Return
ReturnD = zeros(length(Price),1);

% Number of the stocks in sell/buy
Amount = zeros(length(Price),1);
Amount(1) = 0;


for t = LongLen:length(Price)
    
   %% Buy/Sell Strategy
   %% Note: 
   %% Always BUY or SELL near the end of day(t)
   %% thus, no return for day(t) when Pos(t-1)=0;

   switch(mode)
   case 'MA20' 
      if (use_ma5==1)
          % Buy at end of day(t) if MA5 rises up MA20 at day(t-1) 
          SignalBuy = MA5(t)>MA5(t-1) && MA5(t)>MA20(t) && MA5(t-1)>MA20(t-1) && ...
                      MA5(t-2)<=MA20(t-2);
          % Sell at end of day(t) if MA5 falls down MA20 at day(t-1) 
          SignalSell = MA5(t)<MA5(t-1) && MA5(t)<MA20(t) && MA5(t-1)<MA20(t-1) && ...
                       MA5(t-2)>=MA20(t-2);
      else
        SignalBuy  = Price(t)>MAxB(t) && Price(t-1)<=MAxB(t-1); % above MAx
        SignalSell = Price(t)<MAxS(t) && Price(t-1)>=MAxS(t-1); % under MAx
      end
   case 'Bias' 
      SignalBuy  = Bias(t)<bias_dn; % over-sell
      %SignalSell = Bias(t)>bias_up; 
      SignalSell = Price(t)>MA5(t); 
   case 'DingTou' 
      SignalBuy  = (mod(t, dingtou_freq)==2); 
      SignalSell = 0;
   otherwise
      fprintf('Invalid Mode!' );
   end

    Amount(t) = Amount(t-1);

% -------------------------------------------------------
% Do Regression based on Buy/Sell Signal 
% -------------------------------------------------------
    % Do Buy
    if SignalBuy == 1
        % open long
        if Pos(t-1) == 0
            Pos(t) = 1;
            if strcmp(mode,'DingTou')
                Amount(t) = (sum(ReturnD(1:t)) + dingtou_e)/Price(t);
            else
                Amount(t) = (sum(ReturnD(1:t)) + InitialE)/Price(t);
            end
            ReturnD(t) = -Price(t)*Amount(t)*fee;
            lastbuy=t;
            %text(t,Price(t),' \leftarrow open long','FontSize',8);
            if (do_plot==1)
              text(t,Price(t),' \leftarrow open long');  % octave
              plot(t,Price(t),'ro','markersize',8);
            end
            continue;
        end
        % close short and open long
        if Pos(t-1) == -1
            Pos(t) = 1;
            ReturnD(t) = (Price(t-1)-Price(t))*Amount(t);
            Amount(t) = (sum(ReturnD(1:t)) + InitialE)/Price(t);
            ReturnD(t) = ReturnD(t) - Price(t)*Amount(t)*fee*2;
            %text(t,Price(t),' \leftarrow close short & open long','FontSize',8);
            if (do_plot==1)
              text(t,Price(t),' \leftarrow close short & open long');  % octave
              plot(t,Price(t),'ro','markersize',8);           
            end
            continue;
        end
        % DingTou
        if (Pos(t-1) == 1) && strcmp(mode,'DingTou')
            Pos(t) = 1;
            delta_amount = dingtou_e/Price(t);
            Amount(t) = Amount(t-1) + delta_amount;
            ReturnD(t) = -Price(t)*delta_amount*fee;
            lastbuy=t;
            %text(t,Price(t),' \leftarrow open long','FontSize',8);
            if (do_plot==1)
              text(t,Price(t),' \leftarrow open long');  % octave
              plot(t,Price(t),'ro','markersize',8);
            end
            continue;
        end
    end
    
    % Do Sell
    if SignalSell == 1
        if Pos(t-1) == 0
            if (no_short==0)
                Pos(t) = -1;
                Amount(t) = (sum(ReturnD(1:t)) + InitialE)/Price(t);
                ReturnD(t) = -Price(t)*Amount(t)*fee;
                %text(t,Price(t),' \leftarrow open short','FontSize',8);
                if (do_plot==1)
                    text(t,Price(t),' \leftarrow open short');  % octave
                    plot(t,Price(t),'rd','markersize',8);
                end
                continue;
            end
        end
        if Pos(t-1) == 1
            if (no_short==0)
                Pos(t) = -1;
                ReturnD(t) = (Price(t)-Price(t-1))*Amount(t);
                Amount(t) = (sum(ReturnD(1:t)) + InitialE)/Price(t);
                ReturnD(t) = ReturnD(t) - Price(t)*Amount(t)*fee*2;
                %text(t,Price(t),' \leftarrow close long & open short','FontSize',8);
                if (do_plot==1)
                  text(t,Price(t),' \leftarrow close long & open short'); % octave
                  plot(t,Price(t),'rd','markersize',8);
                end
                continue;
            else
                Pos(t) = 0;
                ReturnD(t) = (Price(t)-Price(t-1))*Amount(t);
                ReturnD(t) = ReturnD(t) - Price(t)*Amount(t)*fee;
                Amount(t) = 0;
                if (do_plot==1)
                  text(t,Price(t),' \leftarrow close long'); % octave
                  plot(t,Price(t),'rd','markersize',8);
                end
                continue;
            end
        end
    end
    
    % Calculate the return
    if Pos(t-1) == 1
        Pos(t) = 1;
        ReturnD(t) = (Price(t)-Price(t-1))*Amount(t);
    end
    if Pos(t-1) == -1
        Pos(t) = -1;
        ReturnD(t) = (Price(t-1)-Price(t))*Amount(t);
    end
    if Pos(t-1) == 0
        Pos(t) = 0;
        ReturnD(t) = 0;
    end    
    
    % Close the postion at the end of the trading day if there's any 
    if t == length(Price) && Pos(t-1) ~= 0
        if Pos(t-1) == 1
            Pos(t) = 0;
            ReturnD(t) = (Price(t)-Price(t-1))*Amount(t);
            ReturnD(t) = ReturnD(t) - Price(t)*Amount(t)*fee;
            %text(t,Price(t),' \leftarrow close long','FontSize',8);
            if (do_plot==1)
              text(t,Price(t),' \leftarrow close long'); % octave
              plot(t,Price(t),'rd','markersize',8);
            end
        end
        if Pos(t-1) == -1
            Pos(t) = 0;
            ReturnD(t) = (Price(t-1)-Price(t))*Amount(t);
            ReturnD(t) = ReturnD(t) - Price(t)*Amount(t)*fee;
            %text(t,Price(t),' \leftarrow close short','FontSize',8);
            if (do_plot==1)
              text(t,Price(t),' \leftarrow close short'); % octave
              plot(t,Price(t),'ro','markersize',8);
            end
        end
    end
    
end

if strcmp(mode,'Bias')
    % Report Bias
    figure;
    plot(Bias);
    grid on;
    axis tight;
    title('Bias');
end

% -------------------------------------------------------
% Performance Metrics
% -------------------------------------------------------
%% Accumlated Return
ReturnCum = cumsum(ReturnD);
ReturnCum = ReturnCum + InitialE;
NetValue = ReturnCum/InitialE;

%% Max Drawdown
MaxDrawD = zeros(length(Price),1);
for t = LongLen:length(Price)
    C = max( ReturnCum(1:t) );
    if C == ReturnCum(t)
        MaxDrawD(t) = 0;
    else
        MaxDrawD(t) = (ReturnCum(t)-C)/C;
    end
end
MaxDrawD = abs(MaxDrawD);

MaxMaxDrawD = max(MaxDrawD);
AveRet = ((ReturnCum(end,1)/InitialE) ^ (trade_days/length(Price))) - 1;

