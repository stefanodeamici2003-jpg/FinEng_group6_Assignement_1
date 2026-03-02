% Assignment_1
%  Group X, AA2021-2022
%
%  TBM (To Be Modified): Modify & Add where needed

%% Pricing parameters
% All parameters should be put here, in the script and passed to the
% fuctions of interest (generally in a struct)
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

%TBM: Modify with a cicle
pricingMode = 3; % 1 ClosedFormula, 2 CRR, 3 Monte Carlo
M=10000; % M = simulations for MC, steps for CRR;
OptionPrice = EuropeanOptionPrice(F0,K,B,TTM,sigma,pricingMode,M,flag)

%% Errors Rescaling B-C

% plot Errors for CRR varing number of steps
% Note: both functions plot also the Errors of interest as side-effect 
[nCRR,errCRR]=PlotErrorCRR(F0,K,B,TTM,sigma);

% plot Errors for MC varing number of simulations N 
[nMC,stdEstim]=PlotErrorMC(F0,K,B,TTM,sigma); 

%% KO Option D
%non funziona molto bene sta cosa qui
KO=1.4;
Call_KO_True = EuropeanKOCall_ClosedFormula(F0, K, KO, B, TTM, sigma)
M_CRR = 128;
Call_KO_CRR= EuropeanOptionKOCRR(F0, K, KO, B, TTM, sigma, M)
M_MC = 2^20;
Call_KO_MC=EuropeanOptionKOMC(F0,K,KO,B,TTM,sigma,M)
%% KO Option vega E
S0_vector = 0.65:0.01:1.45; % Range of underlying prices 
vega_exact = zeros(size(S0_vector));
vega_num_crr = zeros(size(S0_vector));
vega_num_mc = zeros(size(S0_vector));
F0_vector = S0_vector .* exp(-d*TTM) ./ B;
M_CRR = 2^10; %we increase the 
for i = 1:length(S0_vector)
    % Update Forward price for each S0 in the range
    
    vega_exact(i) = VegaKO(F0_vector(i), K, KO, B, TTM, sigma, M, 3);
    vega_num_crr(i) = VegaKO(F0_vector(i), K, KO, B, TTM, sigma, M_CRR, 1);
    vega_num_mc(i) = VegaKO(F0_vector(i), K, KO, B, TTM, sigma, M_MC, 2);
end

% Plotting results
figure;
plot(S0_vector, vega_exact, 'b-'); hold on;
plot(S0_vector, vega_num_crr, 'r-'); hold on;
plot(S0_vector, vega_num_mc, 'g-');
xline(KO, 'k:', 'Barrier (1.4)'); % Barrier level 
xlabel('Underlying Price S0 (Euro)');
ylabel('Vega');
title('Vega of Up-and-Out European Call');
legend('Exact (Analytical)', 'Numerical (CRR)', 'Numerical (MC)');
grid on;

%% American Barrier F
figure();
S0_vector = 0.65:0.001:1.45; % Range of underlying prices 
F0_vector = S0_vector .* exp(-d*TTM) ./ B;
%let's use the matlab native function for this problem
Call_American_KO_CRR = EuropeanOptionAmericanBarrier(F0, K, KO, B, TTM, sigma, d);
% Comparation with Euro Barrier

% Analyze Delta
Eur_delta= zeros(length(F0_vector),1);
American_delta= zeros(length(F0_vector),1);

for i=1:length(F0_vector)
    Eur_delta(i) = DeltaKO(F0_vector(i), K, KO, B, TTM, sigma, d);
    American_delta(i) = DeltaAmericanKO(F0_vector(i), K, KO, B, TTM, sigma, d);
end

title('Delta Eur VS American Barrier');
plot(S0_vector, Eur_delta, "Marker","+");
hold on
plot(S0_vector, American_delta, "Marker","+");
title('Delta Eur VS American Barrier');
legend('Delta Eur', 'Delta American');

%%
% Analyze Vega
Eur_vega= zeros(length(F0_vector),1);
American_vega= zeros(length(F0_vector),1);
figure();
for i=1:length(F0_vector)
    Eur_vega(i) = VegaKO(F0_vector(i), K, KO, B, TTM, sigma, M, 3);
    American_vega(i) = VegaAmericanKO(F0_vector(i), K, KO, B, TTM, sigma, d);
end

title('Vega Eur VS American Barrier');
plot(S0_vector, Eur_vega);
hold on
plot(S0_vector, American_vega);
title('Vega Eur VS American Barrier');
legend('Vega Eur', 'Vega American');

%% Antithetic Variables
[M_vec, stdEstim] = PlotErrorMC(F0, K, B, TTM, sigma);
hold on 
[M_vec, stdEstim] = PlotErrorMC_half(F0, K, B, TTM, sigma);


%% Bermudan H
d=0.15;
Bermudan = BermudanOptionPrice(F0, K, TTM, sigma, B, 0.15, M);
%% Bermudan VS European I
q_vector = [0 : 0.001 : 0.05];

for i=1:length(q_vector)
    Bermudan_vector(i) = BermudanOptionPrice(F0, K, TTM, sigma, B, q_vector(i), M);
    B_european=B*exp(q_vector(i)*TTM);
    European_vector(i) =  EuropeanOptionClosed(F0,K,B_european,TTM,sigma,1);
end

plot(q_vector, Bermudan_vector);
hold on
plot(q_vector, European_vector);



