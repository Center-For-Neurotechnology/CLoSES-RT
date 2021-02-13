function disconnectCereStim(cerestim)

try
stopTriggerStimulus(cerestim); %        res = cerestim.stopTriggerStimulus();
disconnect(cerestim);

catch
    disp('Cannot disconnect from Cerestim - is it off already?')
end

%delete(cerestim);
