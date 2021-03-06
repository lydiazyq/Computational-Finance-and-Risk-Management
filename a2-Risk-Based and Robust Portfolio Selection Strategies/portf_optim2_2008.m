clc;
clear all;
format long
global borrow_money period cur_year

% Input files
input_file_prices  = 'Daily_closing_prices20082009.csv';

% Read daily prices
if(exist(input_file_prices,'file'))
  fprintf('\nReading daily prices datafile - %s\n', input_file_prices)
  fid = fopen(input_file_prices);
     % Read instrument tickers
     hheader  = textscan(fid, '%s', 1, 'delimiter', '\n');
     headers = textscan(char(hheader{:}), '%q', 'delimiter', ',');
     tickers = headers{1}(2:end);
     % Read time periods
     vheader = textscan(fid, '%[^,]%*[^\n]');
     dates = vheader{1}(1:end);
  fclose(fid);
  data_prices = dlmread(input_file_prices, ',', 1, 1);
else
  error('Daily prices datafile does not exist')
end

% Convert dates into array [year month day]
format_date = 'mm/dd/yyyy';
dates_array = datevec(dates, format_date);
dates_array = dates_array(:,1:3);

% Find the number of trading days in Nov-Dec 2007 and
% compute expected return and covariance matrix for period 1
day_ind_start0 = 1;
day_ind_end0 = length(find(dates_array(:,1)==2007));
cur_returns0 = data_prices(day_ind_start0+1:day_ind_end0,:) ./ data_prices(day_ind_start0:day_ind_end0-1,:) - 1;
mu = mean(cur_returns0)';
Q = cov(cur_returns0);

% Remove datapoints for year 2007
data_prices = data_prices(day_ind_end0+1:end,:);
dates_array = dates_array(day_ind_end0+1:end,:);
dates = dates(day_ind_end0+1:end,:);

% Initial positions in the portfolio
init_positions = [5000 950 2000 0 0 0 0 2000 3000 1500 0 0 0 0 0 0 1001 0 0 0]';

% Initial value of the portfolio
init_value = data_prices(1,:) * init_positions;
fprintf('\nInitial portfolio value = $ %10.2f\n\n', init_value);

