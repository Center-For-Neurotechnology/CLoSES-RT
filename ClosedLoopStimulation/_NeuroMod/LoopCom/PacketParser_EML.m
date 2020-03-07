function [neuralData,spikeCounts,spikeTimes,pktHeader,nspTime] = PacketParser_EML(ethPkt,iterInd)
%#codegen


persistent neuralDataP t tsPrev tsPkt isValidData pktHeaderP
persistent spikeCountsP spikeTimesP pktCounter pktPrev dropCounter
persistent tsPktUse
% TEST ONLY: overwrite all data with random nonsense + signal(1) + trigger (129) and return
randSource = false;

% Blackrock packets are off by a factor of 4 in Central 6 and beyond
cbScale = .25;
% NSP property: packets will be one of these five rates as of 2016.08
samplesPerSec = [500 1000 2000 10000 30000];
% These parameters tell us how many samples per step; must match the
% expectations from the sCoreParam struct.
expectedType = 3;
modelRateSec = .001;
samplesPerStep = samplesPerSec(expectedType) * modelRateSec;
chanMax = 200;
% We can choose to not use the timestamp information, but we probably
% should
ignoreTimestampsBool = false;
% Do we even consider the possibility of digital input packets? Or do we
% dismiss anything that doesn't look like continuous data?
parseSpikePackets = false;

if isempty(neuralDataP)
    t = 0;
    neuralDataP = zeros(chanMax,samplesPerStep);
    spikeTimesP = zeros(chanMax,1);
    spikeCountsP = zeros(chanMax,1);
    pktCounter = 0;
    tsPrev = 0;
    tsPkt = 0;
    tsPktUse = 1;
    isValidData = false;
    pktHeaderP = zeros(10,1);
    pktPrev = zeros(2048,1,'uint8');
    dropCounter = -179;
end

t = t + 1;

% Parse generic ethernet header (everything in elements 1-28 is ETHERNET
% standard rather than BLACKROCK or Matlab standard).
srcPort = ByteSwap_EML(ethPkt(21:22),'uint16');
dstPort = ByteSwap_EML(ethPkt(23:24),'uint16');
ethPktDouble = double(ethPkt);
pktHeaderP(1:10) = ethPktDouble(31:40);

