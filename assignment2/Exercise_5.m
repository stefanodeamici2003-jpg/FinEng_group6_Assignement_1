% EXERCISE 5
% INPUTS:
%   theta: point in time where the intensity changes
%   lambda1, lambda2: values of the intensity parameter
lambda1 = 0.0004;
lambda2 = 0.0010;
theta   = 5;
%% Question a)
% Simulation of a singular default time through the non constant Intensity
% based model
u = rand;
v = -log(u);

% Piecewise lambda => we can integrate easily and then deduce tau
threshold = lambda1 * theta;   % = 0.002
if v <= threshold
    tau = v/lambda1;
else
    tau = theta + (v-threshold)/lambda2;
end
tau

%% Question b)
% Simulates M=10^5 scenarios through the non constant Intensity
% based model and returns a validation of the parameters using the
% loglinear plot of the empirical survival probability probability and a
% plot of the default time density function

M = 10^5;
tau_vect = zeros(M,1);
u_vect = rand(M,1);
v_vect = -log(u_vect);
threshold = lambda1 * theta; 

% Calculate tau for each simulation
tau_vect(v_vect <= threshold) = v_vect(v_vect <= threshold) / lambda1;
tau_vect(v_vect > threshold)  = theta + (v_vect(v_vect > threshold) - threshold) / lambda2;

tGrid = linspace(0, 30, 500);

% 1) Empirical estimator 

% Empirical survival probability
P_emp = arrayfun(@(t) mean(tau_vect > t), tGrid);

% True survival
P_true = exp(-(lambda1*min(tGrid,theta) + lambda2*max(tGrid-theta,0)));

% CI sur P_emp : binomial => std = sqrt(p*(1-p)/M)
z     = 1.96; % CI 95% 
P_up  = P_emp + z * sqrt(P_emp.*(1-P_emp)/M);
P_low = P_emp - z * sqrt(P_emp.*(1-P_emp)/M);

% SHOWS:
%   the loglinear graph of the theorical survival probability over time
%   on the same plot: the empirical probability and its 95% confidence interval
figure;
first_line = polyfit(tGrid(tGrid<=theta), log(P_emp(tGrid<=theta)),1);
second_line = polyfit(tGrid(tGrid>theta), log(P_emp(tGrid>theta)),1);
semilogy(tGrid, P_true, 'b-',  'LineWidth', 2); hold on
semilogy(tGrid, P_emp,  'r--', 'LineWidth', 2);
semilogy(tGrid, P_up,   'k:',  'LineWidth', 1);
semilogy(tGrid, P_low,  'k:',  'LineWidth', 1);
xlabel('t (years)'); ylabel('P(t) — log scale')
legend('True','Empirical','CI 95%')
title('Survival Probability — empirical estimator')

lambda1_emp = -first_line(1)
lambda2_emp = -second_line(1)

%% PDF Fit of tau over 30 years
dt = 0.5;
tSteps = 0:dt:30; % Setting the time horizon to 30 years

% Empirical PDF and time step midpoints computation
count = arrayfun(@(i) sum(tSteps(i) < tau_vect & tau_vect <= tSteps(i+1)), 1:length(tSteps)-1);
pdf_emp = count / (M * dt);
tMid_steps = (tSteps(1:end-1) + tSteps(2:end)) / 2;

% Theoretical PDF
lambda_grid = lambda1 * (tGrid <= theta) + lambda2 * (tGrid > theta);
pdf_true = lambda_grid .* exp(-(lambda1*min(tGrid,theta) + lambda2*max(tGrid-theta,0)));

% SHOWS:
%   The Theoretical PDF VS the one we calculated through simulation
plot(tMid_steps, pdf_emp, 'r-', 'LineWidth', 1.5);
hold on;
plot(tGrid, pdf_true, 'b--', 'LineWidth', 2);
xlabel('Time t (years)');
ylabel('Density f(t)');
legend('Empirical PDF', 'Theoretical PDF');
title('Density of tau: Empirical vs Theoretical (30 Years)');