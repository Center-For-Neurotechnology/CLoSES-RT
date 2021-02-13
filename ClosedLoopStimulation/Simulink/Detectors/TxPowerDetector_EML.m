function [iedEventDetected,iedEventPropagated] = TxPowerDetector_EML(activeBool, signalIn, detectableChannels, channelThreshold, nSamplesDetectedRequired, txSign)

%#codegen

persistent nEventDetectedPrev
if isempty(nEventDetectedPrev)
    nEventDetectedPrev = 0;
end

iedEventDetected = false;
iedEventPropagated = false;
if activeBool && all(channelThreshold(detectableChannels) > eps)
    if (txSign > 0) && any(signalIn(:,detectableChannels) > channelThreshold(detectableChannels))  %Larger than threhold and sign is positive
        iedEventDetected = true;
    elseif (txSign < 0) && any(signalIn(:,detectableChannels) < channelThreshold(detectableChannels)) %Smaller than threhold and sign is negative
        iedEventDetected = true;
    end
    
    if nEventDetectedPrev >= nSamplesDetectedRequired %count number of consecutive detections       
        iedEventPropagated = true;
    end
end

nEventDetectedPrev = iedEventDetected;