function optionPrice = BermudanOptionCRR(F0,K,B,T,sigma,N,flag)
%Bermudan option price with a CRR tree approach
%
%INPUT
% F0:    forward price
% B:     discount factor
% K:     strike
% T:     time-to-maturity
% sigma: volatility
% N:     number of time steps (knots for CRR tree)
% flag:  1 call, -1 put

dt = T/N;

u = exp(sigma * sqrt(dt));
d = exp(-sigma * sqrt(dt));
p = (1 - d) / (u - d);

% Monthly exercise steps
exerciseSteps = round((1:floor(12*T)) * (N/(12*T)));

% Terminal forward prices
FT = zeros(N+1,1);
for i = 0:N
    FT(i+1) = F0 * d^i * u^(N-i);
end

% Terminal payoff
if flag == 1
    V = max(FT - K,0);
else
    V = max(K - FT,0);
end

% Backward induction
for j = N:-1:1
    
    % Compute forward prices at time j-1
    F = zeros(j,1);
    for i = 0:j-1
        F(i+1) = F0 * d^i * u^(j-1-i);
    end
    
    % Continuation value
    V = p * V(1:j) + (1-p) * V(2:j+1);
    
    % Bermudan early exercise
    if ismember(j-1, exerciseSteps)
        if flag == 1
            exerciseValue = max(F - K,0);
        else
            exerciseValue = max(K - F,0);
        end
        V = max(V, exerciseValue);
    end
end

optionPrice = B * V;

end