function [datesCDS, spreadsCDS] = construct_dataset_ES_4()
% The function constructs the dataset given by the Assignment
% We are missing the 6-th year!
settlementDate = datenum('19-Feb-2008');

% =========================================================================
% CDS MATURITY DATES  (annual, from settlement)
% =========================================================================
datesCDS = zeros(6, 1);
datesCDS(1) = addtodate(settlementDate, 1, 'year');  % 1Y -> 19-Feb-2009
datesCDS(2) = addtodate(settlementDate, 2, 'year');  % 2Y -> 19-Feb-2010
datesCDS(3) = addtodate(settlementDate, 3, 'year');  % 3Y -> 19-Feb-2011
datesCDS(4) = addtodate(settlementDate, 4, 'year');  % 4Y -> 19-Feb-2012
datesCDS(5) = addtodate(settlementDate, 5, 'year');  % 5Y -> 19-Feb-2013
datesCDS(6) = addtodate(settlementDate, 7, 'year');  % 7Y -> 19-Feb-2015

% =========================================================================
% CDS SPREADS  (in decimal)
% =========================================================================
spreadsCDS = [29; 34; 37; 39; 40; 40] * 1e-4;
%              1Y  2Y  3Y  4Y  5Y  7Y   (bps → decimal, /10000)

end