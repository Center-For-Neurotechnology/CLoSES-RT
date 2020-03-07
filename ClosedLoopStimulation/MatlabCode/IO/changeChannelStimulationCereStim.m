function res = changeChannelStimulationCereStim(cerestim, electrode1, electrode2)

if ~isempty(cerestim)
%Change stimulation channel to the input electrodes
%        res = cerestim.readSequenceStatus(); %??
    try
        res = stopTriggerStimulus(cerestim);
        res = beginningOfSequence(cerestim);
        res = beginningOfGroup(cerestim);
        res = autoStimulus(cerestim, electrode1, 1); %Fixed to 2 configurations only! could be made more general
        res = autoStimulus(cerestim, electrode2, 2);
        % res = triggerStimulus(cerestim, 'rising');
        res = endOfGroup(cerestim);
        res = endOfSequence(cerestim);
        res = cerestim.triggerStimulus('rising');
        res = cerestim.readSequenceStatus();
        if res>=0
            disp(['Stimulation Electrodes changed - Cerestim status: ',num2str(res)])
        end
    catch
        disp('Cannot access Cerestim')
        res = -1;
    end
 
else
    disp('Cannot access Cerestim')
    res = -1;
end
