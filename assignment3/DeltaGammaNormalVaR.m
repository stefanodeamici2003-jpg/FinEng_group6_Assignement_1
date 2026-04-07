function VaR = DeltaGammaNormalVaR(alpha, numberOfShares, numberOfPuts, ...
    stockPrice, strike, rate, dividendYield, volatility, TTMinYears, ...
    riskMeasureTimeIntervalInDays, returns)
% This function computes the VaR using the Delta-Gamma-Normal approximation.
% The P&L is approximated up to second order in the underlying price change.
%
% OUTPUT:
% VaR -> Value at Risk at level alpha via Cornish-Fisher expansion

% Delta and Gamma of the put option
[~, putDelta] = blsdelta(stockPrice, strike, rate, TTMinYears, volatility, dividendYield);
putGamma = blsgamma(stockPrice, strike, rate, TTMinYears, volatility, dividendYield);

% Total portfolio delta and gamma
% Shares: delta = 1, gamma = 0
deltaPortfolio = numberOfShares + numberOfPuts * putDelta;
gammaPortfolio = numberOfPuts * putGamma;

% Daily volatility of the underlying (in price terms)
sigma = std(returns) * stockPrice;
sigma_horizon = sigma * sqrt(riskMeasureTimeIntervalInDays);

% Moments of the P&L distribution under Delta-Gamma approximation
% PnL ≈ delta * dS + 0.5 * gamma * dS^2
% where dS = stockPrice * r ~ N(0, sigma_horizon^2)
mu_PnL    = 0.5 * gammaPortfolio * sigma_horizon^2;
sigma_PnL = sqrt((deltaPortfolio * sigma_horizon)^2 + ...
                 0.5 * (gammaPortfolio * sigma_horizon^2)^2);

% Skewness and excess kurtosis of the P&L
skew = (gammaPortfolio * sigma_horizon^2 * deltaPortfolio * sigma_horizon) / sigma_PnL^3;
kurt = 0.5 * (gammaPortfolio * sigma_horizon^2)^2 / sigma_PnL^4;   % excess kurtosis

% Cornish-Fisher adjusted quantile
z = norminv(1 - alpha);
z_cf = z + (z^2 - 1) * skew/6 + (z^3 - 3*z) * kurt/24 - (2*z^3 - 5*z) * skew^2/36;

% VaR
VaR = -(mu_PnL + z_cf * sigma_PnL);
%fprintf('The Delta-Gamma-Normal VaR at %.0f%% confidence level is: %.4f\n', alpha*100, VaR);

end