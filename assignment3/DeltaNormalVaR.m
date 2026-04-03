function VaR = DeltaNormalVaR(alpha, numberOfShares, numberOfPuts, ...
    stockPrice, strike, rate, dividendYield, volatility, TTMinYears, ...
    riskMeasureTimeIntervalInDays, returns)

% This function computes the Value at Risk (VaR) of a portfolio
% using the Delta-Normal approximation.
%
% The portfolio is approximated as linear with respect to the
% underlying asset using the option delta.
%
% INPUTS:
% alpha  -> confidence level 
% numberOfShares -> number of shares in the portfolio
% numberOfPuts   -> number of put options
% stockPrice     -> current stock price
% strike         -> strike of the put option
% rate           -> risk-free rate (annual)
% dividendYield  -> dividend yield (annual)
% volatility     -> volatility (annual)
% TTMinYears     -> time to maturity (in years)
% riskMeasureTimeIntervalInDays -> VaR horizon (in days)
% returns        -> vector of historical daily returns
%
% OUTPUT:
% VaR -> Value at Risk at level alpha

% Compute delta of the put option
[~, putDelta] = blsdelta(stockPrice, strike, rate, TTMinYears, volatility, dividendYield);

% Compute total portfolio delta
% Shares have delta = 1
% Put options have delta = putDelta
deltaPortfolio = numberOfShares + numberOfPuts * putDelta;

% Estimate volatility of returns
% Standard deviation of historical returns (daily)
sigma = std(returns);

% Scale volatility to the VaR horizon
sigma_horizon = sigma * sqrt(riskMeasureTimeIntervalInDays);

% Compute quantile of the standard normal distribution
z_alpha = norminv(1-alpha); 

% Compute VaR
% Linear approximation of portfolio P&L:
% PnL ≈ deltaPortfolio * stockPrice * returns
VaR = -z_alpha * sigma_horizon * deltaPortfolio * stockPrice;
fprintf('The Delta-Normal VaR at %.0f%% confidence level is: %.4f\n', alpha*100, VaR);

end