function [neuralData,spikeCounts,spikeTimes,pktHeader] = PacketParser2_EML(ethPkt)
%#codegen
spikeTimes = 0;
spikeCounts = 0;
persistent neuralDataP t pktHeaderP
cbScale = .25;
expectedType = 3;
samplesPerSec = [500 1000 2000 10000 30000];
samplesPerStep = samplesPerSec(expectedType) * .001;
chanMax = 200;
headerLen = 10;
if isempty(neuralDataP)
    t = 0;
    neuralDataP = zeros(chanMax,samplesPerStep);
    pktHeaderP = zeros(headerLen,1);
end

t = t + 1;

% Parse generic ethernet header
srcPort = ByteSwap_EML(ethPkt(21:22),'uint16');
dstPort = ByteSwap_EML(ethPkt(23:24),'uint16');
if srcPort(1) ~= 51001 || dstPort(1) ~= 51002
    neuralData = neuralDataP;
    pktHeader = ones(size(pktHeaderP));
    return
end

ethPktDouble = double(ethPkt);
searchMin = 30;
dataWidth = 2;
searchMax = length(ethPkt) - dataWidth;
searchHdrMax = 30;


searchInd = searchMin;
chInd = 1;
dataPktStarted = false;
while searchInd < searchMax
    if dataPktStarted
        if chInd > (chanMax + 1)
            searchInd = searchInd + 1;
            dataPktStarted = false;
            continue
        end
        chIndUse = chInd - 1;
        
        offsetInd = 1;
        channelData = ...
            ByteSwap_EML(ethPkt((searchInd+offsetInd):(searchInd+offsetInd+(dataWidth-1))),'int16') * cbScale;
        if isequal(channelData',[0 0])
            searchInd = searchInd + 1;
            dataPktStarted = false;
            continue
        end
        neuralDataP(chIndUse,1) = channelData(1);
        chInd = chInd + 1;
        searchInd = searchInd + dataWidth;
    else

        if ethPktDouble(33) ~= 0; %all(ethPktDouble(searchInd) == 2)
            % Expected constituentes of a packet:
            % Eth Header: tops out at 28
            chInd = 1;
            dataPktStarted = true;
            
            searchWithOffset = searchInd;
            dataWidthTs = 4;
            tsType = 'uint32';
            for jj = 1:10
                pktHeaderP(jj) = ByteSwap_EML([ethPkt((searchWithOffset+jj):(searchWithOffset+jj+dataWidthTs-1))],tsType) / 1000;
            end
        end
        searchInd = searchInd + 1;
        if searchInd > searchHdrMax
            break
        end
    end
end

pktHeader = pktHeaderP;
neuralData = neuralDataP;
end