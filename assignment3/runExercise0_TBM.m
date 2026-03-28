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
refDate=datenum('10 Jul 12');
NumberOfYears=2;
timeWindow = 12*NumberOfYears;
sharesList=cellstr(['AXA     '; 'ENI     '; 'Bayer   ']); 
numberAssets = size(sharesList,1);
weights=(1/numberAssets)*ones(numberAssets,1);

%% Select returns of interest
[tSelected, returnsSelected] = returnsOfInterest(inputFile, refDate, timeWindow, sharesList, formatDate);

%% Compute Risk Measurements

% Analytic VaR & ES (Normal)
% It computes mean and VarCovar on the proper time scale

try
    [ES, VaR] = AnalyticNormalMeasures(alpha, weights, portfolioValue, riskMeasureTimeIntervalInDays, returns); 
catch err
    err.message
end


%% Historical Simulation
% TBC

%% Plausibility Check
% TBC

