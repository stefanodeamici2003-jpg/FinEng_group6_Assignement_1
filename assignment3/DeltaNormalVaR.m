function VaR = DeltaNormalVaR(alpha, numberOfShares, numberOfPuts, ...
    stockPrice, strike, rate, dividendYield, volatility, TTMinYears, ...
    riskMeasureTimeIntervalInDays, returns)
% This function computes the Value at Risk (VaR) of a portfolio
% using a Delta approximation with historical scenarios.
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
% returns        -> vector of historical daily log-returns
%
% OUTPUT:
% VaR -> Value at Risk at level alpha
% Adjust time to maturity (coherence with Full Monte Carlo)
TTM_new = TTMinYears - riskMeasureTimeIntervalInDays/365;

% Compute delta of the put option with updated maturity
[~, putDelta] = blsdelta(stockPrice, strike, rate, TTM_new, volatility, dividendYield);

% Compute total portfolio delta
% Shares have delta = 1
% Put options have delta = putDelta
deltaPortfolio = numberOfShares + numberOfPuts * putDelta;

% Linear approximation of portfolio P&L under historical scenarios
% Using log-returns: ΔS ≈ S * returns
PnL = deltaPortfolio * stockPrice * (exp(returns) - 1);

% Compute VaR using historical quantile
VaR = -quantile(PnL, 1 - alpha);

%fprintf('The Delta (historical) VaR at %.0f%% confidence level (based on %d scenarios) is: %.4f\n', alpha*100, length(returns), VaR);
end