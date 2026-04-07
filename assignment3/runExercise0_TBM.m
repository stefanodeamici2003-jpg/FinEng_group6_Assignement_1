% Risk Measurements of a Linear Portfolio
% Financial Engineering: Politecnico Milano
% 
%  MODIFY formatDate,
%         returnsOfInterest with the selection of previous date in case of missing value 
%     ADD where needed
%
% In order to run the script:
% >> runAssign5Ex0
%
% Last Modified: 25.03.2021

clc;
clear all;

%% Parameters
% File name
inputFile = 'sx5e_historical_data.xls';
% General parameters
formatDate = 'dd/mm/yyyy';
alpha=0.95;

% Input parameters
refDate=datenum('24 Jul 12');
NumberOfYears=2;
timeWindow = 12*NumberOfYears;
sharesList=cellstr({'Inditex'; 'BASF'; 'LVMH'}); 
numberAssets = size(sharesList,1);
weights=(1/numberAssets)*ones(numberAssets,1);

%% Select returns of interest
[tSelected, returnsSelected] = returnsOfInterest(inputFile, refDate, -timeWindow, sharesList, formatDate);
returnsSelected;

%% Compute Risk Measurements

% Analytic VaR & ES (Normal)
% It computes mean and VarCovar on the proper time scale
portfolioValue = 1e7;
riskMeasureTimeIntervalInDays = 1;
try
    [ES_PCA, VaR] = AnalyticNormalMeasures(alpha, weights, portfolioValue, riskMeasureTimeIntervalInDays, returnsSelected); 
catch err
    err.message
end
fprintf('\n==================================================\n');
fprintf(' EXERCISE 0: ANALYTIC NORMAL MEASURES\n');
fprintf('==================================================\n');
fprintf(' VaR (95%%, 1 Day) : %15.2f EUR\n', VaR);
fprintf(' ES  (95%%, 1 Day) : %15.2f EUR\n', ES_PCA);
%% Historical Simulation - Ptf1
sharesListPtf1 = {'ENI'; 'Telefonica'; 'EON'; 'Daimler'}; 
absQuantities = [18e3; 25e3; 15e3; 9e3];
alpha = 0.99;
riskMeasureTimeIntervalInDays_Ptf1 = 1;

% Extraction of today's prices
[tSelected, returnsSelected1] = returnsOfInterest(inputFile, refDate, -timeWindow, sharesListPtf1, formatDate);
[shareData.num, shareData.cell] = xlsread(inputFile, 'Data', 'a5:cx1295');
currentPrices = zeros(length(sharesListPtf1), 1);
for i = 1:length(sharesListPtf1)
    bbgCode = underlyingCode(sharesListPtf1{i});
    [val, t_val] = findSeries(shareData, bbgCode, formatDate);
    idx = find(t_val <= datenum(refDate));
    currentPrices(i) = val(idx(end)); 
end

% Calculation of Ptf weights
portfolioValuePtf1 = sum(absQuantities .* currentPrices);
weightsPtf1 = (absQuantities .* currentPrices) / portfolioValuePtf1;

[ES_HS_Ptf1, VaR_HS_Ptf1] = HSMeasures(alpha, weightsPtf1, portfolioValuePtf1, riskMeasureTimeIntervalInDays_Ptf1, returnsSelected1);

%% Bootstrap Method - Ptf1
rng(1);
M = 200;
num_days = size(returnsSelected1, 1);

% x is just a dummy variable so that arrayfun can work with the function
% handle. We extract the same day for each Asset to preserve correlation.
single_boot_step = @(x) HSMeasures(alpha, ...
                                   weightsPtf1, ...
                                   portfolioValuePtf1, ...
                                   riskMeasureTimeIntervalInDays, ...
                                   returnsSelected1(randi(num_days, num_days, 1), :));

[boot_ES_array, boot_VaR_array] = arrayfun(single_boot_step, 1:M);

VaR_BS_Ptf1 = mean(boot_VaR_array);
ES_BS_Ptf1 = mean(boot_ES_array);