% Initial portfolio weights
w_init = (data_prices(1,:) .* init_positions')' / init_value;

% Number of periods, assets, trading days
N_periods = 6*length(unique(dates_array(:,1))); % 6 periods per year
N = length(tickers);
N_days = length(dates);

% Annual risk-free rate for years 2015-2016 is 2.5%
r_rf = 0.025;
% Annual risk-free rate for years 2008-2009 is 4.5%
r_rf2008_2009 = 0.045;

% Number of strategies
strategy_functions = {'strat_buy_and_hold' 'strat_equally_weighted' 'strat_min_variance' 'strat_max_Sharpe' 'strat_equal_risk_contr' 'strat_lever_equal_risk_contr' 'strat_robust_optim'};
strategy_names     = {'Buy and Hold' 'Equally Weighted Portfolio' 'Minimum Variance Portfolio' 'Maximum Sharpe Ratio Portfolio' 'Equal Risk Contributions Portfolio' 'Leveraged Equal Risk Contributions Portfolio' 'Robust Optimization Portfolio'};
%N_strat = 1; % comment this in your code
N_strat = length(strategy_functions); % uncomment this in your code
fh_array = cellfun(@str2func, strategy_functions, 'UniformOutput', false);

for (period = 1:N_periods)
   % Compute current year and month, first and last day of the period
   if(dates_array(1,1)==08)
       cur_year  = 08 + floor(period/7);
   else
       cur_year  = 2008 + floor(period/7);
   end
   cur_month = 2*rem(period-1,6) + 1;
   day_ind_start = find(dates_array(:,1)==cur_year & dates_array(:,2)==cur_month, 1, 'first');
   day_ind_end = find(dates_array(:,1)==cur_year & dates_array(:,2)==(cur_month+1), 1, 'last');
   fprintf('\nPeriod %d: start date %s, end date %s\n', period, char(dates(day_ind_start)), char(dates(day_ind_end)));

   % Prices for the current day
   cur_prices = data_prices(day_ind_start,:);

   % Execute portfolio selection strategies
   for(strategy = 1:N_strat)

      % Get current portfolio positions
      if(period==1)
         curr_positions = init_positions;
         curr_cash = 0;
         portf_value{strategy} = zeros(N_days,1);
      else
         curr_positions = x{strategy,period-1};
         curr_cash = cash{strategy,period-1};
      end

      % Compute strategy
      [x{strategy,period} cash{strategy,period}] = fh_array{strategy}(curr_positions, curr_cash, mu, Q, cur_prices);

      % Verify that strategy is feasible (you have enough budget to re-balance portfolio)
      % Check that cash account is >= 0
      % Check that we can buy new portfolio subject to transaction costs

      %%%%%%%%%%% Insert your code here %%%%%%%%%%%%

      % Compute portfolio value
      if strategy == 6
          portf_value{strategy}(day_ind_start:day_ind_end) = data_prices(day_ind_start:day_ind_end,:) * x{strategy,period} + cash{strategy,period} - borrow_money;
      else
          portf_value{strategy}(day_ind_start:day_ind_end) = data_prices(day_ind_start:day_ind_end,:) * x{strategy,period} + cash{strategy,period};
      end
      
      fprintf('   Strategy "%s", value begin = $ %10.2f, value end = $ %10.2f\n', char(strategy_names{strategy}), portf_value{strategy}(day_ind_start), portf_value{strategy}(day_ind_end));

      period_portf{strategy,period}=portf_value{strategy}(day_ind_start);
      period_price{period}=data_prices(day_ind_start,:);
      
   end
      
   % Compute expected returns and covariances for the next period
   cur_returns = data_prices(day_ind_start+1:day_ind_end,:) ./ data_prices(day_ind_start:day_ind_end-1,:) - 1;
   mu = mean(cur_returns)';
   Q = cov(cur_returns);
   
end

% Plot results
% figure(1);
%%%%%%%%%%% Insert your code here %%%%%%%%%%%%
length = 1:505;
a = portf_value{1,1};
b = portf_value{1,2};
c = portf_value{1,3};
d = portf_value{1,4};
e = portf_value{1,5};
f = portf_value{1,6};
g = portf_value{1,7};
plot(length,a,length,b,length,c,length,d,length,e,length,f,length,g,'LineWidth',1.5); 
xlabel('Days');
ylabel('Portfolio Value');
title('Performance of the Strategies (2008-2009');
legend('Buy and Hold','Equally Weighted Portfolio','Minimum Variance Portfolio','Maximum Sharpe Ratio Portfolio','Equal Risk Contributions Portfolio','Leveraged Equal Risk Contributions Portfolio','Robust Optimization Portfolio');

x_axis = 1:12;
for i = 1:12
    weight_3{i,1} = period_price{1,i} .* x{3,i}'./(period_portf{3,i} - cash{3,i});
    weight_4{i,1} = period_price{1,i} .* x{4,i}'./(period_portf{4,i} - cash{4,i});
    weight_7{i,1} = period_price{1,i} .* x{7,i}'./(period_portf{7,i} - cash{7,i});
end

variance = cell2mat(weight_3);
figure(2);
plot(variance);
xlabel('Periods');
ylabel('Weight');
title('Minimum Variance Strategy Dynamic Change (2008-2009)');
legend(headers{1,1}(2:21));
 
sharpe = cell2mat(weight_4);
figure(3);
plot(sharpe);
xlabel('Periods');
ylabel('Weight');
title('Maximum Sharpe Ratio Strategy Dynamic Change (2008-2009)');
legend(headers{1,1}(2:21));

sharpe = cell2mat(weight_7);
figure(4);
plot(sharpe);
xlabel('Periods');
ylabel('Weight');
title('Robust Portfolio Selection Strategy Dynamic Change (2008-2009)');
legend(headers{1,1}(2:21));