function plotTranchePrice(I_kl, price_kl, I_exact, price_exact, price_LHP, trancheType)
%--------------------------------------------------------------------------
% plotTranchePrice
%
% Plots the tranche price as a function of the number of obligors I
% (logarithmic scale), comparing KL approximation, exact solution and LHP limit.
%
% INPUT:
%   I_kl        - vector of obligor numbers for KL approximation
%   price_kl    - vector of tranche prices (KL approximation)
%   I_exact     - vector of obligor numbers for exact solution
%   price_exact - vector of tranche prices (exact solution)
%   price_LHP   - scalar, tranche price in the LHP limit
%   trancheType - string specifying the tranche type:
%                 'mezzanine' or 'equity'
%
% OUTPUT:
%   none (the function generates a plot)
%--------------------------------------------------------------------------

figure;
semilogx(I_kl,    price_kl,    'b-',  'LineWidth', 2); hold on;
semilogx(I_exact, price_exact, 'ro',  'MarkerSize', 6, 'LineWidth', 1.5);
yline(price_LHP,               'k--', 'LineWidth', 2);
xlabel('Number of obligors I (log scale)'); ylabel('Tranche Price (% of face value)');
if strcmp(trancheType, 'mezzanine')
    title('Mezzanine Tranche Price vs. I — Vasicek Model');
    legend('KL Approximation', 'Exact Solution', 'LHP Limit', 'Location', 'southeast');
    
elseif strcmp(trancheType, 'equity')
    title('Equity Tranche Price vs. I — Vasicek Model');
    legend('KL Approximation', 'Exact Solution', 'LHP Limit');
end

grid on;
xlim([10, 2e4]);
grid on;
xlim([10, 2e4]);
end