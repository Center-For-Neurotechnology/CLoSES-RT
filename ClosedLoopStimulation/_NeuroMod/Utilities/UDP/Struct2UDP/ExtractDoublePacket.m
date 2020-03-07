function [varName, varVal] = ExtractDoublePacket(packet, socket_h)

% [varName, varVal] = ExtractUDPpacket(packet)
%
% Extract variable name and values from encoded packet
%

% packet definition: (should agree with BuildDoublePacket.m)
% [ID multiPacket formatLength typeLength varNameLength valuesLength ...
    % format, type, varName, values]

% hard-coded params
ID = 44;
headerSize = 7;     
    
% check if packet is empty
if isempty(packet)
    varName = 'null';
    varVal = [];
    disp('[ExtractDoublepacket]: empty packet');
    return;
end
    
% are we sure this is a Struct2UDP packet? Check ID
if packet(1) ~= ID
    varName = 'null';
    varval = [];
    disp('[ExtractDoublepacket]: not a Struct2UDP packet. How did we get in here?');
    return;
end
    
% extract multi-packet from header
%   (i.e. how many packets was this single parameter broken into)
%   [currentPacket totalNumPackets]
currPacket = packet(2);
numPackets = packet(3);

% extract segment indices of packet
formatInds = headerSize+1:headerSize + packet(4);
typeInds = headerSize + packet(4)+1:headerSize + sum(packet(4:5));
varNameInds = headerSize + sum(packet(4:5))+1:headerSize + sum(packet(4:6));
valuesInds = headerSize + sum(packet(4:6))+1:headerSize + sum(packet(4:7));

% extract packet segments
format_d = packet(formatInds);
type_d = packet(typeInds);
varName_d = packet(varNameInds);
values_d = packet(valuesInds);

% convert everything but values to their original string (char)
% representation
format_s = char(format_d);
type_s = char(type_d);
varName = char(varName_d); % implicitly a string/char

% start/stop packet check
if strcmp(format_s,'start') || strcmp(format_s,'stop')
    varVal = [];
    return;
end

% if this parameter was broken into multiple packets, loop through them
% here and build the single parameter values vector
if numPackets > 1 && currPacket == 1
    valuesCat = values_d; % init values vector to concat more data onto
    for i = 2:numPackets % we already have packet 1
        
        packet = ReceiveUDP(socket_h,'next'); % read next packet
        
        if isempty(packet)
            disp('[ExtractDoublePacket]: can not read all multiPackets, what the fuck happened?');
            varName = 'null';
            varVal = [];
            return;
        end
            
        % check the multiPacket header just in case
        currPacketCheck = packet(2);
        if currPacketCheck ~= i
            disp('[ExtractDoublePacket]: multiPacket screwed up, current packet is the wrong index');
        end
        numPacketsCheck = packet(3);   
        if numPacketsCheck ~= numPackets
            disp('[ExtractDoublePacket]: multiPacket screwed up, total num packets is wrong');
        end
        
        % extract inds and values from new packet
        %   the rest of the header is the same
        valuesInds = headerSize + sum(packet(4:6))+1:headerSize + sum(packet(4:7));
        values_d = packet(valuesInds);
        
        % concatonate to super vector of values
        valuesCat = [valuesCat values_d];
                
    end %i     
        
    % not the cleanest way of doing this, but put concat values back into
    % values_d for consistency below
    values_d = valuesCat;
    
end %numPackets

% process values_d based on format and type
%   handle special cases as well

% cell arrays
if strncmp(format_s,'cell',4)
    % extract length of each cell array element
    cellLengths_s = format_s(5:end);
    cellLengths = str2num(cellLengths_s);
    tempValues = cell(1,length(cellLengths));
    % loop through values vector and fill up cell array
    %   index into values vector with cumulative cellLengths 
    startInd = 1;
    for i = 1:length(cellLengths)
        cellVal = values_d(startInd:startInd+cellLengths(i)-1);
        startInd = startInd+cellLengths(i);
        tempValues{i} = cast(cellVal, type_s);
    end
    varVal = tempValues;
    
% column vectors    
elseif strcmp(format_s,'colVec')
    tempValues = values_d'; % transpose back to column vector
    varVal = cast(tempValues, type_s);
    
% 2D matrices
elseif strncmp(format_s,'mat',3)
    % extract original size of matrix and reshape
    sizeVar_s = format_s(4:end);
    sizeVar = str2num(sizeVar_s);
    tempValues = reshape(values_d,sizeVar(1),sizeVar(2));
    varVal = cast(tempValues, type_s);
    
% default (char/string, single values, row vectors)
else
    varVal = cast(values_d, type_s);
end
