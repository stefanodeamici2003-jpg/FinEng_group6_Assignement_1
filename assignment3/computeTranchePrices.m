function [price_LHP, price_exact, price_kl] = computeTranchePrices(Kd, Ku, LGD, c, rho, pY, phiY, dy, y, I_exact, I_kl, KL_div)
    % Define the tranche loss fraction function
    l_tr = @(z) min(max(z*LGD - Kd, 0), Ku - Kd) / (Ku - Kd);

    % --- LHP Solution ---
    EL_LHP = (1/(Ku-Kd)) * quadgk(@(x) normcdf((c - sqrt(1-rho)*norminv(x/LGD)) / sqrt(rho)), Kd, Ku, 'RelTol', 1e-8);
    price_LHP = (1 - EL_LHP) * 100;

    % --- Exact Solution ---
    price_exact = zeros(size(I_exact));
    for idx = 1:length(I_exact)
        I  = I_exact(idx);
        EL = 0;
        for m = 0:I
            ltr_m = l_tr(m/I);
            if ltr_m == 0, continue; end
            % Integrate over Y with rectangular rule
            prob_m = sum(binopdf(m, I, pY) .* phiY) * dy;
            EL     = EL + ltr_m * prob_m;
        end
        price_exact(idx) = (1 - EL) * 100;
    end

    % --- KL Approximation ---
    price_kl = zeros(size(I_kl));
    for idx = 1:length(I_kl)
        I = I_kl(idx);
        % Inner integral over z for each y_j (rectangular rule over y)
        inner = zeros(size(y));
        for j = 1:length(y)
            p_j = pY(j);
            inner(j) = quadgk(@(z) l_tr(z) .* sqrt(I./(2*pi*z.*(1-z))) ...
                               .* exp(-I .* KL_div(z, p_j)), ...
                               0, 1, 'RelTol', 1e-6, 'AbsTol', 1e-10);
        end
        % Outer sum over y (rectangular rule)
        EL_kl         = sum(inner .* phiY) * dy;
        price_kl(idx) = (1 - EL_kl) * 100;
    end
end