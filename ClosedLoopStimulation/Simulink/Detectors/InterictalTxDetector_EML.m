function [iedEventDetected,iedEventPropagated] = InterictalTxDetector_EML(activeBool,signalIn,detectableChannels,channelThreshold,shamProbability)

%#codegen

persistent iedEventDetectedPrev
if isempty(iedEventDetectedPrev)
    iedEventDetectedPrev = false;
end

if activeBool && ...
        (any(signalIn(:,detectableChannels) > channelThreshold(detectableChannels)) && all(channelThreshold(detectableChannels) > 0)) ...
        || (any(signalIn(:,detectableChannels) < channelThreshold(detectableChannels)) && all(channelThreshold(detectableChannels) < 0))

    iedEventDetected = true;
    
    if rand > (shamProbability) && ~iedEventDetectedPrev % shamProbability should be called different -> idea have some cases in which detection occurs but there is no situmlation
        iedEventPropagated = true;
    else
        iedEventPropagated = false;
        
    end
    

else
    iedEventDetected = false;
    iedEventPropagated = false;
    
end

iedEventDetectedPrev = iedEventDetected;