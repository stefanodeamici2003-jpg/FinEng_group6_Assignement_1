function VaR = PlausibilityCheckVaR(alpha, weights, portfolioValue, riskMeasureTimeIntervalInDays, returns)
% PLAUSIBILITYCHECKVAR Computes a Plausibility Check VaR for a portfolio.
%
% INPUTS:
% - alpha                         : confidence level for the risk measures (e.g. 0.99)
% - weights                       : Nx1 column vector with the weights of the N assets
% - portfolioValue                : total notional value of the portfolio
% - riskMeasureTimeIntervalInDays : time horizon for the risk measure in days
% - returns                       : TxN matrix of historical daily returns
% 
% OUTPUTS:
% - VaR                           : Plausibility check Value at Risk in monetary terms

    sens = weights * portfolioValue; % Nx1 vector

    l = quantile(returns, 1 - alpha); 
    u = quantile(returns, alpha);
    
    sVaR = sens .* (abs(l') + abs(u')) ./ 2;
    
    % Apply the square-root-of-time rule for the given time horizon
    sVaR = sVaR * sqrt(riskMeasureTimeIntervalInDays);
    
    C = corr(returns);
    
    VaR = sqrt(sVaR' * C * sVaR);
end