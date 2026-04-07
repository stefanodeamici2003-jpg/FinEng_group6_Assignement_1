function VaR = FullMonteCarloVaR(alpha, numberOfShares, numberOfPuts, ...
    stockPrice, strike, rate, dividendYield, volatility, TTMinYears, ...
    riskMeasureTimeIntervalInDays, returns)

% This function computes the Value at Risk (VaR) of a portfolio
% composed of stocks and put options using a Full Monte Carlo approach.
%
% INPUTS:
% alpha  -> confidence level 
% numberOfShares -> number of shares in the portfolio
% numberOfPuts   -> number of put options (same underlying)
% stockPrice     -> current stock price
% strike         -> strike of the put option
% rate           -> risk-free rate (annual, scalar)
% dividendYield  -> dividend yield (annual)
% volatility     -> volatility (annual)
% TTMinYears     -> time to maturity (in years)
% riskMeasureTimeIntervalInDays -> VaR horizon (in days)
% returns        -> vector of historical daily returns
%
% OUTPUT:
% VaR -> Value at Risk at level alpha

%Initial portfolio value
[~, putPrice0] = blsprice(stockPrice, strike, rate, TTMinYears, volatility, dividendYield);
V0 = numberOfShares * stockPrice + numberOfPuts * putPrice0;

%Adjust time to maturity after one day
TTM_new = TTMinYears - riskMeasureTimeIntervalInDays/365; 

%Vectorized Monte Carlo simulation
%Simulate next-day stock prices
% Each historical return generates one scenario
S_new = stockPrice * exp(returns);   %returns are log

% Reprice the put option
% blsprice works element-wise on vectors of underlying prices
% It returns two vectors: call prices and put prices
[~, putPrices] = blsprice(S_new, strike, rate, TTM_new, volatility, dividendYield);

% Total portfolio value (vector)
V_new = numberOfShares * S_new + numberOfPuts * putPrices;

% Compute Profit & Loss
PnL = V_new - V0;   % (nScenarios x 1 vector)

%Compute VaR
VaR = -quantile(PnL, 1 - alpha);
%fprintf('The Monte Carlo VaR at %.0f%% confidence level (based on %d scenarios) is: %.4f\n', alpha*100, length(returns), VaR);
end