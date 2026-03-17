function [tau_vect, P_emp, P_fit, lambda1_emp, lambda2_emp, CI_lambda1, CI_lambda2] = survival_probability(lambda1,lambda2,theta,M)

% INPUTS:
% lambda1, lambda2 : intensity parameters
% theta            : switching time
% M                : number of simulations

%simulate default times tau
rng(3)
u = rand(M,1);
v = -log(u);

tau_vect = zeros(M,1);
threshold = lambda1 * theta;

tau_vect(v <= threshold) = v(v <= threshold) / lambda1;
tau_vect(v > threshold)  = theta + (v(v > threshold) - threshold) / lambda2;

%empirical survival probability
tGrid = linspace(0,30,500);
P_emp = arrayfun(@(t) mean(tau_vect > t), tGrid);

%Fit lambda1 and lambda2 from log survival

%(t <= theta)
mask1 = tGrid > 0 & tGrid <= theta;
x1 = tGrid(mask1)';
y1 = log(P_emp(mask1))';

mdl1 = fitlm(x1,y1);

lambda1_emp = -mdl1.Coefficients.Estimate(2);
se1 = mdl1.Coefficients.SE(2);

CI_lambda1 = lambda1_emp + [-1.96 1.96]*se1;

%(t > theta)
mask2 = tGrid > theta;
x2 = tGrid(mask2)';
y2 = log(P_emp(mask2))';

mdl2 = fitlm(x2,y2);

lambda2_emp = -mdl2.Coefficients.Estimate(2);
se2 = mdl2.Coefficients.SE(2);

CI_lambda2 = lambda2_emp + [-1.96 1.96]*se2;

%fitted survival probability
P_fit = zeros(size(tGrid));
P_fit(tGrid<=theta) = exp(-lambda1_emp * tGrid(tGrid<=theta));
P_fit(tGrid>theta) = exp(-lambda1_emp*theta ...
                      - lambda2_emp*(tGrid(tGrid>theta)-theta));

%Confidence interval for empirical survival
z = 1.96;
P_up  = P_emp + z*sqrt(P_emp.*(1-P_emp)/M);
P_low = P_emp - z*sqrt(P_emp.*(1-P_emp)/M);


%plot (loglinear scale)
figure

semilogy(tGrid,P_emp,'r','LineWidth',2)
hold on
semilogy(tGrid,P_fit,'b--','LineWidth',2)
semilogy(tGrid,P_up,'k:')
semilogy(tGrid,P_low,'k:')

xlabel('t (years)')
ylabel('Survival Probability (log scale)')

legend('Empirical','Fitted','CI 95%')

title('Empirical vs Fitted Survival Probability')

end