function [neuralData, pktHeader, nspTime] = PacketParserBlackRock_EML(ethPkt, clkTime)
% This function parses the UDP packet sent from BlackRock NSP
% It is  based on the persistent concepts of PacketParser_EML.m but considering the 
%specifications provided by BlackRock (see Note at the end)

persistent neuralDataP t
persistent tsPkt tsPrev tsPktUse
persistent dropCounter cfgNotDataPacketCounter otherSamplingDataPacketCounter
 

%% Configuration

% If the chid is 0x0000 we know it is a data packet
EXPECTED_CHID = hex2dec('0000');
% If the chid is 0x8000 we know it is a BR Configuration packet
EXPECTED_BR_CONFIG_CHID = hex2dec('8000');

% UDP Header is 28 bytes long
UDP_IP_HEADER_LEN = 28;
BR_HEADER_LEN =8; % length of BlackRock Data Packet header

% Blackrock packets are off by a factor of 4 in Central 6 and beyond
cbScale = .25; %0.25 corresponds to MaxAnalo / MaxDigital Values

% NSP property: packets will be one of these five rates 
samplesPerSec = [500 1000 2000 10000 30000];
EXPECTED_TYPE = 3; % sampling rate the data was acquired at (1 = 500, 2 = 1k, 3 = 2k.... 5=30k, 6= 30k raw)

% These parameters tell us how many samples per step; must match the expectations from the sCoreParam struct.
modelRateSec = .001;
samplesPerStep = samplesPerSec(EXPECTED_TYPE) * modelRateSec;
chanMax = 200;

% Maximum expected time between timestamps - 
maxExpectedInterTimeStamp = max(samplesPerSec)/samplesPerSec(EXPECTED_TYPE);

%% Initialize persistent variables
if isempty(neuralDataP)|| clkTime<0.2
    t = 0;
    neuralDataP = zeros(chanMax,samplesPerStep);
    tsPkt =0;
    tsPrev = 0;
    tsPktUse = 1;
    dropCounter = 0;
    cfgNotDataPacketCounter = 0;
    otherSamplingDataPacketCounter = 0;
end

t = t + 1;
pktHeader = zeros(13,1); % pktHeader contains last BR header + dropCounter + cfgNotDataPacketCounter + t
BRHeaderData= zeros(BR_HEADER_LEN,1);

%% Read Ethernet Packet
% 1. Parse generic ethernet header (everything in elements 1-28 is ETHERNET standard rather than BLACKROCK or Matlab standard).
ethPkt=ethPkt(:);
ethPktDouble = double(ethPkt);

UDPHeader = getUDPHeader(ethPkt, UDP_IP_HEADER_LEN);
udpLen = decodeUDPIPHeader(UDPHeader);
payload = getPayload(ethPkt, UDP_IP_HEADER_LEN);


