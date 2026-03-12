% exercise 5 : credit_simulation

lambda1 = 0.0004;
lambda2 = 0.0010;
theta   = 5;

%% Question a)
u   = rand;
v   = -log(u);

% piecewise lambda => we can integrate easily and then deduce tau
threshold = lambda1 * theta;   % = 0.002
if v <= threshold
    tau = v/lambda1;
else
    tau = theta + (v-threshold)/lambda2;
end
tau

%% Question b)

M = 10^5; % number of simulation
tau_vect = zeros(M,1);
u_vect = rand(M,1);
v_vect = -log(u_vect);
threshold = lambda1 * theta; 

% Calculate tau for each simulation
tau_vect(v_vect <= threshold) = v_vect(v_vect <= threshold) / lambda1;
tau_vect(v_vect > threshold)  = theta + (v_vect(v_vect > threshold) - threshold) / lambda2;

tGrid = linspace(0, 20, 500);

% 1) Empirical estimator 

% Empirical survival probability
P_emp = arrayfun(@(t) mean(tau_vect > t), tGrid);

% True survival
P_true = exp(-(lambda1*min(tGrid,theta) + lambda2*max(tGrid-theta,0)));

% CI sur P_emp : binomial => std = sqrt(p*(1-p)/M)
z     = 1.96; % CI 95% 
P_up  = P_emp + z * sqrt(P_emp.*(1-P_emp)/M);
P_low = P_emp - z * sqrt(P_emp.*(1-P_emp)/M);

figure;
semilogy(tGrid, P_true, 'b-',  'LineWidth', 2); hold on
semilogy(tGrid, P_emp,  'r--', 'LineWidth', 2);
semilogy(tGrid, P_up,   'k:',  'LineWidth', 1);
semilogy(tGrid, P_low,  'k:',  'LineWidth', 1);
xlabel('t (years)'); ylabel('P(t) — log scale')
legend('True','Empirical','CI 95%')
title('Survival Probability — empirical estimator')

