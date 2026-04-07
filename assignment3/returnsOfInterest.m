function [tSelected, returnsSelected] = returnsOfInterest(inputFile, refDate, timeWindow, sharesList, formatDate)
% Selects set of dates and returns in a lag of interest
% [tSel returnsSel] = returnsOfInterest(inputFile, refDate, timeWindow, sharesList)
%
% INPUTS:
% - inputFile:  complete excel file name (with path) 
% - refDate:    first date of interest
% - timeWindow: in months
% - sharesList: list of the N Shares of Interest
% - formatDate: format used for dates (default 'mm/dd/yyyy')
% 
% OUTPUTS:
% - tSelected:  vector with the T dates of interest 
% - returnsSel: matrix with TxN returns values
%
% USES:
% - findSeries: given the set of data selects the asset of interest
% - dateAddMonth: adds to a month a given number of months
% - closestDate: selects the nearest (even the previous one) to a given date
% - underlyingCode: Converts share name in bbg code 

if(nargin <5)
    formatDate = 'mm/dd/yyyy';
end

elementsBasket = size(sharesList,1);

% Scarico dati storici 
[shareData.num,shareData.cell]=xlsread(inputFile,'Data','a5:cx1295');

% Select the set of dates of interest: the ones in Eurostoxx50
[values_index, t_index, ~]=findSeries(shareData,'SX5E Index', formatDate);
% refDate, endDate
refDate=datenum(refDate);
[refDate, idxStart] = closestDate(refDate, t_index);
datetime(refDate, "ConvertFrom", "datenum");
endDate = dateAddMonth(refDate, timeWindow);
[~, idxEnd] = closestDate(endDate, t_index);

tSelected = t_index(idxEnd:idxStart);
% Prices of the selected shares
% If the value is not present I take the value from the previous date 
valuesSelectedShares=zeros(idxStart-idxEnd+1,elementsBasket);


for i=1:elementsBasket
    
    bbgCode= underlyingCode(sharesList(i,:));
    %Select the shares of interest
    [values_share, t_share]=findSeries(shareData, bbgCode, formatDate);
    [val_time, offset] = closestDate(endDate, t_share);    
    
    for d = 0:length(tSelected) - 1
        if t_share(offset + d) > tSelected(d+1)
            t_share = [t_share(1:offset + d-1); tSelected(d+1); t_share(offset + d:end)];
            values_share = [values_share(1:offset + d-1); values_share(offset + d-1); values_share(offset + d:end)];
        end
        
    end
    valuesSelectedShares(:, i) = values_share(offset:offset+length(tSelected) - 1);
end
returnsSelected=log(valuesSelectedShares(2:end,:)./valuesSelectedShares(1:end-1,:));
tSelected = tSelected(2:end);

end %returnsOfInterest