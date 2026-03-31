%% Settings
formatData='dd/mm/yyyy'; 
%% Read market data
[datesSet, ratesSet] = readExcelData('MktData_CurveBootstrap.xls', formatData);

%% P&L impacts for an IRS
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
%% Asset Swap
issueDate = datenum('31/03/2007', 'dd/mm/yyyy');
maturityDate = datenum('31/03/2012', 'dd/mm/yyyy');
cleanPrice = 1.015; 
coupon = 0.046;
s_asw = assetSwapSpread(dates, discounts, dates(1), issueDate, maturityDate, cleanPrice, coupon);
fprintf('ASW Spread : %.4f bps\n', s_asw * 10000);

%% Case Study

% A) Construction of the spline-complete set
missing_s=spline([1,2,3,4,5,7],[29; 34; 37; 39; 40; 40] / 10000,6);
[datesCDS, spreadsCDS] = construct_dataset(missing_s);

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


%% Credit simulation
%   theta: point in time where the intensity changes
%   lambda1, lambda2: values of the intensity parameter


% Simulates M=10^5 scenarios through the non constant Intensity
% based model and returns a validation of the parameters
M = 10^5;
lambda1 = 0.0004;
lambda2 = 0.0010;
theta   = 5;
[tau_vect, P_emp, P_fit, lambda1_emp, lambda2_emp, CI_lambda1, CI_lambda2] = survival_probability(lambda1,lambda2,theta,M);