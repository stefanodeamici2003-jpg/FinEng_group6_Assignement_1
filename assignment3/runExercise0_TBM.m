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