fprintf('\n==================================================\n');
fprintf(' PORTFOLIO 1: HISTORICAL SIMULATION & BOOTSTRAP\n');
fprintf('==================================================\n');
fprintf(' --- Historical Simulation ---\n');
fprintf(' VaR (99%%, 1 Day) : %15.2f EUR\n', VaR_HS_Ptf1);
fprintf(' ES  (99%%, 1 Day) : %15.2f EUR\n', ES_HS_Ptf1);
fprintf(' --- Bootstrap (200 Simulations) ---\n');
fprintf(' VaR (99%%, 1 Day) : %15.2f EUR\n', VaR_BS_Ptf1);
fprintf(' ES  (99%%, 1 Day) : %15.2f EUR\n', ES_BS_Ptf1);
%% Weighted Historical Simulation - Ptf2
sharesListPtf2 = {'Vivendi'; 'AXA'; 'ENEL'; 'Volkswagen'; 'Schneider'}; 
lambda = 0.98;
riskMeasureTimeIntervalInDays_Ptf2 = 1;

% Extraction of today's prices
[tSelected, returnsSelected2] = returnsOfInterest(inputFile, refDate, -timeWindow, sharesListPtf2, formatDate);
[shareData.num, shareData.cell] = xlsread(inputFile, 'Data', 'a5:cx1295');
%{
currentPrices = zeros(length(sharesListPtf2), 1);
for i = 1:length(sharesListPtf2)
    bbgCode = underlyingCode(sharesListPtf2{i});
    [val, t_val] = findSeries(shareData, bbgCode, formatDate);
    idx = find(t_val <= datenum(refDate));
    currentPrices(i) = val(idx(end)); 
end
%}
% Calculation of Ptf weights
weightsPtf2 = ones(length(sharesListPtf2),1)/length(sharesListPtf2);

portfolioValuePtf2 = 1;
[ES_WHS_Ptf2, VaR_WHS_Ptf2] = WHSMeasures(alpha, lambda, weightsPtf2, portfolioValuePtf2, riskMeasureTimeIntervalInDays_Ptf2, returnsSelected2);
fprintf('\n==================================================\n');
fprintf(' PORTFOLIO 2: WEIGHTED HISTORICAL SIMULATION\n');
fprintf('==================================================\n');
fprintf(' VaR (99%%, 1 Day) : %15.6f (Relative)\n', VaR_WHS_Ptf2);
fprintf(' ES  (99%%, 1 Day) : %15.6f (Relative)\n', ES_WHS_Ptf2);
%% Gaussian parametric PCA - Ptf3
sharesListPtf3 = {'AirLiquide';'Allianz';'InBev';'Arcelor';'ASML';'Generali';'AXA';'BBVA';'Santander';'BASF';'Bayer';'BMW';'BNP';'Carrefour';'StGobain';'CRH';'Daimler';'Danone';'DB';'DT';'EON';'ENEL';'ENI';'Essilor';'FT'}; % Extraction of the first 25 Assets
riskMeasureTimeIntervalInDays_Ptf3 = 10;
portfolioValuePtf3 = 15e6; % Notional €15 Mln

[tSelected, returnsSelected3] = returnsOfInterest(inputFile, refDate, -timeWindow, sharesListPtf3, formatDate);
% Calculation of Equally weighted Ptf
weightsPtf3 = ones(length(sharesListPtf3),1)/length(sharesListPtf3);

