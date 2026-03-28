function [values date CompleteName]=findSeries(equityData,assetName,formatDate)
% [values date CompleteName]=findSeries(equityData,assetName)
%
% Finds an asset in a data-struct 
%   - coming from an Excel file in numeric and cell-format
%   - downloaded from Bloomberg 
% 
%  INPUT:
%  - equityData: data struct from excel: equityData.num: numeric format 
%                                        equityData.cell: cell-format
%  - assetName: string containing the name (or part) of teh asset of interest 
%   (the first one, if there are more than one)
%  - formatDate: format used for dates (default 'mm/dd/yyyy')
%  
%  OUTPUT:
%  - values: asset-prices historical serie
%  - date: dates (in numeric format) for the asset of interest
%  - CompleteName: complete name for the asset of interest

%% Inizialization 
% Costruisco matrice dati in formato cell senza il nome del titolo:
%  taglio la prima riga che contiene i campi descrittivi

if(nargin <3)
    formatDate = 'mm/dd/yyyy';
end

numCancelRows = 1;
dati_cell_cut=equityData.cell(numCancelRows+1:end,:); 
% Inizializzo il nome
CompleteName='';

%% Ricerca
for j=1:size(equityData.cell,2)/2+1
        
        if isempty(findstr(equityData.cell{1,2*j-1},assetName)) % se non ho trovato la colonna che cercavo niente
        else % altrimenti la salvo ed esco dal ciclo
            CompleteName=equityData.cell{1,2*j-1};
            date=datenum(dati_cell_cut(~isnan(equityData.num(:,2*j-1)),2*j-1),formatDate);
            values=equityData.num(~isnan(equityData.num(:,2*j-1)),2*j-1);
            
            break;
        end
end
  
%% Controllo se ho trovato i dati
if strcmp(CompleteName,'')
    error(['Titolo "' assetName '" non trovato; provare a scrivere solo parte del nome']);
end
 
end % findSeries 
                                          