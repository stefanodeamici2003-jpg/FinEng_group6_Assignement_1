function [datesCDS, spreadsCDS] = construct_dataset_ES_4()
% The function constructs the dataset given by the Assignment
settlementDate = datenum('19-Feb-2008');

% CDS maturity dates
datesCDS = zeros(6, 1);
datesCDS(1) = addtodate(settlementDate, 1, 'year');  
datesCDS(2) = addtodate(settlementDate, 2, 'year');
datesCDS(3) = addtodate(settlementDate, 3, 'year');
datesCDS(4) = addtodate(settlementDate, 4, 'year');
datesCDS(5) = addtodate(settlementDate, 5, 'year'); 
datesCDS(6) = addtodate(settlementDate, 7, 'year'); 

% CDS spreads  (bps to decimal)
spreadsCDS = [29; 34; 37; 39; 40; 40] * 1e-4;

end