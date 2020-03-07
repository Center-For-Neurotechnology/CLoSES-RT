function signalOut = selectChannelsFromFrame_EML(signalIn, selectCh)
%#codegen

signalOut = zeros(1,length(selectCh));
nRealChannels = size(signalIn,2);
if isempty(selectCh) || all(selectCh) <=0 ||  nRealChannels <=1 || nRealChannels < length(selectCh) %if either select all channels or by mistake selChannels is larger than real channels
    signalOut = signalIn(1,1:nRealChannels);
else
    signalOut = signalIn(1,selectCh); %Only send first time point of frame
end
