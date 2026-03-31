function NPV = discounted_cash_flow(dates, discounts, initial_amount)
% Making use of the given discounts, the function finds the NPV of a cash flow
% dates: the dates of the given discounts
% discounts: DF in the given dates

% Definition of the cash flow (20Y, 5% AAGR applied at the end of each year)
Y = 20; M = 12;
cash_flow = zeros(M * Y, 1);
CF = initial_amount;
AAGR = 0.05;

for y = 0:(Y-1)
    for m = 1:M
        cash_flow(m+y*M) = CF;
    end
    CF = CF * (1+AAGR);
end
% Calculate the right points in time
SettlementDate = dates(1);
FluxDates = zeros (M*Y, 1);

for i=1:Y*M
    FluxDates(i) = addtodate(SettlementDate, i, "month");
end

% Calculate the correct discounts we need
correct_discounts = zeros (M*Y, 1);
for y = 0:(Y-1)
    for m = 1:M
        correct_discounts(m+y*M) = linearRateInterp(dates, discounts, SettlementDate, FluxDates(m+y*M));
    end
end

% Calcualtion of NPV
NPV = sum(cash_flow .* correct_discounts);

end