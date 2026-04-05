function [ES, VaR] = HSMeasures(alpha, weights, portfolioValue, riskMeasureTimeIntervalInDays, returns)
% Computes Value at Risk (VaR) and Expected Shortfall (ES) of a linear portfolio 
% via Historical Simulation.
% [ES, VaR] = HSMeasures(alpha, weights, portfolioValue, riskMeasureTimeIntervalInDays, returns)
%
% INPUTS:
% - alpha:                         confidence level for the risk measures (e.g. 0.99)
% - weights:                       Nx1 column vector with the weights of the N assets
% - portfolioValue:                total notional value of the portfolio
% - riskMeasureTimeIntervalInDays: time horizon for the risk measure in days
% - returns:                       TxN matrix of historical daily returns
% 
% OUTPUTS:
% - ES:                            Expected Shortfall of the portfolio in monetary terms
% - VaR:                           Value at Risk of the portfolio in monetary terms
%

    % Extract ptf Historical Losses 
    port_returns = returns * weights;
    % Adaptation to correct timewindow
    port_returns = port_returns * riskMeasureTimeIntervalInDays;
    losses = -port_returns * portfolioValue;
    % Sort from highest to lowest loss
    orderedLoss = sort(losses, 'descend');
    n = length(orderedLoss);
    % Taking the floor numer to be more restrictive, or one to avoid any bugs
    idx = max(1, floor(n * (1 - alpha))); 

    VaR = orderedLoss(idx);
    ES = mean(orderedLoss(1:idx));

end