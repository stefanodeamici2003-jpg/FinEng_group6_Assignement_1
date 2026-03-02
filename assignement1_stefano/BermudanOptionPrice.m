function Bermudan = BermudanOptionPrice(F0, K, T, sigma, B, q, M)
%test prova
% Parameters
r = -log(B)/T;          

dt = T / M;
steps = [ceil(M/4), ceil(M/2), ceil(3*M/4)];

% Probabilities
u = exp(sigma * sqrt(dt));
d = 1 / u;
p = (1 - d) / (u - d); 

% Calculation of different scenarios
j = 0:M; 
F_T = F0 * (u.^j) .* (d.^(M - j));

% Final payoff
V = max(F_T - K, 0);

% 4. Backward Induction
for i = (M - 1):-1:0
    
    % Continuation Value
    V = p * V(2:end) + (1 - p) * V(1:end-1);
    
    % Check if we are at the possible exercise time
    if ismember(i, steps)
        t_i = i * dt; % Tempo corrente in anni
        
        % Find the value of F up to i-th time step
        j_current = 0:i;
        F_t = F0 * (u.^j_current) .* (d.^(i - j_current));
        
        % From the forward find the value of the actual S_ti
        S_t = F_t * exp(-(r - q) * (T - t_i));
        
        % Payoff in T if we exercise the option
        B_ti_T = exp(-r * (T - t_i));
        Payoff = max(S_t - K, 0) / B_ti_T;
        
        % Exercise when it's convenient
        V = max(V, Payoff);

    end
end

% Find the value at present time
Bermudan = B * V(1);
