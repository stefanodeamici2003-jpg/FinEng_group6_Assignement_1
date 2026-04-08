function VaR = DeltaGammaNormalVaR(alpha, numberOfShares, numberOfPuts, ...
    stockPrice, strike, rate, dividendYield, volatility, TTMinYears, ...
    riskMeasureTimeIntervalInDays, returns)

% Delta and Gamma of the put option 
TTM_new = TTMinYears - riskMeasureTimeIntervalInDays/365;
[~, putDelta] = blsdelta(stockPrice, strike, rate, TTM_new, volatility, dividendYield);
putGamma = blsgamma(stockPrice, strike, rate, TTM_new, volatility, dividendYield);

% Total portfolio sensitivities
deltaPortfolio = numberOfShares + numberOfPuts * putDelta;
gammaPortfolio = numberOfPuts * putGamma;

% Convert log-returns into price changes
dS = stockPrice * (exp(returns) - 1);

% Delta-Gamma PnL approximation
PnL = deltaPortfolio * dS + 0.5 * gammaPortfolio * (dS.^2);

% Compute VaR from empirical distribution
VaR = -quantile(PnL, 1 - alpha);

%fprintf('The Delta-Gamma (historical) VaR at %.0f%% confidence level (based on %d scenarios) is: %.4f\n',alpha*100, length(returns), VaR);

end