% Assignment_1
%  Group 6, AA2025-2026
%
%  

%% Pricing parameters
S0=1;
K=1.1;
r=0.025;
TTM=1/3; 
sigma=0.212;
flag=1; % flag:  1 call, -1 put
d=0.02;

%% Quantity of interest
B=exp(-r*TTM); % Discount

%% Pricing A
F0=S0*exp(-d*TTM)/B;     

pricingMode = 3; % 1 ClosedFormula, 2 CRR, 3 Monte Carlo
M=10000; % M = simulations for MC, steps for CRR;
OptionPrice = EuropeanOptionPrice(F0,K,B,TTM,sigma,pricingMode,M,flag)

%% Errors Rescaling B-C

% plot Errors for CRR varing number of steps 
[nCRR,errCRR]=PlotErrorCRR(F0,K,B,TTM,sigma);

% plot Errors for MC varing number of simulations N 
[nMC,stdEstim]=PlotErrorMC(F0,K,B,TTM,sigma); 

%% KO Option D
% Pricing European Call with european barrier
KO=1.4;
Call_KO_True = EuropeanKOCall_ClosedFormula(F0, K, KO, B, TTM, sigma)
M_CRR = 2^7;
Call_KO_CRR= EuropeanOptionKOCRR(F0, K, KO, B, TTM, sigma, M_CRR)
M_MC = 2^20;
Call_KO_MC=EuropeanOptionKOMC(F0,K,KO,B,TTM,sigma,M_MC)

%% KO Option vega E
S0_vector = 0.65:0.01:1.45; % Range of underlying prices 
vega_exact = zeros(size(S0_vector));
vega_num_crr = zeros(size(S0_vector));
vega_num_mc = zeros(size(S0_vector));
F0_vector = S0_vector .* exp(-d*TTM) ./ B;
M_CRR = 2^10; %we increase the number to get more precision
for i = 1:length(S0_vector)
    % Update Forward price for each S0 in the range
    
    vega_exact(i) = VegaKO(F0_vector(i), K, KO, B, TTM, sigma, M, 3);
    vega_num_crr(i) = VegaKO(F0_vector(i), K, KO, B, TTM, sigma, M_CRR, 1);
    vega_num_mc(i) = VegaKO(F0_vector(i), K, KO, B, TTM, sigma, M_MC, 2);
end

% Plotting results
figure;
plot(S0_vector, vega_exact, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b', 'MarkerSize', 2); hold on;
plot(S0_vector, vega_num_crr, 'r', 'LineWidth', 1.5); hold on;
plot(S0_vector, vega_num_mc, 'g-', 'LineWidth', 1.5);

xline(KO, '--k', 'Barrier (1.4)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');   % Barrier level 
xlabel('Underlying Price S0 (Euro)');
ylabel('Vega (Euro)');
title('Vega of Up-and-Out European Call');
legend('Exact (Analytical)', 'Numerical (CRR)', 'Numerical (MC)');
grid on;

%% American Barrier F
S0_vector = 0.65:0.001:1.45; % Range of underlying prices 
F0_vector = S0_vector .* exp(-d*TTM) ./ B;
%let's use the matlab native function for this problem
Call_American_KO = EuropeanOptionAmericanBarrier(F0, K, KO, B, TTM, sigma, d);
% Comparation with Euro Barrier

% Analyze Delta
Eur_delta= zeros(length(F0_vector),1);
American_delta= zeros(length(F0_vector),1);

for i=1:length(F0_vector)
    Eur_delta(i) = DeltaKO(F0_vector(i), K, KO, B, TTM, sigma, d);
    American_delta(i) = DeltaAmericanKO(F0_vector(i), K, KO, B, TTM, sigma, d);
end

figure;
plot(S0_vector, Eur_delta, '-', 'LineWidth', 1.5); 
hold on
plot(S0_vector, American_delta, '-', 'LineWidth', 1.5);

% Vizualization
title('Delta European VS American Barrier');
xlabel('Underlying Price S0 (Euro)');
ylabel('Delta');
legend('Delta European', 'Delta American', 'Location', 'best');
grid on;

% Analyze Vega
Eur_vega= zeros(length(F0_vector),1);
American_vega= zeros(length(F0_vector),1);
figure();
for i=1:length(F0_vector)
    Eur_vega(i) = VegaKO(F0_vector(i), K, KO, B, TTM, sigma, M, 3);
    American_vega(i) = VegaAmericanKO(F0_vector(i), K, KO, B, TTM, sigma, d);
end

plot(S0_vector, Eur_vega, '-', 'LineWidth', 1.5);
hold on
plot(S0_vector, American_vega, '-', 'LineWidth', 1.5);
title('Vega European VS American Barrier');
xlabel('Underlying Price S0 (Euro)');
ylabel('Vega');
legend('Vega European', 'Vega American');
grid on;

%% Antithetic Variables G
[M_vec, stdEstim] = PlotErrorMC(F0, K, B, TTM, sigma);
hold on 
[M_vec_half, stdEstim_half] = PlotErrorMC_half(F0, K, B, TTM, sigma);


%% Bermudan H
% Evaluate Bermudan price
Bermudan = BermudanOptionPrice(F0, K, TTM, B, sigma, d, M)

%% Bermudan VS European I
figure();
q_vector = linspace(0, 0.05, 100);

% Initialization of price vectors
Bermudan_vector = zeros(1, length(q_vector));
European_vector = zeros(1, length(q_vector));

% evolution of the dividend yield
for i=1:length(q_vector)
    % F0
    F0_current = S0 * exp(-q_vector(i) * TTM) / B;
    
    Bermudan_vector(i) = BermudanOptionPrice(F0_current, K, TTM, B, sigma, q_vector(i), M);
    European_vector(i) = EuropeanOptionClosed(F0_current, K, B, TTM, sigma, 1);
end
plot(q_vector, Bermudan_vector);
hold on
plot(q_vector, European_vector);
title('Bermudan VS European');
xlabel('Dividends');
ylabel('Option Price');
legend('Bermudan', 'European');
grid on;




