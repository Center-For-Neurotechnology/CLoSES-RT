function tg = SetRealTimeOnlyNewValue(tg,paramName,newValue)

currentVal = GetRealTimeValue(tg,paramName);
%Check if values is different than existing and set new value
if ~isequal(currentVal, newValue) && (length(currentVal)==length(newValue)) % RZ: added length comparison - BAD hack to avoid issues with different sizes that are not allowed during parameter update
    tg = SetRealTimeValue(tg,paramName,newValue);
end
