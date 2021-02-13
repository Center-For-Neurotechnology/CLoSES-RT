function sendStimManaged = ManageStimLockoutWithMaxConsecutive_EML(sendStimPulse,lockoutDuration,startupTime,maxConsecutiveTrials, stepPeriod)
persistent t isLockedOut tMaster nConsecutiveStim nStimGlobal
if isempty(t); t = 0; tMaster = 0; isLockedOut = false; nConsecutiveStim = 0; nStimGlobal = 0; end
sendStimManaged = false;
if sendStimPulse && ~isLockedOut && (tMaster > (startupTime / stepPeriod))
    t = 0;
    isLockedOut = true;
    sendStimManaged = true;
    nConsecutiveStim = nConsecutiveStim +1;
    nStimGlobal = nStimGlobal +1;
end
t = t + 1;
tMaster = tMaster + 1;
if t > lockoutDuration / stepPeriod
    isLockedOut = false;
end
if nConsecutiveStim > maxConsecutiveTrials %RIZ: not tested
    isLockedOut = true;
    nConsecutiveStim = 0;
end
