function V = price_cliquet(S0, sigma, r, N, Notional)
% price_cliquet computes the price of a cliquet option assuming no
% counterparty
% risk
% INPUTS:
%   S0       - spot price
%   sigma    - constant volatility 
%   r        - risk-free rate 
%   N_period - number of annual periods 
%   Notional - notional amount in EUR 
%
% OUTPUT:
%   V        - risk-free fair value of the Cliquet option in EUR

    dt = 1;

    d1 = (r + 0.5 * sigma^2) * dt / (sigma * sqrt(dt));
    d2 = d1 - sigma * sqrt(dt);

    c_unit = S0 * (normcdf(d1) - exp(-r * dt) * normcdf(d2));

    V = N * c_unit * Notional;
end