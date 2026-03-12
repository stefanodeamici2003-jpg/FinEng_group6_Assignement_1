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
% This fuction works on Windows OS. Pay attention on other OS.

[datesSet, ratesSet] = readExcelData('MktData_CurveBootstrap.xls', formatData);

%% Bootstrap
% dates includes SettlementDate as first date

[dates, discounts, zeroRates]=bootstrap(datesSet, ratesSet); % TBC
%% Plot Results

figure;

yyaxis left
plot(dates, discounts, 'b-', 'LineWidth', 1.5);
ylabel('Discounts');

yyaxis right
plot(dates, zeroRates, 'r-', 'LineWidth', 1.5);
ylabel('Zero Rates');

datetick('x', 'yyyy');   % <-- questa riga risolve il problema
grid on;
legend({'discounts', 'zero rates'}, 'Location', 'northeast');
title('IR Curve - 15 Feb 2008');
%% Exercise 3: Asset Swap
issueDate = datenum('31/03/2007', 'dd/mm/yyyy');
maturityDate = datenum('31/03/2012', 'dd/mm/yyyy');
cleanPrice = 1.015; coupon = 0.046;
s_asw = assetSwapSpread(dates, discounts, dates(1), issueDate, maturityDate, cleanPrice, coupon);
%% Exercise 4: Case Study

% Construction of the Dataset
[datesCDS, spreadsCDS] = construct_dataset_ES_4();

% Point A: Construction & plot of the spline-complete set
y=spline(datesCDS,spreadsCDS,dates);
figure;
plot(dates, y, 'b-', 'LineWidth', 1.5); % Disegna la linea blu della spline
hold on;
plot(datesCDS, spreadsCDS, 'ro', 'MarkerSize', 7, 'LineWidth', 1.5); % Disegna i cerchi rossi sui dati originali

% Point B: Intensities with all 3 methods
recovery = 0.4;
for i=1:3
    [datesCDS, survProbs, intensities] = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS, i, recovery);
end

%% Exercise 6
% Making use of the curve found in Es.1 find the NPV of a cash flow recived
% on the 19th of each month with an Average Annual Growth Rate of 5%
% applied in March of each year
initial_amount = 1.5 *10^3;
NPV = discounted_cash_flow(dates, discounts, initial_amount)
