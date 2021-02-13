function [eventDetected, eventPropagated] = CoherenceDetector_EML(activeBool, signalIn, indDetPairCh, thresholds, nDetectionsRequired, txSign, probabilityOfStim)

%#codegen
%Detects if signalIn is larger than  channelThreshold (or smaller depending on txSign) 
%to actually elicit a stimulation (indicated by eventPropagated) we must
%detect (be above/below threshold) for a number of consecutive detections
%(if 0/1 only 1 detection is sufficient)

persistent nEventDetectedPrev
if isempty(nEventDetectedPrev)
    nEventDetectedPrev = 0;
end
if isempty(probabilityOfStim)
    probabilityOfStim=1;
end

eventDetected = false;
eventPropagated = false;
%indDetPairCh = find(detectablePairsChannelsIndexes);
thInDetCh = thresholds(indDetPairCh);
sigInDetCh = signalIn(indDetPairCh);
if activeBool && any(thInDetCh > eps)
    % WE need to decide what we are comparing for coherence!!!! - any / all / sum??
    if (txSign > 0) && any(sigInDetCh > thInDetCh)  %Larger than threhold and sign is positive
 %       eventDetected = true;
        nEventDetectedPrev = nEventDetectedPrev + 1;
    elseif (txSign < 0) && any(sigInDetCh < thInDetCh) %Smaller than threhold and sign is negative
 %       eventDetected = true;
        nEventDetectedPrev = nEventDetectedPrev + 1;
    else
        nEventDetectedPrev = 0;
    end
    if nEventDetectedPrev >= nDetectionsRequired %count number of consecutive detections       
        eventDetected = true;   % eventDetected is now ONLY 1 if duration of detection was met!
        nEventDetectedPrev = 0; % once stimulation signal could be sent -> restart counter
        if rand <= (probabilityOfStim)
            eventPropagated = true; %Actually send stim puse only probabilityOfStim % of the time (0<=probabilityOfStim<=1)
        end
    end
else
    nEventDetectedPrev = 0; 
end
