function IFdata=LoadIFdata()
% Load IF data from .mat file

% IF main contract, 1min 
% date, time, opening price, ceil, floor, closing price, volumn, open position
load IF_main_clean.mat;

% Get the num of entry of the same day
IFday = IF(:,1);
Day = unique(IFday);
days = length(Day);  % total days

NumEntryByDay = zeros(size(Day));
for i=1:days
    NumEntryByDay(i)=length(find(IFday==Day(i)));
end

% UnderSample the PriceData by-day from by-minite data
day_index=1;
IFdata = zeros(days,2);
IFdata(1,1) = IF(1,1);

for i=1:size(IF,1)
  if (IF(i,1)~=IFdata(day_index,1)) % if it's a new date, increase the day index
    day_index = day_index+1;
  end
  IFdata(day_index,1) = IF(i,1);
  IFdata(day_index,2) = IF(i,6);
end

end
