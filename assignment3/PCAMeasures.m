function [ES, VaR] = PCAMeasures(alpha, k, weights, portfolioValue, riskMeasureTimeIntervalInDays, returns)
% PCAMEASURES Computes VaR and ES using a Gaussian parametric PCA approach.
%
%   INPUTS:
%       alpha                         : Confidence level (e.g., 0.99 for 99%)
%       k                             : Number of principal components to keep
%       weights                       : Column vector (N x 1) of portfolio weights
%       portfolioValue                : Total notional value of the portfolio
%       riskMeasureTimeIntervalInDays : Time horizon for the risk measure (e.g., 10)
%       returns                       : Matrix (T x N) of historical asset returns
%
%   OUTPUTS:
%       ES  : Expected Shortfall of the portfolio over the specified horizon
%       VaR : Value-at-Risk of the portfolio over the specified horizon

    sigma = cov(returns);
    
    % Perform the eigendecomposition of the covariance matrix
    [V, D] = eig(sigma);
    
    % Standard normal quantile for the given alpha
    z = norminv(alpha);
    
    % Sort eigenvalues and eigenvectors in descending order
    % MATLAB's eig() sorts in ascending order by default
    eigVals = diag(D);
    [sortedEigVals, ind] = sort(eigVals, 'descend');
    V_sorted = V(:, ind);                 

    weightsCap = V_sorted' * weights; 
    
    % Calculate the approximate variance using only the first 'k' components
    var_reduced = sum( (weightsCap(1:k).^2) .* sortedEigVals(1:k) );
    
    stdDev = sqrt(var_reduced);
    d = riskMeasureTimeIntervalInDays;
    VaR = stdDev * z * sqrt(d) * portfolioValue;
    ES = (normpdf(z) / (1 - alpha)) * stdDev * sqrt(d) * portfolioValue;

end