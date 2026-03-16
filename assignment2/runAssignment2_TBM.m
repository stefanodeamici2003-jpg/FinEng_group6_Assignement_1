% runAssignment2
%  group 6, AY2025-2026
% 

clear all; close all; clc;

%% Settings
formatData='dd/mm/yyyy'; %Pay attention to your computer settings 

%% Read market data
[datesSet, ratesSet] = readExcelData('MktData_CurveBootstrap.xls', formatData);

%% Exercise 1 : P&L impacts for an IRS
% dates includes SettlementDate as first date
[dates, discounts, zeroRates]=bootstrap(datesSet, ratesSet); 
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

%% Exercise 2: --> report 

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


%% Exercise 5: credit simulation
%   theta: point in time where the intensity changes
%   lambda1, lambda2: values of the intensity parameter
lambda1 = 0.0004;
lambda2 = 0.0010;
theta   = 5;

%% Question a)
% Simulation of a singular default time through the non constant Intensity
% based model
u = rand;
v = -log(u);
% Piecewise lambda => we can integrate easily and then deduce tau
threshold = lambda1 * theta;   % = 0.002
if v <= threshold
    tau = v/lambda1;
else
    tau = theta + (v-threshold)/lambda2;
end
tau

%% Question b)
% Simulates M=10^5 scenarios through the non constant Intensity
% based model and returns a validation of the parameters using the
% loglinear plot of the empirical survival probability probability and a
% plot of the default time density function
M = 10^5;
lambda1 = 0.0004;
lambda2 = 0.0010;
theta   = 5;
[P_emp, P_fit, lambda1_emp, lambda2_emp, CI_lambda1, CI_lambda2] = survival_probability(lambda1,lambda2,theta,M);
disp(['lambda1 estimate = ',num2str(lambda1_emp)])
disp(['lambda1 CI = [',num2str(CI_lambda1(1)),' , ',num2str(CI_lambda1(2)),']'])
disp(['lambda2 estimate = ',num2str(lambda2_emp)])
disp(['lambda2 CI = [',num2str(CI_lambda2(1)),' , ',num2str(CI_lambda2(2)),']'])

%% Exercise 6
% Making use of the curve found in Es.1 find the NPV of a cash flow recived
% on the 19th of each month with an Average Annual Growth Rate of 5%
% applied in March of each year
initial_amount = 1.5 *10^3;
NPV = discounted_cash_flow(dates, discounts, initial_amount)
initial_amount = 6.0 *10^3;
NPV = discounted_cash_flow(dates, discounts, initial_amount)

