function delta=AmericanBarrierDeltaKO(F0,K,KO,B,T,sigma,q,N)
%Delta of the European Barrier option 
%
%INPUT
% F0:    forward price
% B:     discount factor
% K:     strike
% T:     time-to-maturity
% sigma: volatility
% flagNum:  1 CRR, 2 MC, 3 Exact
% KO:    threshold

h = 1e-8;
dt = T/N;

% Simulate Forward GBM paths
Z = randn(N, N);

% sigma + h
logR_up = (-0.5*(sigma+h)^2)*dt + (sigma+h) *sqrt(dt).*Z;
logF_up = [log(F0)*ones(N,1), cumsum(logR_up,2) + log(F0)];
F_up = exp(logF_up);
% sigma - h 
logR_down = (-0.5*(sigma-h)^2)*dt + (sigma-h)*sqrt(dt).*Z;
logF_down = [log(F0)*ones(N,1), cumsum(logR_down,2) + log(F0)];
F_down = exp(logF_down);

r = -log(B)/T;
timeGrid = linspace(0,T,N+1);
adjFactor = exp(-(r-q)*(T - timeGrid));
% Spot paths up
S_up = F_up .* adjFactor;

% Spot paths down
S_down = F_down .* adjFactor;

% Check knock-out barrier up
hitBarrier = any(S_up > KO, 2);
FT_up = F_up(:, end);
FT_up(hitBarrier) = 0;
% Check knock-out barrier down
hitBarrier = any(S_down > KO, 2);
FT_down = F_down(:, end);
FT_down(hitBarrier) = 0;

% Payoff and discount
payoffs_up = max(FT_up - K, 0);
Price_up = B * mean(payoffs_up);
% Payoff and discount
payoffs_down = max(FT_down - K, 0);
Price_down = B * mean(payoffs_down);

vega = (Price_up - Price_down)/(2*h);

end