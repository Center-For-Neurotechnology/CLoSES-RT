function signalOut = selectChannels_EML(signalIn, selectCh)
%#codegen
signalOut = zeros(1,length(selectCh));
nRealChannels = size(signalIn,2);
if isempty(selectCh) || all(selectCh) <=0 || nRealChannels <=1 || nRealChannels < length(selectCh)%if either select all channels or signal is smaller than selChannels size (e.g. coherence)
    signalOut = signalIn(:,1:nRealChannels);
else
    signalOut = signalIn(:,selectCh);
end