% Following the Ethernet packet there are an unspecified number of BR data packets
idx=1; % fisrt BR data packect starts after UDP packet
foundNonDataPacket= 0; % Assumes that config packets are at the end of UDPpackets (there are NO data packets following within that UDP packet)
while all(idx < udpLen) && foundNonDataPacket==0
    % Decode 1 BR paket at the time
    
    % 2. The blackrock packets have the following header:
    %    UINT32 time;           UINT16 chid;           UINT8 type;          UINT8 dlen;
    BRHeader = getBRHeader(payload, BR_HEADER_LEN); % Assign Whole BR Header -to keep only header corresponding to data
    [timeStamp, chid, type, dlen, idx] = decodeBRHeader(payload, idx);
    
    % 3. Process BR data
    if  all(chid == EXPECTED_CHID) && all(type == EXPECTED_TYPE)
        tsPkt = timeStamp; % Assign Header timestamp as NSPtime
        BRHeaderData = BRHeader;
        
        % 3. get Data Values for each channel
        % if the chid is 0x0000 and type=3 (2kHz)we know it is a data packet
         % Each 32 bit chunk contains two 16 bit raw analog values. There are dlen 32bit chuncks of data
         nChannels = ceil(dlen*2);
         dataDoublePerCh = zeros(nChannels, 1);
         for iCh=1:nChannels
             [dataDouble, idx] = extractDoubleInt16(payload, idx);
             %dataDouble = double(typecast(uint8(ethPkt(indFirstDataInUDP+iCh-1:indFirstDataInUDP+iCh)),'int16'));
             dataDoublePerCh(iCh,1) = cbScale * dataDouble(1);       % it is only size 1x1 but it was giving a size error on compilation  
                
        %     disp([' Ch', num2str(iCh),' :', num2str(dataDouble)]);
         end

         % 4. Assign channel Values to output signal and Increment sample point (we need 2 samplesbecause Simulink is set at 1ms)
         if tsPkt > tsPrev % only move to next sample if timestamp increased
             % Assign Channel values
             neuralDataP(1:nChannels, tsPktUse) = dataDoublePerCh;
             % move to the other timepoint
             tsPktUse = tsPktUse+1;
             if tsPktUse > samplesPerStep
                 tsPktUse = 1;
             end
             
             tsDiff = tsPkt - tsPrev;
             
             % Check for lost packets
             if all(tsDiff> maxExpectedInterTimeStamp) && all(tsPrev > 0)
                 dropCounter = dropCounter +1;
             end
         end
         % 5. Assign current values to prev
         tsPrev = tsPkt(1);
         % disp(['DATA packet: ',num2str(timeStamp)])
        
    elseif all(chid == EXPECTED_CHID) && all(type ~= EXPECTED_TYPE)
        % if it is a different sampling rate
        % We just ignore this everything that is not at 2kHz
        % but keep a counter

        otherSamplingDataPacketCounter =otherSamplingDataPacketCounter +1; % Count not data packets ( config packets)
        idx = idx + max(dlen*4,1); %dlen tell how many 32 bits chunks there were in this data packet
        foundNonDataPacket = 1; % Exit UDP packet after config

    elseif chid == EXPECTED_BR_CONFIG_CHID
        % if it is a configuration packet we can read the channel list
        % RIZ: Add in the FUTURE?
        % for now just advance
       % disp(['Config packet: ',num2str(timeStamp)])
        cfgNotDataPacketCounter =cfgNotDataPacketCounter +1; % Count not data packets ( config packets)
        % 6.  Advance index to get next data Packet on next iteration
        idx = idx + max(dlen*4,1); %udpLen; % Exit UDP packet after config- config packets seem to be at the end of UDP packets - idx + max(dlen*4,1); %dlen tell how many 32 bits chunks there were in this data packet
        foundNonDataPacket = 1; % Exit UDP packet after config
    else
        % if it is not a data packet - skip this BR packet (add dlen to go to the next BR packet)
        cfgNotDataPacketCounter =cfgNotDataPacketCounter +1; % Count not data packets (could be config packets)
        % 6.  Advance index to get next data Packet on next iteration
        idx = idx + max(dlen*4,1); %udpLen; % Exit UDP packet after config- config packets seem to be at the end of UDP packets - idx + max(dlen*4,1); %dlen tell how many 32 bits chunks there were in this data packet
        foundNonDataPacket = 1; % Exit UDP packet after config
    end    

end

nspTime = tsPkt; % there might be more timestamps if within an UDP packet there are multiple BR packets...
neuralData = neuralDataP;
pktHeader(1:8) = BRHeaderData;
pktHeader(9) = tsPkt;
pktHeader(10) = cfgNotDataPacketCounter;
pktHeader(11) = dropCounter;
pktHeader(12) = otherSamplingDataPacketCounter;
pktHeader(13) = t;

end


function [timeStamp, chid, type, dlen, idx] = decodeBRHeader(payload, idx)
    % Decode BR Header
    %    UINT32 time;           UINT16 chid;           UINT8 type;          UINT8 dlen;
    [timeStampUInt32, idx] = extractUInt32(payload, idx);
    timeStamp = double(timeStampUInt32);
    [chid, idx] = extractUInt16(payload, idx);
    [type, idx] = extractUInt8(payload, idx);
    [dlenUInt8, idx] = extractUInt8(payload, idx);
    dlen = double(dlenUInt8);

%         disp([' timeStamp: ', num2str(timeStamp)]); 
%         disp([' chid: ', num2str(chid)]);
%         disp([' type: ', num2str(type)]); 
%         disp([' dlen: ', num2str(dlen)]); 
    
end



