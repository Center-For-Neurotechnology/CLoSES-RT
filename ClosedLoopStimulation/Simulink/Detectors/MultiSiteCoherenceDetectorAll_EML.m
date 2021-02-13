function [eventDetected, eventPropagated, stimChannelNumber] = MultiSiteCoherenceDetectorAll_EML(activeBool, signalIn, indDetPairCh, thresholdsUpperLim, thresholdsLowerLim, nDetectionsRequired, possibleStimChannels, probabilityOfStim)

%#codegen
%Detects if signalIn is larger than  channelThreshold (or smaller depending on txSign) 
%to actually elicit a stimulation (indicated by eventPropagated) we must
%detect (be above/below threshold) for a number of consecutive detections
%(if 0/1 only 1 detection is sufficient)
% possibleStimChannels should be a vector with consecutive numbers corresponding to bipolar stim channels configurations. 
% e.g:possibleStimChannels=[1,2,3,4]; means: use stim on bipolar channel 1-2 when above threshold and stim on bipolar channel 3-4 if below lower threshold

persistent nEventDetectedPrevUpper
if isempty(nEventDetectedPrevUpper)
    nEventDetectedPrevUpper = 0;
end
persistent nEventDetectedPrevLower
if isempty(nEventDetectedPrevLower)
    nEventDetectedPrevLower = 0;
end

if length(possibleStimChannels)<4 % assumes that it was not meant for multisite stim if there are NOT 4 contacts!
    possibleStimChannels(2)=possibleStimChannels(1); %
    possibleStimChannels(3)=possibleStimChannels(1); %
    possibleStimChannels(4)=possibleStimChannels(1); %
end
if isempty(probabilityOfStim)
    probabilityOfStim=1;
end

eventDetected = false;
eventPropagated = false;
stimChannelNumber = zeros(1,2); %Not sure if I want to change this! or keep the previous one

%indDetPairCh = find(detectablePairsChannelsIndexes);
thInDetChUpperLim = thresholdsUpperLim(indDetPairCh);
thInDetChLowerLim = thresholdsLowerLim(indDetPairCh);

sigInDetCh = signalIn(indDetPairCh);
if activeBool && any(thInDetChUpperLim > eps)
    % WE need to decide what we are comparing for coherence!!!! - any / all / sum??
    if all(sigInDetCh > thInDetChUpperLim)  %Larger than threhold and sign is positive
  %      eventDetected = true;
        nEventDetectedPrevUpper = nEventDetectedPrevUpper + 1;
    elseif all(sigInDetCh < thInDetChLowerLim) %Smaller than threhold and sign is negative
 %       eventDetected = true;
        nEventDetectedPrevLower = nEventDetectedPrevLower + 1;
    else
        nEventDetectedPrevUpper = 0;
        nEventDetectedPrevLower = 0;
    end
    if nEventDetectedPrevUpper >= nDetectionsRequired %count number of consecutive detections       
  %      eventPropagated = true;
        eventDetected = true;
        stimChannelNumber(1) = possibleStimChannels(1);
        stimChannelNumber(2) = possibleStimChannels(2);
        nEventDetectedPrevUpper = 0; %once stimulation signal is sent -> restart counter
    end
    if nEventDetectedPrevLower >= nDetectionsRequired %count number of consecutive detections
 %       eventPropagated = true;
        eventDetected = true;
        stimChannelNumber(1) = possibleStimChannels(3);
        stimChannelNumber(2) = possibleStimChannels(4);
        nEventDetectedPrevLower = 0; %once stimulation signal is sent -> restart counter
    end
    if (eventDetected == true) && (rand <= probabilityOfStim) %Only send stimpulse (eventPropagated) if detection longer than req duration on probabilityOfStim % of the times
        eventPropagated = true;
    end
else
    nEventDetectedPrevUpper = 0; 
    nEventDetectedPrevLower = 0;
end