% Test values
if randSource==1
    stepPeriod=0.001;
    nSamples = size(neuralDataP,2);
    %background noise
    %neuralData = rand(size(neuralDataP)) - .5;
      neuralData = double([1:size(neuralDataP,1);3:size(neuralDataP,1)+2]'*1/100);
  
    %signal events
    eventAmplitude = 5;
    eventFreq = 80;                                             % event frequency in Hz
    eventDurationSec = 1;
    eventDurationSamples = 2000;
    eventSignal = eventAmplitude * sin(2*pi* eventFreq *(0:stepPeriod:eventDurationSec));
    eventPeriodSamples = 8 / stepPeriod;       % event occurs every 8 seconds (every other trigger)
    eventDelaySamples = 1 / stepPeriod;        % event occurs 1 sec after trigger
    eventFirstSamples =eventPeriodSamples*([1:nSamples]*1/eventPeriodSamples)+eventDelaySamples;
    tSignal = eventFirstSamples(1):eventFirstSamples(1)+eventDurationSamples;
    if ~isempty(find(tSignal==t))
        eventSignal1=eventSignal(1:2:end);
        eventSignal2=eventSignal(2:2:end);
        neuralData(3,1) = double(eventSignal1(t));
        neuralData(3,2) = double(eventSignal2(t));
    end
   % neuralData(3,:) = neuralData(1,:) * 10;
   % neuralData(4,:) = neuralData(1,:) * 5;
    %triggers
    neuralData(129,:) = zeros(1, nSamples);
    trigPeriodSamples = 4 / stepPeriod;
    %neuralData(129, trigPeriodSamples*(1:nSamples/trigPeriodSamples)) = 1;
    neuralData(129, 1) = mod(t,trigPeriodSamples)==0;
    pktHeader = ((pktHeaderP));
    spikeCounts = (spikeCountsP);
    spikeTimes = (spikeTimesP);
    nspTime = t;
    return

end

% We know that for Central 6.04 and above, we send from 51001-->51002
% In 6.03 and below, that is 1001 to 1002.
if srcPort(1) ~= 51001 || dstPort(1) ~= 51002;
    neuralData = neuralDataP;
    pktHeader = ((pktHeaderP));
    spikeCounts = (spikeCountsP);
    spikeTimes = (spikeTimesP);
    nspTime = 0;
    return
end

pktPrev = ethPkt;
pktCounter = pktCounter + 1;
% Now the timestamp comes from the Blackrock section of the packet
tsPkt = double(ByteSwap_EML(ethPkt(29:32),'uint32','none'));
tsDiff = tsPkt - tsPrev;
nspTime = tsPkt;

% Next we want to take a somewhat brute-force search approach through the
% remainder of the packet, looking for indicators of the BLACKROCK-specific
% (rather than Ethernet-specific) header, starting from element 30 (should
% this be 32 because the timestamp goes up to 32?)
searchMin = 30;
dataWidth = 2;
searchMax = length(ethPkt) - dataWidth;

searchInd = searchMin;
chInd = 1;

% By default, we are neither looking at a continuous packet nor a spike
% data packet
dataPktStarted = false;
spikePktStarted = false;

while searchInd < searchMax && chInd < chanMax
    % Increment the index
    searchInd = searchInd + 1;
    % If I'm in a data packet
    if dataPktStarted
        % If the channel index is weirdly high, I'm not in a data packet
        if chInd > (chanMax + 1)
            dataPktStarted = false;
            continue
        end
        %chIndUse = max(1,chInd - 1); % RIZ: changed to be able to test packets from file
        chIndUse = chInd - 1;
        
        % We assume everything looks like data, and we pull the next
        % available voltage sample into our output matrix
        % RIZ2018: Added conversion to double before scaling
        offsetInd = 1;
        channelData = ...
            cbScale * double(ByteSwap_EML(ethPkt((searchInd+offsetInd):(searchInd+offsetInd+(dataWidth-1))),'int16'));
        % idx = searchInd+offsetInd
        % byte1 = ethPkt(idx)
        % byte2 = ethPkt(idx+1)
        % val = byte2 << 8 | byte1
        
        
        % We assume, MAYBE DANGEROUSLY, that true data are never actually
        % zero (and therefore, again, not a packet)
        if isequal(channelData',[0 0])
            dataPktStarted = false;
            continue
        end
        if isValidData
            neuralDataP(chIndUse,tsPktUse) = channelData(1);
        end
        tsPktUse = tsPktUse+1;
        if tsPktUse > samplesPerStep
            tsPktUse = 1;
        end
        chInd = chInd + 1;
        searchInd = searchInd + dataWidth - 1;
       
    elseif spikePktStarted && parseSpikePackets
       % Some guesses about what the spike packet format looks like 
        chIndUse = chInd - 128 - 20;
        spikeCountsP(chIndUse) = spikeCountsP(chIndUse) + 1;
        searchInd = searchInd + 50;
        spikePktStarted = false;
        chInd = chInd - 1;
        continue
        
    else
        % We aren't in any kind of blackrock packet so far - we're out of
        % the ethernet header, but we don't recognize anything
        
        % We have pieced together that a blackrock packet should start with
        % a series of numbers that look like "[0 0 x]" where x is the
        % integer corresponding to the sampling rate in the NSx format
        
        % NOTE: we could in the future want to sample some things at 30k
        % and others at 2k, in which case we would see BOTH kinds of
        % packets
        if all(ethPktDouble((searchInd-1):(searchInd+1))' == [0 0 expectedType])
            chInd = 1;
            dataPktStarted = true;
            
            % Question for later: why don't we update the tsPkt if we think
            % there might be multiple Blackrock packets in an ethernet
            % packet?
            
            % Check that time is incrementing
            if tsPkt(1) >= tsPrev || ignoreTimestampsBool
                
                % If more than one step worth of time has passed, increment
                % the drop counter
                if tsDiff > 30000*modelRateSec && tsPrev > 0
                    dropCounter = dropCounter + tsDiff / (30000*modelRateSec);
                end
                tsPrev = tsPkt(1);

                isValidData = true;
                % This "header" has been co-opted to only serve a display
                % function -- maybe delete this -- it was only used for
                % debugging and is currently overwritten at the end of the
                % function
                for jj = 1:9
                    pktHeaderP(jj) = ethPktDouble((searchInd+2+jj));
                end
            else
                isValidData = false;
            end
        elseif parseSpikePackets && (ethPktDouble(searchInd) ~=0) && all(ethPktDouble(searchInd+1:searchInd+2) == [0; 0;])
            chInd = ethPktDouble(searchInd);
            spikePktStarted = true;

                tsPrev = tsPkt(1);
                isValidData = true;
                % This "header" has been co-opted to only serve a display
                % function -- maybe delete this
                for jj = 1:9
                    pktHeaderP(jj) = ethPktDouble((searchInd+jj-1));
                end
%                 
        end

    end
end
pktHeaderP(1:10) = 0;
pktHeaderP(1) = tsPkt / 30000;
pktHeaderP(2) = tsDiff;
pktHeaderP(3) = dropCounter;
pktHeader = pktHeaderP;
neuralData = neuralDataP;
spikeCounts = spikeCountsP;
spikeTimes = spikeTimesP;

end
