% runAssignment2
%  group X, AY20ZZ-20ZZ
% Computes Euribor 3m bootstrap with a single-curve model
%
% This is just code structure: it should be completed & modified (TBM)
%
% to run:
% > runAssignment2_TBM

clear all;
close all;
clc;

%% Settings
formatData='dd/mm/yyyy'; %Pay attention to your computer settings 

%% Read market data
[datesSet, ratesSet] = readExcelData('MktData_CurveBootstrap.xls', formatData);

%% Exercise 1 : P&L impacts for an IRS
% dates includes SettlementDate as first date
[dates, discounts, zeroRates]=bootstrap(datesSet, ratesSet); 

% Plot Result
figure;

yyaxis left
plot(dates, discounts, 'b-', 'LineWidth', 1.5);
ylabel('Discounts');
yyaxis right
plot(dates, zeroRates, 'r-', 'LineWidth', 1.5);
ylabel('Zero Rates');

datetick('x', 'yyyy'); 
grid on;
legend({'discounts', 'zero rates'}, 'Location', 'northeast');
title('IR Curve - 15 Feb 2008');

%% Exercise 3: Asset Swap
issueDate = datenum('31/03/2007', 'dd/mm/yyyy');
maturityDate = datenum('31/03/2012', 'dd/mm/yyyy');
cleanPrice = 1.015; 
coupon = 0.046;
s_asw = assetSwapSpread(dates, discounts, dates(1), issueDate, maturityDate, cleanPrice, coupon);
fprintf('ASW Spread : %.4f bps\n', s_asw * 10000);

%% Exercise 4: Case Study

% A) Construction & plot of the spline-complete set
% Construction of the Dataset
missing_s=spline([1,2,3,4,5,7],[29; 34; 37; 39; 40; 40] / 10000,6);
[datesCDS, spreadsCDS] = construct_dataset_ES_4(missing_s);

% B) Intensities with all 3 methods
recovery = 0.4;

figure;

for i = 1:3
    [datesCDS, survProbs, intensities] = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS, i, recovery);
    t = (datesCDS - datesCDS(1)) / 365;  % year from t0
    stairs(t, intensities, 'LineWidth', 1.5);
    hold on;
end
labels = {'no accrual','accrual','Jarrow Turnbull'};
hold off;
legend(labels);
xlabel('year');
ylabel('intensity');
title('Intensities CDS');
grid on;

figure;
for i = 1:3
    [datesCDS, survProbs, intensities] = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS, i, recovery);
    t = (datesCDS - datesCDS(1)) / 365;  % year from t0
    plot(t, survProbs, 'LineWidth', 1.5);
    hold on;
end
labels = {'no accrual','accrual','Jarrow Turnbull'};
hold off;
legend(labels);
xlabel('year');
ylabel('survProbs');
title('survProbs CDS');
grid on;


 %% Exercise 6
 % Making use of the curve found in Es.1 find the NPV of a cash flow recived
 % on the 19th of each month with an Average Annual Growth Rate of 5%
 % applied in March of each year
initial_amount = 1.5 *10^3;
NPV = discounted_cash_flow(dates, discounts, initial_amount)