function udpLen = decodeUDPIPHeader(ethPkt)
% Decode IP/UDP header -> we have to change Endianess - from Network (Big Endian) to Little Endian
    idx=1;
    [versionIP, idx] = extractUInt8(ethPkt, idx);
    [dscpEcn, idx] = extractUInt8(ethPkt, idx);
    [totalLength, idx] = extractUInt16LE(ethPkt, idx);
    [flagFragment, idx] = extractUInt16LE(ethPkt, idx);
    [id, idx] = extractUInt16(ethPkt, idx); %% WHY!!??
    [ttl, idx] = extractUInt8(ethPkt, idx);
    [proto, idx] = extractUInt8(ethPkt, idx);
    [headerCheckSum, idx] = extractUInt16LE(ethPkt, idx);
    % Get Source and Destination IP/port
    srcIP=zeros(1,4);
    for i=1:4
        [srcIP(i), idx] = extractUInt8(ethPkt, idx);
    end
    destIP=zeros(1,4);
    for i=1:4
        [destIP(i), idx] = extractUInt8(ethPkt, idx);
    end
    [srcPort, idx] = extractUInt16LE(ethPkt, idx);
    [destPort, idx] = extractUInt16LE(ethPkt, idx);
    [udpLenUInt, idx] = extractUInt16LE(ethPkt, idx);
    udpLen = double(udpLenUInt);
    [checksum, idx] = extractUInt16LE(ethPkt, idx);
       
    
%         disp([' IP version: ', num2str(versionIP), ' Total Length: ', num2str(totalLength)]); 
%         disp([' IP Protocol: ', num2str(proto)]);
%         disp([' Src (ip:port) ', num2str(srcIP(1)),'.',num2str(srcIP(2)),'.',num2str(srcIP(3)),'.',num2str(srcIP(4)),' : ',num2str(srcPort)]);
%         disp([' Dest (ip:port) ', num2str(destIP(1)),'.',num2str(destIP(2)),'.',num2str(destIP(3)),'.',num2str(destIP(4)),' : ',num2str(destPort)]);
    

