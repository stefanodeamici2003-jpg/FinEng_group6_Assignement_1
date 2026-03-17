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

%% Dirty Price C_bar(0)
% Rough calculation of the number of coupons in the lifespan of the Bond,
% rounded by the function round()
nCoupons = round((maturityDate - issueDate) / 365.25);
couponDates = zeros(nCoupons, 1);

% The function calculates the theoretical point in time where coupons 
% should be paid without worring about the working days
for i = 1:nCoupons
    couponDates(i) = addtodate(issueDate, i, 'year');
end

% Last coupon date before settlement in order to be able to calculate the
% Accrual starting point
pastDates = couponDates(couponDates <= settlementDate);
if isempty(pastDates)
    lastCoupon = issueDate; % if no coupon has been paid yet, accrual starts from issue date
else
    lastCoupon = pastDates(end);
end

% Future coupon dates 
futureDates = couponDates(couponDates > settlementDate);

% Accrual: we don't need to use busdate() since settlement date is for sure
% a business day
A = coupon * yearfrac(lastCoupon, settlementDate, 3);  % ACT/365

% Market dirty price:  C_bar(0)= cleanPrice + A
C_bar = cleanPrice + A;

%% Risk free price: C(0)
% Period start dates: contains the starting points of the year fraction starting
% from the last time a coupon has been paid up to futureDates(end-1)
startDates = [lastCoupon; futureDates(1:end-1)];
C0 = 0;

% Calculation of coupons price
for i = 1:length(futureDates)
    % unadjusted yearfrac between two couponn payment dates
    delta_i = yearfrac(startDates(i), futureDates(i), 6); %30/360
    
    % Calculation through the Financial Toolbox function busdate()
    % of the exact date with respect to the "modified following"
    % criteria used to determine the correct discount factor
    adjustedDate = busdate(futureDates(i), 'modifiedfollow');
    B_i = linearRateInterp(datesDF, discounts, settlementDate, adjustedDate);
    
    C0 = C0 + coupon * delta_i * B_i;
end
% Principal payment at maturity
B_N = linearRateInterp(datesDF, discounts, settlementDate, busdate(maturityDate, "modifiedfollow"));

C0   = C0 + B_N

%% Floating leg BPV  (Euribor 3M, ACT/360)
% Calculation of the quarters in the lifespan of the bound or number of
% coupon payment days
nQuarters = round((maturityDate - settlementDate) / (365.25/4))
floatDates = zeros(nQuarters, 1);
% Proceeding in the same fashion of the previous sector:

% Schedule of the theoretical days when coupons will be paid
for i = 1:nQuarters
    floatDates(i) = addtodate(settlementDate, i*3, 'month'); % each 3 months 
end

% Period start dates
floatStarts = [settlementDate; floatDates(1:end-1)];

% BPV = sum_{j=1,..,Nf} delta_j * B(t0, tj)
BPV = 0;
for j = 1:length(floatDates)
    delta_j = yearfrac(floatStarts(j), floatDates(j), 6);     % 30/360
    adjustedDate = busdate(floatDates(j), 'modifiedfollow');
    B_j  = linearRateInterp(datesDF, discounts, settlementDate, adjustedDate);
    BPV   = BPV + delta_j * B_j;
end
BPV
%% asset swap spread
s_asw = (C0 - C_bar) / BPV;

end