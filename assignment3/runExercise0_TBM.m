clc; clear all;
%% Exercise 1
%% Parameters
inputFile = 'sx5e_historical_data.xls'; formatDate = 'dd/mm/yyyy'; alpha = 0.95; refDate = datenum('24 Jul 12');
% Load data ONCE to save time and lines
[shareData.num, shareData.cell] = xlsread(inputFile, 'Data', 'a5:cx1295');
[datesSet, ratesSet] = readExcelData('MktData_CurveBootstrap.xls', formatDate);
[dates, discounts, zeroRates] = bootstrap(datesSet, ratesSet);
%% Select returns of interest
timeWindow = 12 * 2; 
sharesList = {'Inditex'; 'BASF'; 'LVMH'}; 
[~, returnsSelected] = returnsOfInterest(inputFile, refDate, -timeWindow, sharesList, formatDate);
%% Compute Risk Measurements
portfolioValue = 1e7; riskMeasureTimeIntervalInDays = 1; numberAssets = size(sharesList,1);
weights = (1/numberAssets) * ones(numberAssets,1);
try
    [ES_PCA, VaR] = AnalyticNormalMeasures(alpha, weights, portfolioValue, riskMeasureTimeIntervalInDays, returnsSelected); 
catch err
    err.message
end
%% Historical Simulation - Ptf1
sharesListPtf1 = {'ENI'; 'Telefonica'; 'EON'; 'Daimler'};  absQuantities = [18e3; 25e3; 15e3; 9e3];
alpha = 0.99; riskMeasureTimeIntervalInDays_Ptf1 = 1;

[tSelected, returnsSelected1] = returnsOfInterest(inputFile, refDate, -timeWindow, sharesListPtf1, formatDate);

% Calculate current prices using the getLatestPrice helper function
currentPrices = zeros(length(sharesListPtf1), 1);
for i = 1:length(sharesListPtf1)
    bbgCode = underlyingCode(sharesListPtf1{i});
    currentPrices(i) = getLatestPrice(shareData, bbgCode, formatDate, refDate);
end

portfolioValuePtf1 = sum(absQuantities .* currentPrices);
weightsPtf1 = (absQuantities .* currentPrices) / portfolioValuePtf1;
[ES_HS_Ptf1, VaR_HS_Ptf1] = HSMeasures(alpha, weightsPtf1, portfolioValuePtf1, riskMeasureTimeIntervalInDays_Ptf1, returnsSelected1);
%% Bootstrap Method - Ptf1
rng(1); M = 200; num_days = size(returnsSelected1, 1);

single_boot_step = @(x) HSMeasures(alpha, weightsPtf1, portfolioValuePtf1, riskMeasureTimeIntervalInDays_Ptf1, returnsSelected1(randi(num_days, num_days, 1), :));
[boot_ES_array, boot_VaR_array] = arrayfun(single_boot_step, 1:M);

VaR_BS_Ptf1 = mean(boot_VaR_array);
ES_BS_Ptf1 = mean(boot_ES_array);
%% Weighted Historical Simulation - Ptf2
sharesListPtf2 = {'Vivendi'; 'AXA'; 'ENEL'; 'Volkswagen'; 'Schneider'}; 
lambda = 0.98; riskMeasureTimeIntervalInDays_Ptf2 = 1;
% Extraction of today's prices
[tSelected, returnsSelected2] = returnsOfInterest(inputFile, refDate, -timeWindow, sharesListPtf2, formatDate);
[shareData.num, shareData.cell] = xlsread(inputFile, 'Data', 'a5:cx1295');
weightsPtf2 = ones(length(sharesListPtf2),1)/length(sharesListPtf2);
portfolioValuePtf2 = 1;

[ES_WHS_Ptf2, VaR_WHS_Ptf2] = WHSMeasures(alpha, lambda, weightsPtf2, portfolioValuePtf2, riskMeasureTimeIntervalInDays_Ptf2, returnsSelected2);
%% Gaussian parametric PCA - Ptf3
sharesListPtf3 = {'AirLiquide';'Allianz';'InBev';'Arcelor';'ASML';'Generali';'AXA';'BBVA';'Santander';'BASF';'Bayer';'BMW';'BNP';'Carrefour';'StGobain';'CRH';'Daimler';'Danone';'DB';'DT';'EON';'ENEL';'ENI';'Essilor';'FT'}; % Extraction of the first 25 Assets
riskMeasureTimeIntervalInDays_Ptf3 = 10; portfolioValuePtf3 = 15e6;
[tSelected, returnsSelected3] = returnsOfInterest(inputFile, refDate, -timeWindow, sharesListPtf3, formatDate);