% %srcPort = ByteSwap_EML(ethPkt(21:22),'uint16'); % UDP Source Port -> it should be the same as swapbyte(typecast(ethPkt(21:22),'uint16')
% srcPort = swapbytes(typecast(uint8(ethPkt(21:22)),'uint16'));
% %dstPort = ByteSwap_EML(ethPkt(23:24),'uint16'); % UDP Destination Port
% dstPort = swapbytes(typecast(uint8(ethPkt(23:24)),'uint16'));

% We know that for Central 6.04 and above, we send from 51001-->51002 ( In 6.03 and below, that is 1001 to 1002).
% RZ:REMOVE? -  We know is an UDP packet - just read the content!
% if srcPort(1) ~= 51001 || dstPort(1) ~= 51002
%     neuralData = neuralDataP;
%     nspTime = 0;
%     return
% end

end

function UDPHeader = getUDPHeader(ethPkt, UDP_IP_HEADER_LEN)
    % Rerun UDP/IP header
    UDPHeader = ethPkt(1:UDP_IP_HEADER_LEN);
end

function payload = getPayload(ethPkt, UDP_IP_HEADER_LEN)
    % Rerun UDP/IP header
    payload = ethPkt(UDP_IP_HEADER_LEN+1:end);
end

function BRHeader = getBRHeader(dataPacket, BR_HEADER_LEN)
    % Rerun UDP/IP header
    BRHeader = double(dataPacket(1:BR_HEADER_LEN));
end

function [dOut, idx] = extractUInt8(dataPacket, idx)
    % Decode a uint8 return a tuple having the decode value and new index in data 
    dOut = uint8(dataPacket(idx));
    idx = idx + 1;
end

function [dOut, idx] = extractUInt16(dataPacket, idx)
    % Decode a uint16 return a tuple having the decode value and new index in data 
    dOut = typecast(uint8(dataPacket(idx:idx+1)),'uint16');
    idx = idx + 2;
end

function [dOut, idx] = extractUInt16LE(dataPacket, idx)
    % Decode a uint16 Little Endian return a tuple having the decode value and new index in data 
    %dOut = swapbytes(typecast(uint8(dataPacket(idx:idx+1)),'uint16')); %Removed swapbytes because it was giving a compiling error on Simulink Real-Time
    ui8Data = uint8(dataPacket(idx:idx+1));
    dOut = typecast(flipud(ui8Data(:)),'uint16');
    idx = idx + 2;
end

function [dOut, idx] = extractUInt32(dataPacket, idx)
    % Decode a uint32 return a tuple having the decode value and new index in data 
    dOut = typecast(uint8(dataPacket(idx:idx+3)),'uint32');
    idx = idx + 4;
end

function [dOut, idx] = extractInt16(dataPacket, idx)
    % Decode a uint16 return a tuple having the decode value and new index in data 
    dOut = typecast(uint8(dataPacket(idx:idx+1)),'int16');
    idx = idx + 2;
end

function [dOut, idx] = extractDoubleInt16(dataPacket, idx)
    % Decode a uint16 and convert to Double
    [dOutUInt16, idx] = extractInt16(dataPacket, idx);
    dOut = double(dOutUInt16);
end


%% Note From BlackRock on how to create this script
% At the start of the UDP packet there is a 28 value header. You have this correctly identified and handled. 
% 
% Following the UDP header you have an unspecified number of blackrock packets of unspecified types. 
% 
% Regardless of the type, the blackrock packets have the following header:
%     UINT32 time;           UINT16 chid;           UINT8 type;          UINT8 dlen;     
% 
% Some notes here
% 
% 1. Each BR packet will contain its own timestamp, so there is more than just one after the end of the Ethernet header. You should use it to stay locked with the timestamp from the NSP. 
% 
% 2. Every BR packet will have the same header followed by data of length dlen. 
% 
% 3. chid and type will allow you to determine the type of packet that follows the header. If the packet is not of the desired type, you can skip ahead by dlen to arrive at the header of the next BR packet. 
% 
% So in practice, if we are just looking for continuous data sampled at 2k, we would check the chid of the first BR packet at byte 33/34. if the chid is 0x0000 we know it is a data packet. We now can check the type at byte 35 and see what sampling rate the data was acquired at (1 = 500, 2 = 1k, 3 = 2k.... 5=30k, 6= 30k raw)
% If the chid is 3, we know there is 2k data in the packet. We then look at dlen in byte 36 which tells us how many 32 bit chunck of data there are in the packet. Each 32 bit chunk contains two 16 bit raw analog values. If there are an odd number of channels sampled at this rate, the last chunk will contain 16 bits of zero value at the end. 
% 
% After advancing through by dlen, the next data in the UDP packet will be the time stamp of the next blackrock packet header, again followed by the chid, type, and dlen which we can check. If we identify a different chid, such as 0x8000 for a configuration packet, then we can skip the data contained by checking dlen and skipping that many bytes of data to arrive at the next br packet header. 
% 
% 
% If your channel configuration remains the same all the time, this will be sufficient. However, you may want to read the groupinfo packets which are sent when recording starts or configurations are changed, and contains the sampling group, rate, period (all measures of the sampling rate) and the number of each channel sampled at that rate. The data coming in group packets is listed in the same order as the channel numbers in the list. 
% The packet will begin with a timestamp, as always, then a chid of 0x8000, and then a type of 0x30 for cbPKTTYPE_GROUPREP (group info reply from NSP)
% 
% Similarly to reading analog data, you want to then move to the start of the next header. 
% 
% 
% Your script is searching for the type value expected for data at your sampling rate, and this definitely works, though I worry it may be leading to some of the issues you are experiencing since it does not take into account the nature of the br packet headers and data at multiple sampling rates. 


% Each BR group data packet will contain one data point for each channel enabled at that particular sampling rate. They will go in order, and each sample will be 16 bits. dlen will equal number of channels / 2 because dlen is the number of 32 bit chucks, each containing two 16 bit values. If an odd number of channels are enabled, then the last channel sample will be in the first 16 bits of the last 32 bit chunk, and the remaining 16 bits will be random. 
% 
%  Each BR group data packet should have incrementing time stamps and this time stamp is universal across all sampling rates. 30k data will increment by 1 timestmap each sample, while 1k data will increment by 30 time stamps. 
% 
%  The entire BR section should be in Big- Endian. You should be able to easily confirm if the time stamps are incrementing or not. The continuous data will be harder to check, but if you can feed in sine wave it should also be possible to verify. 
% 
