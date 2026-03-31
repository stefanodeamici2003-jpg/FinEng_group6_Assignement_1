function [ES, VaR] = AnalyticNormalMeasures(alpha, weights, portfolioValue, riskMeasureTimeIntervalInDays, returns)
% AnalyticNormalMeasures computes the Value at Risk (VaR) and Expected Shortfall (ES)
% for a linear portfolio using the Gaussian parametric (Variance-Covariance) approach.
%
% INPUTS:
%   alpha                         : Confidence level for the risk measures.
%   weights                       : Nx1 column vector representing the weights of the assets in the portfolio.
%   portfolioValue                : Total notional value of the portfolio.
%   riskMeasureTimeIntervalInDays : Time horizon for the risk measure in days (e.g., 1 for daily VaR).
%   returns                       : TxN matrix of historical log-returns for the N assets over T days.
%
% OUTPUTS:
%   ES                            : Expected Shortfall of the portfolio.
%   VaR                           : Value at Risk of the portfolio.

    mu_assets = mean(returns) * riskMeasureTimeIntervalInDays;
    Covariance = cov(returns) * riskMeasureTimeIntervalInDays;
    
    % mu_assets is a 1xN row vector and weights is an Nx1 column vector; their product is a scalar.
    mu_port = mu_assets * weights; 
    sigma_port = sqrt(weights' * Covariance * weights);
    
    Z = norminv(alpha);
    
    % VaR and ES calculation in monetary terms
    VaR = portfolioValue * (-mu_port + sigma_port * Z);
    % Making use of the ES formula for Normal Loss distributions
    ES = portfolioValue * (-mu_port + sigma_port * (normpdf(Z) / (1 - alpha)));

end