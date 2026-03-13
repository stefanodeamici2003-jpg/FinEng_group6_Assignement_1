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
%     datesDF        
%     discounts      
%     settlementDate 
%     issueDate      
%     maturityDate   
%     cleanPrice     
%     coupon         
%
%   OUTPUT:
%     s_asw : Asset Swap Spread 

% Schedule of annual coupon dates
nCoupons    = round(years(datetime(maturityDate, 'ConvertFrom', 'datenum') - ...
                          datetime(issueDate, 'ConvertFrom', 'datenum')));
couponDates = zeros(nCoupons, 1);
for i = 1:nCoupons
    couponDates(i) = addtodate(issueDate, i, 'year');
end
couponDates(end) = maturityDate;

% Last coupon date before settlement (accrual start)
pastDates = couponDates(couponDates <= settlementDate);
if isempty(pastDates)
    lastCoupon = issueDate; % if no coupon has been paid yet, accrual starts from issue date
else
    lastCoupon = pastDates(end);
end

% Future coupon dates 
futureDates = couponDates(couponDates > settlementDate);

%% Market dirty price:  C_bar(0)= cleanPrice + A
% Accrual
A = coupon * yearfrac(lastCoupon, settlementDate, 0);  % ACT/365

C_bar = cleanPrice + A;

%% Risk free price: C(0)
% Period start dates: lastCoupon for first period, then futureDates(i-1)
startDates = [lastCoupon; futureDates(1:end-1)];
C0 = 0;

% Calculation of coupons price
for i = 1:length(futureDates)
    delta_i = yearfrac(startDates(i), futureDates(i), 3);   % ACT/365
    B_i  = linearRateInterp(datesDF, discounts, settlementDate, futureDates(i)); %B(t0, ti) risk free DF
    C0    = C0 + coupon * delta_i * B_i;
end
% Principal payment at maturity
B_N = linearRateInterp(datesDF, discounts, settlementDate, maturityDate);

C0   = C0 + B_N;

%% Floating leg BPV  (Euribor 3M, ACT/360)

% Schedule of floating leg payments
nQuarters = round((maturityDate - settlementDate) / (365.25/4));
floatDates = zeros(nQuarters, 1);
for i = 1:nQuarters
    floatDates(i) = addtodate(settlementDate, i*3, 'month'); % each 3 months 
end
floatDates(end) = maturityDate; % last float date = bond maturity 

% Period start dates
floatStarts = [settlementDate; floatDates(1:end-1)];

% BPV = sum_{j=1,..,Nf} delta_j * B(t0, tj)
BPV = 0;
for j = 1:length(floatDates)
    delta_j = yearfrac(floatStarts(j), floatDates(j), 2);     % ACT/360
    B_j  = linearRateInterp(datesDF, discounts, settlementDate, floatDates(j));
    BPV   = BPV + delta_j * B_j;
end

%% asset swap spread
s_asw = (C0 - C_bar) / BPV;

end