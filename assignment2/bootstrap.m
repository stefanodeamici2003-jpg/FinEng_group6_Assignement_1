function [dates, discounts, zeroRates] = bootstrap(datesSet, ratesSet)
% BOOTSTRAP  Bootstraps the Euribor 3M single-curve discount factor curve.
%
%   Uses three instrument types in sequence:
%     1. Deposits    – short end,  Act/360, simply compounded
%     2. STIR Futures– mid range,  Act/360 forward rates (log-linear interp)
%     3. Swaps vs 3M – long end,   fixed leg annual 30/360 EU
%
%   Single-curve assumption: floating leg discounting = projection curve.
%
% INPUTS:
%   datesSet  – struct with fields:
%                 .settlement  scalar datenum
%                 .depos       Nd x 1 datenum vector (end dates)
%                 .futures     Nf x 2 datenum matrix [startDate, endDate]
%                 .swaps       Ns x 1 datenum vector (maturity dates)
%   ratesSet  – struct with fields (bid/ask columns):
%                 .depos       Nd x 2  (as decimals, e.g. 0.04 = 4%)
%                 .futures     Nf x 2  (forward rates, already 100-price)
%                 .swaps       Ns x 2
%
% OUTPUTS:
%   dates      – column vector of datenums (settlement first, then end dates)
%   discounts  – column vector of discount factors B(t0, T)
%   zeroRates  – column vector of zero rates (Act/365, continuously compounded)
%
% Function signature (from assignment):
%   [dates, discounts, zeroRates] = bootstrap(datesSet, ratesSet)

%% -----------------------------------------------------------------------
%  0.  Setup
%  -----------------------------------------------------------------------
settlementDate = datesSet.settlement;

% Mid-market rates (average of bid and ask)
midDepos   = mean(ratesSet.depos,   2);   % Nd x 1
midFutures = mean(ratesSet.futures, 2);   % Nf x 1
midSwaps   = mean(ratesSet.swaps,   2);   % Ns x 1

% Initialise curve at settlement:  B(t0, t0) = 1
dates     = settlementDate;
discounts = 1.0;

%% -----------------------------------------------------------------------
%  1.  DEPOSITS  –  Act/360, simply compounded
%       B(t0, T) = 1 / (1 + r * delta)
%  -----------------------------------------------------------------------
nDepos = length(datesSet.depos);

firstFutSettle = datesSet.futures(1, 1);
for i = 1:nDepos
    if datesSet.depos(i) >= firstFutSettle
        break   % stop al primo deposito che supera il settlement del futures
    end
    T     = datesSet.depos(i);
    delta = (T - settlementDate) / 360;
    B     = 1.0 / (1.0 + midDepos(i) * delta);
    [dates, discounts] = insertPoint(dates, discounts, T, B);
end

%% -----------------------------------------------------------------------
%  2.  STIR FUTURES  –  Act/360 forward rates
%       B(t0, T2) = B(t0, T1) / (1 + r_fwd * delta)
%       B(t0, T1) obtained by log-linear interpolation on current curve
%  -----------------------------------------------------------------------
nFut = min(7, size(datesSet.futures, 1));
for i = 1:nFut
    T1    = datesSet.futures(i, 1);              % period start (IMM date)
    T2    = datesSet.futures(i, 2);              % period end
    delta = (T2 - T1) / 360;                     % Act/360
    
    B_T1 = linearRateInterp(dates, discounts, settlementDate, T1); %
    B_T2 = B_T1 / (1.0 + midFutures(i) * delta);
    [dates, discounts] = insertPoint(dates, discounts, T2, B_T2);
end

% Ensure curve is sorted before swap bootstrap
[dates, sortIdx] = sort(dates);
discounts = discounts(sortIdx);

%% -----------------------------------------------------------------------
%  3.  SWAPS vs Euribor 3M  –  single-curve bootstrap
%       Fixed leg: annual payments, 30/360 European (basis 6)
%       Bootstrap formula (n-th maturity):
%         B(t0, T_n) = (1 - K * BPV_{1..n-1}) / (1 + K * delta_n)
%       where  BPV = sum_{j=1}^{n-1}  delta_j * B(t0, T_j)
%  -----------------------------------------------------------------------
nSwaps = length(datesSet.swaps);
lastFutEnd = datesSet.futures(nFut, 2);  % end date del 7° futures

for i = 1:nSwaps
    if datesSet.swaps(i) <= lastFutEnd
        continue   % zona già coperta dai futures
    end
    T_n = datesSet.swaps(i);
    K   = midSwaps(i);

    % Number of annual coupon periods
    nYears = year(T_n) - year(settlementDate);
    if nYears < 1 % maybe redundant
        continue
    end

    % --- Fixed-leg payment dates (annual, from settlement) ---------------
    fixedDates = zeros(nYears, 1);
    for j = 1:nYears
        fixedDates(j) = addtodate(settlementDate, j, 'year');
    end
    fixedDates(end) = T_n;   % last payment coincides with swap maturity

    % --- Accumulate BPV for periods 1 .. n-1 -----------------------------
    BPV      = 0.0;
    prevDate = settlementDate;
    for j = 1:nYears - 1
        delta_j = yearfrac(prevDate, fixedDates(j), 6);   % 30/360 EU
        B_j     = linearRateInterp(dates, discounts, settlementDate, prevDate);
        BPV     = BPV + delta_j * B_j;
        prevDate = fixedDates(j);
    end
    % --- Bootstrap last discount factor ----------------------------------
    delta_n = yearfrac(prevDate, T_n, 6);                 % 30/360 EU
    B_Tn    = (1.0 - K * BPV) / (1.0 + K * delta_n);

    [dates, discounts] = insertPoint(dates, discounts, T_n, B_Tn);
end

%% -----------------------------------------------------------------------
%  4. From Discount Factors to Zero rates  –  Act/365, continuously compounded
%       r(T) = -ln(B(t0,T)) / ((T - t0)/365)
%  -----------------------------------------------------------------------
T_ACT365  = (dates - settlementDate) / 365;
zeroRates = zeros(size(dates));

validIdx = T_ACT365 > 0;
zeroRates(validIdx) = -log(discounts(validIdx)) ./ T_ACT365(validIdx);

% Settlement point: zero rate undefined (T=0), set to NaN or 0
zeroRates(~validIdx) = NaN;

end % bootstrap

%% =======================================================================
%  LOCAL HELPER FUNCTIONS
%  =======================================================================

function [datesOut, discountsOut] = insertPoint(dates, discounts, t, B)
%INSERTPOINT  Insert or overwrite a point in the (sorted) curve.
%   If t already exists, overwrite the discount; otherwise append and sort.
idx = find(dates == t, 1);
if isempty(idx)
    datesOut     = [dates;     t];
    discountsOut = [discounts; B];
    [datesOut, sortIdx] = sort(datesOut);
    discountsOut = discountsOut(sortIdx);
else
    datesOut            = dates;
    discountsOut        = discounts;
    discountsOut(idx)   = B;
end
end % insertPointend