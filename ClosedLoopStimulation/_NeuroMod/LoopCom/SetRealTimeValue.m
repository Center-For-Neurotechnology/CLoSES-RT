function tg = SetRealTimeValue(tg,paramName,newValue)
    if ~isempty(tg.getparamid('',paramName))
        tg.setparam(tg.getparamid('',paramName),newValue);
        setVal = tg.getparam(tg.getparamid('',paramName));
        if isequal(setVal,newValue)
            fprintf('Set [%s] to %0.2f.\n',paramName,newValue(1))
        else
            fprintf('Did not successfully set %s.\n',paramName)
        end
    else
        fprintf('Did not successfully set %s. It does not exist.\n',paramName)
    end
end
