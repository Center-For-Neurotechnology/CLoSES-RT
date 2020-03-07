function [sendStimulationPulse, indTrialInM, vecStimTrials] = stimulateNoutofMtrials(detectedStim, maxNStimTrials, outOfMTrials,indTrialInM, vecStimTrials)
% Send stimulation pulse at most N out of M times

%persistent vecStimTrials indTrialInM

sendStimulationPulse = false;

% Initialize if first time or if size is different
% if isempty(vecStimTrials) || length(vecStimTrials) ~= outOfMTrials
%     vecStimTrials = zeros(outOfMTrials,1); 
%     indTrialInM = 0;
% end
% increase indTrialInM and reset indTrialInM to make circular changes
if indTrialInM<outOfMTrials
    indTrialInM = indTrialInM + 1;
else
    indTrialInM =1;
end

% Fill vector of Stimulated Trials and check if more than N trials with stim
vecStimTrials(indTrialInM) = 0;
nStimWithinLastMtrials = sum(vecStimTrials(:));
if detectedStim ==1 && nStimWithinLastMtrials < maxNStimTrials
    vecStimTrials(indTrialInM) = 1;
    sendStimulationPulse = true;
end


