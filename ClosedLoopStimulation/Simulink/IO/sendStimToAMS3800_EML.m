function stimHappening = sendStimToAMS3800_EML(sendStimPulse)
% send stim pulse to card

persistent stimInterface;
if isempty(stimInterface)
    %Initialize the first time
    [stimInterface, IdxStatus, onValue, offValue]  = configureAMS3800(); % Check that IdxStatus is fixed
end

if sendStimPulse >= 1
    %Send stimulation pulse
    stimInterface.SetListValue(0,IdxStatus, onValue);
    % to turn it off you would send:
    stimInterface.SetListValue(0,IdxStatus, offValue);
end
