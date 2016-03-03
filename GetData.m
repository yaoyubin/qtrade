function TradeData=GetData(FileName)
% Load IF data from .mat file

%addpath('~/Documents/MyMoney/GetData/');

% ----------------------------------------------------------------------------
% Test Set
%load IF888-2011.mat;
%TradeData=IF888(:,1:2);

% ----------------------------------------------------------------------------
% IF main contract, 1min 
%TradeData = LoadIFdata();

% ----------------------------------------------------------------------------

FullFileName = ['~/Documents/MyMoney/GetData/', FileName];
[Day, PriceOpen, PriceCeil, PriceFloor, PriceClose, Vol, Vol2] = textread (FullFileName, "%s %f %f %f %f %d %f", 'headerlines', 2, 'delimiter', ',');

DayByNum = datenum(Day,'yyyy/mm/dd');

TradeData = [DayByNum PriceClose];

end
