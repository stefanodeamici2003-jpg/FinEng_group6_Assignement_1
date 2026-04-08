function price = getLatestPrice(shareData, bbgCode, format, refDate)
    [val, dates] = findSeries(shareData, bbgCode, format);
    price = val(find(dates <= datenum(refDate), 1, 'last'));
end