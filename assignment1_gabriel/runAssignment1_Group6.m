% Assignment_1
%  Group 6, AA2025-2026
%
%  TBM (To Be Modified): Modify & Add where needed

% Seed for reproductability
rng(42);

%% Pricing parameters
S0=1;
K=1.1;
r=0.025;
TTM=1/3; 
sigma=0.212;
flag=1; % flag:  1 call, -1 put
d=0.02;
KO=1.4; % threshold

%% Quantity of interest
B=exp(-r*TTM); % Discount

%% Pricing 
F0=S0*exp(-d*TTM)/B;     % Forward in G&C Model
 

%% KI Option

%% KI Option Gamma

%% Antithetic Variables

%% QUESTION a)
% i)
rng(1)
M=1000;
pricingMode = 1; % 1 ClosedFormula, 2 CRR, 3 Monte Carlo
OptionPrice = EuropeanOptionPrice(F0,K,B,TTM,sigma,pricingMode,M,flag);
fprintf( "Option price with closed formula : %.4f\n" ,OptionPrice )
% ii)
pricingMode = 2;
M=20000; % M = steps for CRR
OptionPrice = EuropeanOptionPrice(F0,K,B,TTM,sigma,pricingMode,M,flag);
fprintf( "Option price with CRR : %.4f\n" ,OptionPrice )
% iii)
pricingMode = 3;
M = 100000; % M = simulations for MC
OptionPrice = EuropeanOptionPrice(F0,K,B,TTM,sigma,pricingMode,M,flag);
fprintf( "Option price with MC : %.4f\n" ,OptionPrice )

%% QUESTION b)

% We choose M = ...

%% QUESTION c)
% Errors Rescaling 

% plot Errors for CRR varing number of steps
% Note: both functions plot also the Errors of interest as side-effect 
[nCRR,errCRR] = PlotErrorCRR(F0,K,B,TTM,sigma);
% plot
figure
loglog(nCRR, errCRR, '-o', 'LineWidth', 1.25, 'MarkerSize', 6)
grid on
xlabel('M')
ylabel('err_{CRR}')
title('CRR : Error vs M (log-log)')

% plot Errors for MC varing number of simulations N 
[nMC,stdEstim]=PlotErrorMC(F0,K,B,TTM,sigma);
% plot
figure
loglog(nMC, stdEstim, '-o', 'LineWidth', 1.25, 'MarkerSize', 6)
grid on
xlabel('M')
ylabel('stdEstim')
title('MC : Error vs M (log-log)')

%% QUESTION d)
rng(2)
%% i) CRR
M=20000; % M = steps for CRR
OptionPrice = EuropeanOptionKOCRR(F0,K, KO,B,TTM,sigma,M);
fprintf( "Option price for European barrier with CRR : %.4f\n" ,OptionPrice )
%% ii) Monte Carlo
M = 10000; % M = simulations for MC
OptionPrice = EuropeanOptionKOMC(F0,K, KO,B,TTM,sigma,M);
fprintf( "Option price for European barrier with MC : %.4f\n" ,OptionPrice )
%% iii) closed formula
OptionPrice = EuropeanBarrierClosed(F0,K, KO,B,TTM,sigma);
fprintf( "Option price for European barrier with closed formula : %.4f\n" ,OptionPrice )

%% QUESTION e)
rng(3)
Sgrid = linspace(0.65,1.45,150);
Fgrid = Sgrid*exp(-d*TTM)/B;

VegaCRR = zeros(size(Fgrid));
VegaMC = zeros(size(Fgrid));
VegaExact = zeros(size(Fgrid));

for i = 1:length(Fgrid)
    rng(1000+i)
    F_0 = Fgrid(i);
    flagNum = 1;
    M=10000; % M = steps for CRR
    VegaCRR(i) = VegaKO(F_0,K,KO,B,TTM,sigma,M,flagNum);
    flagNum = 2;
    N=10000; % M = simulations for MC
    VegaMC(i) = VegaKO(F_0,K,KO,B,TTM,sigma,N,flagNum);
    flagNum = 3;
    VegaExact(i) = VegaKO(F_0,K,KO,B,TTM,sigma,N,flagNum);
end 


figure
plot(Sgrid,VegaCRR,'LineWidth',2)
hold on
plot(Sgrid,VegaMC,'LineWidth',2)
hold on
plot(Sgrid,VegaExact,'LineWidth',2)
hold off

xlabel('S_0')
ylabel('Vega')
title('Vega of Up-and-Out Call')
legend('CRR','MC','Exact')
grid on

%% QUESTION f)

%% i) pricing with Monte Carlo
rng(4)
M = 10000; % M = simulations for MC
OptionPrice = EuropeanOptionAmericanBarrierKOMC(F0,K, KO,B,TTM,sigma,d,M);
fprintf( "Option price for American barrier with MC : %.4f\n" ,OptionPrice )
% %% ii) delta
% rng(5)
% delta=AmericanBarrierDeltaKO(F0,K,KO,B,TTM,sigma,d,N);
% fprintf( "Delta for American barrier with MC : %.4f\n" ,delta)
%% ii) vega
rng(5)
vega=AmericanBarrierVegaKO(F0,K,KO,B,TTM,sigma,d,N);
fprintf( "Vega for American barrier with MC : %.4f\n" ,vega)

%% QUESTION g)
%% Antithetic Variables
% plot Errors for MC varing number of simulations N 
[nMC,stdEstim]=PlotErrorMC(F0,K,B,TTM,sigma);
[nMC_ant,stdEstim_ant]=PlotErrorMC_ant(F0,K,B,TTM,sigma);
% plot
figure
loglog(nMC, stdEstim, '-o', 'LineWidth', 1.25, 'MarkerSize', 6)
hold on
loglog(nMC_ant, stdEstim_ant, '-o', 'LineWidth', 1.25, 'MarkerSize', 6)
hold off
grid on
xlabel('M')
ylabel('stdEstim')
title('ErrorMC vs ErrorMC antithetic')
legend('MC','MC antithetic')

%% QUESTION h) Bermudian option
M=20000; % M = steps for CRR
OptionPrice = BermudanOptionCRR(F0,K,B,TTM,sigma,M,flag);
fprintf( "Option price for Bermudan barrier with CRR : %.4f\n" ,OptionPrice )



