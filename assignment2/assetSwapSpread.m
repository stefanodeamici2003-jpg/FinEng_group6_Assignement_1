function [s_asw, couponDates] = assetSwapSpread(datesDF, discounts, settlementDate, issueDate, maturityDate, cleanPrice, coupon)
% ASSETSWAPSPREAD  Par Asset Swap Spread over Euribor 3M.
%
%   Formula: s_asw = ( C(0) - C_bar(0) ) / BPV_float
%
%   C(0)      = risk-free price value of bond cash flows      
%   C_bar(0)  = market dirty price                   
%   BPV_float = floating leg annuity (ACT/360)
%
%   INPUT:
%     datesDF        - risk-free curve pillar dates
%     discounts      - corresponding discount factors
%     settlementDate - settlement date (t0)
%     issueDate      - bond issue date
%     maturityDate   - bond maturity date
%     cleanPrice     - market clean price in decimal (e.g. 1.015 = 101.5%)
%     coupon         - annual coupon rate in decimal  (e.g. 0.046 =   4.6%)
%
%   OUTPUT:
%     s_asw - Asset Swap Spread 

% Build the full schedule of annual coupon dates
couponDates = [];
d = issueDate;
while true
    d = addtodate(d, 1, 'year');
    couponDates = [couponDates; d];
    if d >= maturityDate, break; end
end
couponDates(end) = maturityDate;  % force last date = maturity

% Last coupon date before settlement → accrual start
% If no coupon has been paid yet, accrual starts from issue date
pastDates = couponDates(couponDates <= settlementDate);
if isempty(pastDates)
    lastCoupon = issueDate;
else
    lastCoupon = pastDates(end);
end

% Future coupon dates (strictly after settlement)
futureDates = couponDates(couponDates > settlementDate);
% In our case: 31-Mar-2008, 31-Mar-2009, 31-Mar-2010, 31-Mar-2011, 31-Mar-2012

%  Market dirty price:  C_bar(0)
%
%  Accrual  = coupon * yearfrac(lastCoupon, settlement)   [ACT/ACT]
%  C_bar(0) = cleanPrice + AI

AC    = coupon * yearfrac(lastCoupon, settlementDate, 0);  % ACT/ACT
C_bar = cleanPrice + AC;

%   Risk free price: C(0)
%
%   C(0) = sum_{i=1}^{N} coupon * delta_i * B(t0, ti)  +  B(t0, tN)
%   delta_i = yearfrac(t_{i-1}, t_i)   ACT/ACT
%   Period start dates: lastCoupon for first period, then futureDates(i-1)

periodStarts = [lastCoupon; futureDates(1:end-1)];

C0 = 0;
% Calculation of coupons price
for i = 1:length(futureDates)
    delta_i = yearfrac(periodStarts(i), futureDates(i), 3);   % ACT/365
    df_i  = linearRateInterp(datesDF, discounts, settlementDate, futureDates(i)); %B(t0, ti)
    C0    = C0 + coupon * delta_i * df_i;
end

% Add principal payment at maturity
df_N = linearRateInterp(datesDF, discounts, settlementDate, maturityDate);
C0   = C0 + df_N;

% 4. Floating leg BPV  (Euribor 3M, ACT/360)
%
%   BPV = sum_{j=1}^{Nf} delta_j * B(t0, tj)
%   Dates: 3M steps forward from settlement to maturity

floatDates = [];
d = settlementDate;
while true
    d = addtodate(d, 3, 'month');
    floatDates = [floatDates; d];
    if d >= maturityDate, break; end
end
floatDates(end) = maturityDate;  % last float date = bond maturity

floatStarts = [settlementDate; floatDates(1:end-1)];

BPV = 0;
for j = 1:length(floatDates)
    delta_j = yearfrac(floatStarts(j), floatDates(j), 2);     % ACT/360
    df_j  = linearRateInterp(datesDF, discounts, settlementDate, floatDates(j));
    BPV   = BPV + delta_j * df_j;
end


%ASSET SWAP SPREAD
s_asw = (C0 - C_bar) / BPV;

% ── Summary ───────────────────────────────────────────────────────────────
fprintf('\n--- Asset Swap Spread Breakdown ---\n');
fprintf('Last coupon date : %s\n',       datestr(lastCoupon));
fprintf('Accrual : %.6f\n',     AC);
fprintf('Dirty Price      : %.6f\n',     C_bar);
fprintf('C(0) risk-free   : %.6f\n',     C0);
fprintf('BPV float        : %.6f\n',     BPV);
fprintf('ASW Spread       : %.4f bps\n', s_asw * 10000);

end