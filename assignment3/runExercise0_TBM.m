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
formatDate = 'mm/dd/yyyy';
alpha=0.95;

% Input parameters
refDate=datenum('Jul 24 12');
NumberOfYears=2;
timeWindow = 12*NumberOfYears;
sharesList=cellstr({'Inditex'; 'BASF'; 'LVMH'}); 
numberAssets = size(sharesList,1);
weights=(1/numberAssets)*ones(numberAssets,1);

%% Select returns of interest
[tSelected, returnsSelected] = returnsOfInterest(inputFile, refDate, timeWindow, sharesList, formatDate);
returnsSelected;


%% Compute Risk Measurements

% Analytic VaR & ES (Normal)
% It computes mean and VarCovar on the proper time scale
portfolioValue = 1e7;
riskMeasureTimeIntervalInDays = 1;
try
    [ES, VaR] = AnalyticNormalMeasures(alpha, weights, portfolioValue, riskMeasureTimeIntervalInDays, returnsSelected); 
catch err
    err.message
end


%% Historical Simulation
% TBC

%% Plausibility Check
% TBC

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
>>>>>>> d16b333 (ex 4 to continue)

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

%% Historical Simulation - Ptf1
sharesListPtf1 = {'ENI'; 'Telefonica'; 'EON'; 'Daimler'}; 
absQuantities = [18e3; 25e3; 15e3; 9e3];
alpha = 0.99;
riskMeasureTimeIntervalInDays_Ptf1 = 1;

% Extraction of today's prices
[tSelected, returnsSelected1] = returnsOfInterest(inputFile, refDate, timeWindow, sharesListPtf1, formatDate);
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

fprintf('Historical Simulation VaR: %f\n', VaR_HS_Ptf1);
fprintf('Bootstrap VaR (200 sim): %f\n', VaR_BS_Ptf1);

%% Weighted Historical Simulation - Ptf2
sharesListPtf2 = {'Vivendi'; 'AXA'; 'ENEL'; 'Volkswagen'; 'Schneider'}; 
lambda = 0.98;
riskMeasureTimeIntervalInDays_Ptf2 = 1;

% Extraction of today's prices
[tSelected, returnsSelected2] = returnsOfInterest(inputFile, refDate, timeWindow, sharesListPtf2, formatDate);
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

%% Gaussian parametric PCA - Ptf3
sharesListPtf3 = {'AirLiquide';'Allianz';'InBev';'Arcelor';'ASML';'Generali';'AXA';'BBVA';'Santander';'BASF';'Bayer';'BMW';'BNP';'Carrefour';'StGobain';'CRH';'Daimler';'Danone';'DB';'DT';'EON';'ENEL';'ENI';'Essilor';'FT'}; % Extraction of the first 25 Assets
riskMeasureTimeIntervalInDays_Ptf3 = 10;
portfolioValuePtf3 = 15e6; % Notional €15 Mln

[tSelected, returnsSelected3] = returnsOfInterest(inputFile, refDate, timeWindow, sharesListPtf3, formatDate);

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
VaR_PCA_1_percent
fprintf('Min PC for <5%% error: %d\n', n_5_percent);
fprintf('Min PC for <1%% error: %d\n', n_1_percent);
%% Plausibility Check
VaR_plausible_Ptf1 = PlausibilityCheckVaR(alpha, weightsPtf1, portfolioValuePtf1, riskMeasureTimeIntervalInDays_Ptf1, returnsSelected1);
VaR_plausible_Ptf2 = PlausibilityCheckVaR(alpha, weightsPtf2, portfolioValuePtf2, riskMeasureTimeIntervalInDays_Ptf2, returnsSelected2);
VaR_plausible_Ptf3 = PlausibilityCheckVaR(alpha, weightsPtf3, portfolioValuePtf3, riskMeasureTimeIntervalInDays_Ptf3, returnsSelected3);

