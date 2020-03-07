function sendStimManaged = ManageStimLockout_EML(sendStimPulse,lockoutDuration,startupTime,stepPeriod)
persistent t isLockedOut t_master
if isempty(t); t = 0; t_master = 0; isLockedOut = false; end
sendStimManaged = false;
if sendStimPulse && ~isLockedOut && (t_master > (startupTime / stepPeriod))
    t = 0;
    isLockedOut = true;
    sendStimManaged = true;
end
t = t + 1;
t_master = t_master + 1;
if t > lockoutDuration / stepPeriod
    isLockedOut = false;
end