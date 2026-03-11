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

[datesSet, ratesSet] = readExcelDataOS('MktData_CurveBootstrap.xls', formatData);

%% Bootstrap
% dates includes SettlementDate as first date

[dates, discounts, zeroRates]=bootstrap(datesSet, ratesSet); % TBC

%% Compute Zero Rates
% TBM

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

%% Exercise 6
% Making use of the curve found in Es.1 find the NPV of a cash flow recived
% on the 19th of each month with an Average Annual Growth Rate of 5%
% applied in March of each year
initial_amount = 6 *10^3;
NPV = discounted_cash_flow(dates, discounts, initial_amount)
NPv = calc_NPV_Ex6(dates, discounts);
testo_leggibile = datestr(dates, 'dd/mm/yyyy')
