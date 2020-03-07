function [neuralData,spikeCounts,spikeTimes,pktHeader] = PacketParser3_EML(ethPkt,iterInd)
%#codegen


persistent neuralDataP t tsPrev tsPkt isValidData pktHeaderP
persistent spikeCountsP spikeTimesP pktCounter pktPrev
cbScale = .25;
expectedType = 3;
samplesPerSec = [500 1000 2000 10000 30000];
samplesPerStep = samplesPerSec(expectedType) * .001;
chanMax = 200;
ignoreTimestampsBool = true;
if isempty(neuralDataP)
    t = 0;
    neuralDataP = zeros(chanMax,samplesPerStep);
    spikeTimesP = zeros(chanMax,1);
    spikeCountsP = zeros(chanMax,1);
    pktCounter = 0;
    tsPrev = uint16(0);
    tsPkt = 0;
    isValidData = false;
    pktHeaderP = zeros(10,1);
    pktPrev = zeros(4,1,'uint8');
    
end
t = t + 1;

% Parse generic ethernet header
srcPort = ByteSwap_EML(ethPkt(21:22),'uint16');
dstPort = ByteSwap_EML(ethPkt(23:24),'uint16');
ethPktDouble = double(ethPkt);
pktHeaderP(1:10) = ethPktDouble(31:40);

if srcPort(1) ~= 51001 || dstPort(1) ~= 51002 || all(pktPrev == ethPkt(29:32));
    neuralData = neuralDataP;
    pktHeader = ((pktHeaderP));
    spikeCounts = (spikeCountsP);
    spikeTimes = (spikeTimesP);
    
    return
end
pktPrev = ethPkt(29:32);
pktCounter = pktCounter + 1;
searchMin = 30;
searchHdrMax = 34;
dataWidth = 2;
searchMax = length(ethPkt) - dataWidth;

searchInd = searchMin;
chInd = 131;
dataPktStarted = false;
spikePktStarted = false;

while searchInd < searchMax
    searchInd = searchInd + 1;
    if dataPktStarted
        if chInd > (chanMax + 1)
            searchInd = searchInd + 1;
            dataPktStarted = false;
            searchHdrMax = searchInd + 150;
            continue
        end
        chIndUse = chInd - 1;
        
        offsetInd = 1;
        channelData = ...
            ByteSwap_EML(ethPkt((searchInd+offsetInd):(searchInd+offsetInd+(dataWidth-1))),'int16') * cbScale;
        if isequal(channelData',[0 0])
            dataPktStarted = false;
            searchHdrMax = searchInd + 150;
            continue
        end
        tsPktUse = mod(tsPkt-1,samplesPerStep) + 1;
        if isValidData
            neuralDataP(chIndUse,tsPktUse) = channelData(1);
        end
        chInd = chInd + 1;
        searchInd = searchInd + dataWidth - 1;
    elseif spikePktStarted
        
        chIndUse = chInd - 128 - 20;
        spikeCountsP(chIndUse) = spikeCountsP(chIndUse) + 1;
        searchInd = searchInd + 50;
        spikePktStarted = false;
        searchHdrMax = searchInd + 150;
        chInd = chInd - 1;
        continue
        
    else
        if searchInd > searchHdrMax
            break
        end
        if all(ethPktDouble((searchInd-1):(searchInd+1))' == [0 0 expectedType])
            chInd = 1;
            dataPktStarted = true;
            tsRcvd = ByteSwap_EML([ethPkt((searchInd-4):(searchInd-3))],'uint16');
            
            if tsRcvd(1) >= tsPrev || ignoreTimestampsBool
                tsPrev = tsRcvd(1);
                tsPkt = tsPkt + 1;
                isValidData = true;
                for jj = 1:9
                    pktHeaderP(jj) = ethPktDouble((searchInd+2+jj));
                end
            else
                isValidData = false;
            end
        elseif (ethPktDouble(searchInd) ~=0) && all(ethPktDouble(searchInd+1:searchInd+2) == [0; 0;])
            chInd = ethPktDouble(searchInd);
            spikePktStarted = true;
            tsRcvd = ByteSwap_EML(ethPkt((searchInd-4):(searchInd-3)),'uint16');
            
            tsPrev = tsRcvd(1);
            tsPkt = tsPkt + 1;
            isValidData = true;
            
            for jj = 1:9
                pktHeaderP(jj) = ethPktDouble((searchInd+jj-1));
            end
            
        end
        
    end
end
pktHeaderP(10) = iterInd;
% pktHeaderP(1:10) = ethPktDouble(31:40);

pktHeader = pktHeaderP;
neuralData = neuralDataP;
spikeCounts = spikeCountsP;
spikeTimes = spikeTimesP;

end