% Calculation of full Gaussian approach VaR:
sigma = cov(returnsSelected3);
z = norminv(alpha);
stdDev_full = sqrt(weightsPtf3' * sigma * weightsPtf3);
VaR_full = z * stdDev_full * sqrt(riskMeasureTimeIntervalInDays_Ptf3) * portfolioValuePtf3;

% Preallocate usefull variables
n_5_percent = 0; n_1_percent = 0;
ES_PCA_5_percent = 0; ES_PCA_1_percent = 0;
VaR_PCA_5_percent = 0; VaR_PCA_1_percent = 0;

for k = 1:length(sharesListPtf3)
    [ES_PCA, VaR_PCA] = PCAMeasures(alpha, k, weightsPtf3, portfolioValuePtf3, riskMeasureTimeIntervalInDays_Ptf3, returnsSelected3);
    error_pca = (VaR_full - VaR_PCA) / VaR_full;
    
    if error_pca <= 0.05 && n_5_percent == 0
        n_5_percent = k; ES_PCA_5_percent = ES_PCA; VaR_PCA_5_percent = VaR_PCA;
    end
    
    if error_pca <= 0.01 && n_1_percent == 0
        n_1_percent = k; ES_PCA_1_percent = ES_PCA; VaR_PCA_1_percent = VaR_PCA;
    end
end
fprintf('\n==================================================\n');
fprintf(' PORTFOLIO 3: GAUSSIAN PARAMETRIC PCA\n');
fprintf('==================================================\n');
fprintf(' Full Gaussian VaR (99%%, 10 Days) : %15.2f EUR\n', VaR_full);
fprintf(' --- Approximation Errors ---\n');
fprintf(' Min PCs for < 5%% error : %d\n', n_5_percent);
fprintf(' -> PCA VaR (5%% threshold) : %15.2f EUR\n', VaR_PCA_5_percent);
fprintf(' -> PCA ES  (5%% threshold) : %15.2f EUR\n', ES_PCA_5_percent);
fprintf(' Min PCs for < 1%% error : %d\n', n_1_percent);
fprintf(' -> PCA VaR (1%% threshold) : %15.2f EUR\n', VaR_PCA_1_percent);
fprintf(' -> PCA ES  (1%% threshold) : %15.2f EUR\n', ES_PCA_1_percent);

%% Plausibility Check
VaR_plausible_Ptf1 = PlausibilityCheckVaR(alpha, weightsPtf1, portfolioValuePtf1, riskMeasureTimeIntervalInDays_Ptf1, returnsSelected1);
VaR_plausible_Ptf2 = PlausibilityCheckVaR(alpha, weightsPtf2, portfolioValuePtf2, riskMeasureTimeIntervalInDays_Ptf2, returnsSelected2);
VaR_plausible_Ptf3 = PlausibilityCheckVaR(alpha, weightsPtf3, portfolioValuePtf3, riskMeasureTimeIntervalInDays_Ptf3, returnsSelected3);

fprintf('\n==================================================\n');
fprintf(' PLAUSIBILITY CHECK\n');
fprintf('==================================================\n');
fprintf(' Ptf1 Plausible VaR (99%%,  1 Day) : %15.2f EUR\n', VaR_plausible_Ptf1);
fprintf(' Ptf2 Plausible VaR (99%%,  1 Day) : %15.6f (Relative)\n', VaR_plausible_Ptf2);
fprintf(' Ptf3 Plausible VaR (99%%, 10 Days): %15.2f EUR\n', VaR_plausible_Ptf3);
%% Es2 
inputFile = 'sx5e_historical_data.xls';
refDate = datenum('15 Feb 08');   %we start taking values from here
valuationDate = datenum('15 Feb 10');  
NumberOfYears=2;
timeWindow = 12*NumberOfYears;
shares=cellstr('Generali'); 
formatDate = 'dd/mm/yyyy';   %modified
[tSelected, returnsSelected] = returnsOfInterest(inputFile, refDate, timeWindow, shares, formatDate); %get returns  
costOfShares = 1164000;
[shareData.num,shareData.cell]=xlsread(inputFile,'Data','a5:cx1295');
[values_G, dates_G] = findSeries(shareData,underlyingCode('Generali'), formatDate);
idx = find(dates_G <= valuationDate, 1, 'last');
stockPrice = values_G(idx);
numberOfShares = costOfShares / stockPrice;
numberOfPuts = numberOfShares;
expiry = datenum('18 Apr 10');
strike = 28.5;
volatility = 0.223;   %yearly
dividendYield = 0.051;    %yearly
alpha = 0.99;
TTMinYears = (expiry - valuationDate) / 365;
riskMeasureTimeIntervalInDays = 1;
[datesSet, ratesSet] = readExcelData('MktData_CurveBootstrap.xls', formatDate);
[dates, discounts, zeroRates]=bootstrap(datesSet, ratesSet);
idx = find(dates <= valuationDate, 1, 'last');
rate = zeroRates(idx);
VaR_FullMonteCarlo = FullMonteCarloVaR(alpha, numberOfShares, numberOfPuts, stockPrice, strike, rate, dividendYield, volatility, TTMinYears, riskMeasureTimeIntervalInDays, returnsSelected); 
VaR_DeltaNormal = DeltaNormalVaR(alpha, numberOfShares, numberOfPuts, stockPrice, strike, rate, dividendYield, volatility, TTMinYears, riskMeasureTimeIntervalInDays, returnsSelected);
fprintf('\n==================================================\n');
fprintf(' EXERCISE 2: FULL MONTE CARLO & DELTA NORMAL\n');
fprintf('==================================================\n');
fprintf(' Delta Normal VaR     (99%%, 1 Day) : %15.2f EUR\n', VaR_DeltaNormal);
fprintf(' Full Monte Carlo VaR (99%%, 1 Day) : %15.2f EUR\n', VaR_FullMonteCarlo);
fprintf('==================================================\n\n');