fprintf('Plausibility VaR Ptf1 (99%%, %d Day) : %f Euro\n',riskMeasureTimeIntervalInDays_Ptf1, VaR_plausible_Ptf1);
fprintf('Plausibility VaR Ptf2 (99%%, %d Day) : %f Euro\n',riskMeasureTimeIntervalInDays_Ptf2, VaR_plausible_Ptf2);
fprintf('Plausibility VaR Ptf3 (99%%, %d Day) : %f Euro\n',riskMeasureTimeIntervalInDays_Ptf3, VaR_plausible_Ptf3);
%% Es2 
inputFile = 'sx5e_historical_data.xls';
refDate = datenum('15 Feb 08');   %we start taking values from here
valuationDate = datenum('15 Feb 10');  
NumberOfYears=2;
timeWindow = 12*NumberOfYears;
shares=cellstr('Generali'); 
formatDate = 'dd/mm/yyyy';   %modified
[tSelected, returnsSelected3] = returnsOfInterest(inputFile, refDate, timeWindow, shares, formatDate); %get returns  
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
VaR_FullMonteCarlo = FullMonteCarloVaR(alpha, numberOfShares, numberOfPuts, stockPrice, strike, rate, dividendYield, volatility, TTMinYears, riskMeasureTimeIntervalInDays, returnsSelected3); 
VaR_DeltaNormal = DeltaNormalVaR(alpha, numberOfShares, numberOfPuts, stockPrice, strike, rate, dividendYield, volatility, TTMinYears, riskMeasureTimeIntervalInDays, returnsSelected3);

%% MBS Pricing - Mezzanine Tranche
% Parameters
p    = 0.05;
rho  = 0.40;
R    = 0.20;
Kd   = 0.05;
Ku   = 0.09;
LGD  = 1 - R;

% Grid for integration over the common factor Y ~ N(0,1)
y    = linspace(-6, 6, 2000);
dy   = y(2) - y(1);
phiY = normpdf(y);

% Conditional default probability given Y
c    = norminv(p);
pY   = normcdf((c - sqrt(rho)*y) / sqrt(1-rho));

%% 1. LHP Solution
lossY_LHP       = pY * LGD;
trancheLoss_LHP = min(max(lossY_LHP - Kd, 0), Ku - Kd);
EL_LHP          = sum(trancheLoss_LHP .* phiY) * dy;
price_LHP       = (1 - EL_LHP / (Ku - Kd)) * 100;

%% 2. Exact Solution (finite I)
I_exact     = [10, 20, 30, 50, 75, 100, 150, 200, 400, 600, 1000, 2000, 5000];
price_exact = zeros(size(I_exact));

for idx = 1:length(I_exact)
    I  = I_exact(idx);
    EL = 0;
    for k = 0:I
        lf = k/I * LGD;
        tl = min(max(lf - Kd, 0), Ku - Kd);
        if tl == 0, continue; end
        % Integrate over Y
        prob_k = sum(binopdf(k, I, pY) .* phiY) * dy;
        EL = EL + tl * prob_k;
    end
    price_exact(idx) = (1 - EL / (Ku - Kd)) * 100;
    fprintf('I=%d, price=%.4f%%\n', I, price_exact(idx));
end

% 3. KL (Beta) Approximation
mu_ell = p * LGD;

% E[pY^2] for systematic variance — integrated over Y
Ep2    = sum(pY.^2 .* phiY) * dy;
var_sys = LGD^2 * (Ep2 - p^2);

I_kl      = unique(round(logspace(1, log10(2e4), 80)));
price_kl  = zeros(size(I_kl));

for idx = 1:length(I_kl)
    I        = I_kl(idx);
    var_idio = LGD^2 * p*(1-p) / I;
    var_ell  = var_sys + var_idio;

    alpha_b  = mu_ell * (mu_ell*(1-mu_ell)/var_ell - 1);
    beta_b   = (1-mu_ell) * (mu_ell*(1-mu_ell)/var_ell - 1);

    if alpha_b <= 0 || beta_b <= 0
        price_kl(idx) = price_LHP;
        continue;
    end

    EL_kl       = integral(@(x) min(max(x - Kd, 0), Ku - Kd) ...
                    .* betapdf(x, alpha_b, beta_b), 0, 1, 'RelTol', 1e-6);
    price_kl(idx) = (1 - EL_kl / (Ku - Kd)) * 100;
end

%% ---- Plot ----
figure;
semilogx(I_kl,    price_kl,    'b-',  'LineWidth', 2); hold on;
semilogx(I_exact, price_exact, 'ro',  'MarkerSize', 6, 'LineWidth', 1.5);
yline(price_LHP, 'k--', 'LineWidth', 2);
xlabel('Number of obligors I (log scale)');
ylabel('Tranche Price (% of face value)');
title('Mezzanine Tranche Price vs. I — Vasicek Model');
legend('KL (Beta) Approximation', 'Exact Solution', 'LHP Limit', 'Location', 'southeast');
grid on;
xlim([10, 2e4]);


