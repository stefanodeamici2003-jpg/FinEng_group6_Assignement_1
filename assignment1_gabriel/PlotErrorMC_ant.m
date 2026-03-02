function [M,stdEstim]=PlotErrorMC_ant(F0,K,B,TTM,sigma)
%Plot of the error with a MC approach
%
%INPUT
% F0:    forward price
% B:     discount factor
% K:     strike
% T:     time-to-maturity
% sigma: volatility

flag = 1;
M = zeros(1, 20); % Initialize the M array
stdEstim = zeros(1, 20); % Initialize the stdEstim array

for m = 1:20
    M(m) = 2^(m-1); % M/2
    % Generate random paths for the underlying asset price
    Z = randn(M(m),1);
    F = zeros(M(m), 1);
    F_ant = zeros(M(m), 1);
    for i = 1:M(m)
        F(i) = F0 * exp((- 0.5 * sigma^2) * TTM + sigma * sqrt(TTM) * Z(i));
        F_ant(i) = F0 * exp((- 0.5 * sigma^2) * TTM + sigma * sqrt(TTM) * (-Z(i)));
    end

    % Discounted expected value and standard error
    payoff1 = max(F - K, 0);
    payoff2 = max(F_ant - K, 0);
    disc_payoff_antithetic = B * 0.5 * (payoff1 + payoff2);   % average of pairs
    % Standard deviation
    s = std(disc_payoff_antithetic);
    % error
    stdEstim(m) = s / sqrt(M(m));

end

end