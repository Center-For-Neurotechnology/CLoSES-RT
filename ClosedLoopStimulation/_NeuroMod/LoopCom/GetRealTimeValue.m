function getVal = GetRealTimeValue(tg,paramName)
    getVal =[];
    if ~isempty(tg.getparamid('',paramName))
        getVal = tg.getparam(tg.getparamid('',paramName));
    end

end
