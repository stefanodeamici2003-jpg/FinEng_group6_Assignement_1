function [ES, VaR] = WHSMeasures(alpha, lambda, weights, portfolioValue, riskMeasureTimeIntervalInDays, returns) 
    
    % Extract ptf Historical Losses 
    port_returns = returns * weights;
    % Adaptation to correct timewindow
    port_returns = port_returns * riskMeasureTimeIntervalInDays;
    losses = -port_returns * portfolioValue;
    n = length(losses);
    
    % Calculation of constants vector
    % Our vector of returns goes from the oldest to the most recent return
    C = ((1 - lambda) / (1 - lambda^n)) * (lambda .^ ((n-1:-1:0)'));
    
    % Sort from highest to lowest loss, in the same way also the weights
    [orderedLoss, I] = sort(losses, 'descend');
    C_sorted = C(I); % CORRETTO IL TYPO QUI
    
    % cumulative sum of the constants
    sumOfConstants = cumsum(C_sorted);
    
    % Taking the most restrictive index
    idx = find(sumOfConstants <= (1 - alpha), 1, 'last');
    
    % In order to avoid any crash
    if isempty(idx)
        idx = 1;
    end
    
    VaR = orderedLoss(idx);
    
    ES = sum(orderedLoss(1:idx) .* C_sorted(1:idx)) / sumOfConstants(idx);

end