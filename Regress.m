
% Prepare Data
%FileName = '74_XOP.txt';     % XOP
%FileName = '27_HSI.txt';     % Heng Sheng Zhi Shu
%FileName = '27_HZ5014.txt';   % Heng Sheng Guo Qi Zhi Shu
%FileName = 'SZ_399006.txt';  % Chuang Ye Ban Zhi
%FileName = 'SH_510660.txt';  % Yi Yao Hang Ye
%FileName = 'SH_518880.txt';     % XOP
FileName = 'SZ_399905.txt';  % Zhong Zheng 500

PriceData=GetData(FileName);

% Regress 
min_period = 15;
max_period = 40;

AveRet = zeros(max_period,max_period);
MaxDrawD = zeros(max_period,max_period);

for b=min_period:max_period
    for s=min_period:max_period
        [AveRet(b,s) MaxDrawD(b,s)] = TradingMA_BS(PriceData,b,s);
    end
end

% Save Result
save 399905_ma_regr.mat AveRet MaxDrawD

% Plot
surf (min_period:max_period,min_period:max_period, AveRet(min_period:max_period,min_period:max_period))
%surf(MaxDrawD);

%fprintf('AveRet:  %2f\n', AveRet(20,20));
%fprintf('MaxDrawD:  %2f\n', MaxDrawD(20,20));
