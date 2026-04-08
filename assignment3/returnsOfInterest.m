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
    
    bbgCode = underlyingCode(sharesList(i,:));
    
    % Select the shares of interest
    [values_share, t_share] = findSeries(shareData, bbgCode, formatDate);
    
    % Trovo l'offset di partenza esatto (l'ultimo giorno <= alla prima data)
    [~, offset] = closestDate(tSelected(1), t_share);
    
    % Inizializzo il "puntatore" del titolo
    if isempty(offset) || offset == 0
        idx_stock = 1; % Rete di sicurezza
    else
        idx_stock = offset;
    end
    
    % Ciclo sulle date che mi interessano (da 1 a length)
    for d = 1:length(tSelected)
        
        % Faccio avanzare il puntatore SOLO SE la data successiva del titolo 
        % esiste e non supera la data del calendario di riferimento
        while (idx_stock < length(t_share)) && (t_share(idx_stock + 1) <= tSelected(d))
            idx_stock = idx_stock + 1;
        end
        
        % Prendo il valore a cui è fermo il puntatore
        valuesSelectedShares(d, i) = values_share(idx_stock);
        
    end
end
returnsSelected=log(valuesSelectedShares(2:end,:)./valuesSelectedShares(1:end-1,:));
tSelected = tSelected(2:end);

end %returnsOfInterest