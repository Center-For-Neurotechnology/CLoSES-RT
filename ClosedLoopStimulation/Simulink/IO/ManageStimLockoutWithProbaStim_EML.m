function sendStimManaged = ManageStimLockoutWithProbaStim_EML(sendStimPulse,lockoutDuration,startupTime,stepPeriod, probabilityOfStim)
%Identical to ManageStimLockout_EML but added   && (rand <= probabilityOfStim)

persistent t isLockedOut t_master
if isempty(t); t = 0; t_master = 0; isLockedOut = false; end
sendStimManaged = false;
if isempty(probabilityOfStim)
    probabilityOfStim=1;
end

if sendStimPulse && ~isLockedOut && (t_master > (startupTime / stepPeriod)) && (rand <= probabilityOfStim)
    t = 0;
    isLockedOut = true;
    sendStimManaged = true;
end
t = t + 1;
t_master = t_master + 1;
if t > lockoutDuration / stepPeriod
    isLockedOut = false;
end