weightsPtf3 = ones(length(sharesListPtf3),1)/length(sharesListPtf3);
sigma = cov(returnsSelected3);
z = norminv(alpha);
stdDev_full = sqrt(weightsPtf3' * sigma * weightsPtf3);
VaR_full = z * stdDev_full * sqrt(riskMeasureTimeIntervalInDays_Ptf3) * portfolioValuePtf3;

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
%% Plausibility Check
VaR_plausible_Ptf1 = PlausibilityCheckVaR(alpha, weightsPtf1, portfolioValuePtf1, riskMeasureTimeIntervalInDays_Ptf1, returnsSelected1);
VaR_plausible_Ptf2 = PlausibilityCheckVaR(alpha, weightsPtf2, portfolioValuePtf2, riskMeasureTimeIntervalInDays_Ptf2, returnsSelected2);
VaR_plausible_Ptf3 = PlausibilityCheckVaR(alpha, weightsPtf3, portfolioValuePtf3, riskMeasureTimeIntervalInDays_Ptf3, returnsSelected3);
%% Exercise 2 
valuationDate = datenum('15 Feb 2010'); 
shares = cellstr('Generali'); 
[tSelected, returnsSelected] = returnsOfInterest(inputFile, valuationDate, -timeWindow, shares, formatDate);
costOfShares = 1164000;
% Retrieve stock price using the getLatestPrice helper function
stockPrice = getLatestPrice(shareData, underlyingCode('Generali'), formatDate, valuationDate); 
numberOfShares = costOfShares / stockPrice; numberOfPuts = numberOfShares;
expiry = datenum('18 Apr 2010');
strike = 28.5; volatility = 0.223; dividendYield = 0.051; alpha = 0.99; riskMeasureTimeIntervalInDays = 1;
TTMinYears = (expiry - valuationDate) / 365;

rate = interp1(dates, zeroRates, valuationDate); % Rate is interpolated using the curves loaded at the beginning

VaR_FullMonteCarlo = FullMonteCarloVaR(alpha, numberOfShares, numberOfPuts, stockPrice, strike, rate, dividendYield, volatility, TTMinYears, riskMeasureTimeIntervalInDays, returnsSelected); 
VaR_DeltaNormal = DeltaNormalVaR(alpha, numberOfShares, numberOfPuts, stockPrice, strike, rate, dividendYield, volatility, TTMinYears, riskMeasureTimeIntervalInDays, returnsSelected);
VaR_DeltaGammaNormal = DeltaGammaNormalVaR(alpha, numberOfShares, numberOfPuts, stockPrice, strike, rate, dividendYield, volatility, TTMinYears, riskMeasureTimeIntervalInDays, returnsSelected);
%% Exercise 3: Pricing in presence of counterparty risk
S0 = 1; sigma = 0.19; N_period = 5; Notional = 45e6; t = yearfrac(dates(1), dates, 3); r = interp1(t, zeroRates, 1.0);

V_rf = price_cliquet(S0, sigma, r, N_period, Notional);
defaultProb = 0.02; recovery = 0.40;
CVA = defaultProb * (1 - recovery) * V_rf;
V_adj = V_rf - CVA;
%% CONSOLIDATED PRINTS (EXERCISES 1, 2, 3)
fprintf('\n==================================================\n EXERCISE 0: ANALYTIC NORMAL MEASURES\n==================================================\n VaR (95%%, 1 Day) : %15.2f EUR\n ES  (95%%, 1 Day) : %15.2f EUR\n', VaR, ES_PCA);
fprintf('\n==================================================\n PORTFOLIO 1: HISTORICAL SIMULATION & BOOTSTRAP\n==================================================\n --- Historical Simulation ---\n VaR (99%%, 1 Day) : %15.2f EUR\n ES  (99%%, 1 Day) : %15.2f EUR\n --- Bootstrap (200 Simulations) ---\n VaR (99%%, 1 Day) : %15.2f EUR\n ES  (99%%, 1 Day) : %15.2f EUR\n', VaR_HS_Ptf1, ES_HS_Ptf1, VaR_BS_Ptf1, ES_BS_Ptf1);
fprintf('\n==================================================\n PORTFOLIO 2: WEIGHTED HISTORICAL SIMULATION\n==================================================\n VaR (99%%, 1 Day) : %15.6f (Relative)\n ES  (99%%, 1 Day) : %15.6f (Relative)\n', VaR_WHS_Ptf2, ES_WHS_Ptf2);
fprintf('\n==================================================\n PORTFOLIO 3: GAUSSIAN PARAMETRIC PCA\n==================================================\n Full Gaussian VaR (99%%, 10 Days) : %15.2f EUR\n --- Approximation Errors ---\n Min PCs for < 5%% error : %d\n -> PCA VaR (5%% threshold) : %15.2f EUR\n -> PCA ES  (5%% threshold) : %15.2f EUR\n Min PCs for < 1%% error : %d\n -> PCA VaR (1%% threshold) : %15.2f EUR\n -> PCA ES  (1%% threshold) : %15.2f EUR\n', VaR_full, n_5_percent, VaR_PCA_5_percent, ES_PCA_5_percent, n_1_percent, VaR_PCA_1_percent, ES_PCA_1_percent);
fprintf('\n==================================================\n PLAUSIBILITY CHECK\n==================================================\n Ptf1 Plausible VaR (99%%,  1 Day) : %15.2f EUR\n Ptf2 Plausible VaR (99%%,  1 Day) : %15.6f (Relative)\n Ptf3 Plausible VaR (99%%, 10 Days): %15.2f EUR\n', VaR_plausible_Ptf1, VaR_plausible_Ptf2, VaR_plausible_Ptf3);
fprintf('\n==================================================\n EXERCISE 2: FULL MONTE CARLO & DELTA NORMAL\n==================================================\n Full Monte Carlo VaR   (99%%, 1 Day) : %15.4f EUR\n Delta Normal VaR       (99%%, 1 Day) : %15.4f EUR\n Delta Gamma Normal VaR (99%%, 1 Day) : %15.4f EUR\n==================================================\n\n', VaR_FullMonteCarlo, VaR_DeltaNormal, VaR_DeltaGammaNormal);
fprintf('\n==================================================\n EXERCISE 3: COUNTERPARTY RISK\n==================================================\n Fair Value (Risk-Free) : %15.0f EUR\n CVA-Adjusted Value     : %15.0f EUR\n\n', V_rf, V_adj);
%% Exercise 4
%% Parameters
p   = 0.05;  rho = 0.40; R   = 0.20;   % default probability, correlation, recovery
LGD = 1 - R;
%% Common factor Y grid
c    = norminv(p); y    = linspace(-6, 6, 2000); dy   = y(2) - y(1);
phiY = normpdf(y);
pY   = normcdf((c - sqrt(rho)*y) / sqrt(1-rho));  % p(y), 1x2000
KL_div = @(z, p) z.*log(z./p) + (1-z).*log((1-z)./(1-p));

I_exact  = [10, 20, 30, 50, 75, 100, 150, 200, 400, 600, 1000, 2000, 5000];
I_kl     = unique(round(logspace(1, log10(2e4), 80)));
%% a) mezzanine tranche
Kd  = 0.05;   Ku  = 0.09; % attachment and detachment point
% Call external function for Mezzanine calculations
[price_LHP, price_exact, price_kl] = computeTranchePrices(Kd, Ku, LGD, c, rho, pY, phiY, dy, y, I_exact, I_kl, KL_div);

fprintf('LHP price = %.4f%%\n', price_LHP);
for idx = 1:length(I_exact)
    fprintf('I = %5d,  price = %.4f%%\n', I_exact(idx), price_exact(idx));
end
%% Plot 
plotTranchePrice(I_kl, price_kl, I_exact, price_exact, price_LHP, 'mezzanine');
%% b) equity tranche
Kd_eq = 0.00; Ku_eq = 0.05;
% Call external function for Equity calculations
[price_LHP_eq, price_exact_eq, price_kl_eq] = computeTranchePrices(Kd_eq, Ku_eq, LGD, c, rho, pY, phiY, dy, y, I_exact, I_kl, KL_div);

fprintf('LHP equity price = %.4f%%\n', price_LHP_eq);
for idx = 1:length(I_exact)
    fprintf('I = %5d,  equity price = %.4f%%\n', I_exact(idx), price_exact_eq(idx));
end
%% Plot - equity
plotTranchePrice(I_kl, price_kl_eq, I_exact, price_exact_eq, price_LHP_eq, 'equity')