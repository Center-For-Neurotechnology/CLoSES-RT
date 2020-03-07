function packetArray = BuildDoublePacket(varName, varVal)

% packet = BuildDoublePacket(varName, varVal)
%   Called exclusively from Struct2UDPrec
%
% Description:
%   Take in the parameter name (string) and values (any data type) and
%   builds a standard Struct2UDP packet out of it.  This includes appending
%   a header to instruct the receive end how to parse the number of packet
%   fragments per param (i.e. if param needs to split into multiple
%   packets), format, type, variable name and values data.
%
% INPUTS
%   varName: generically a variable name (string), more specifically a
%       structure field name (e.g. 'sSLC.features.spikeRate.enableComputeSave')
%   varVal: variable holding the values of the parameter (any data type)
%
% OUTPUT
%   packetArray:
%       cell array of formatted, header appended packet ready 
%           to get sent via UDP
%       All elements are converted to doubles
%       See comments below for format of this packet
%   
% created by Dan Bacher 2013.03.19


% packet definition:
%
% [ID 
% multiPacket
% formatLength 
% typeLength 
% varNameLength 
% valuesLength
%
% format
% type 
% varName 
% values]'
%   All in a row vector of doubles after packaging

% Struct2UDP packet ID:
ID = 44; % this should also be hard-coded on receive end
    
% max single packet length
MAX_PACKET_LENGTH = 1400;

% var size
sizeVar = size(varVal);
    
% define format, type, and values derived from varVal

% handle different data formats:
% cell array
    % build header of lengths of each cell array element
    % concat all data together
if iscell(varVal)
    formatCell = 'cell';
    type_s = class(varVal{1,1}); % for now assuming same data type in each cell
                                     % TO DO (check and flag if not)
    cellLengths = [];
    cellVals = [];
    for i = 1:length(varVal)
        cellLengths = [cellLengths length(varVal{i})];
        cellVals = [cellVals varVal{i}];
            % TO DO check all singular format!
    end
    cellLengths_s = num2str(cellLengths); % convert to string as part of header
    format_s = [formatCell cellLengths_s];
    values = cellVals;
    
% column vectors
    % flip to horizontal
elseif sizeVar(1) > 1 && sizeVar(2) == 1
    format_s = 'colVec';
    type_s = class(varVal);
    values = varVal';
    
% 2D matrices
elseif sizeVar(1) > 1 && sizeVar(2) > 1
    format_s = ['mat' num2str(sizeVar)];
    type_s = class(varVal);
    values = reshape(varVal,1,sizeVar(1)*sizeVar(2));
   
% other (char/string, single values, row vectors)
else
    format_s = 'default';
    type_s = class(varVal);
    values = varVal;
end
   
% TO DO add "other you fucked up" case

% start/stop packet special cases!
if strcmp(varName,'start') || strcmp(varName,'stop')
    format_s = varName;    
end
    

% header lengths
formatLength = length(format_s);
typeLength = length(type_s);
varNameLength = length(varName);
valuesLength = length(values);

% convert header strings to doubles
format_d = double(uint8(format_s));
type_d = double(uint8(type_s));
varName_d = double(uint8(varName));

% if values are already double don't convert, else convert
if strcmp(type_s,'double')
    values_d = values;
else
    values_d = double(uint8(values));
end

% break up data into multiple packets if param is too large
numPackets = ceil(length(values_d)/MAX_PACKET_LENGTH);

% fill cell array with chopped up packets
%   - this will be a single packet 95% of the time, but keep this generic
%   format in place
packetArray = cell(1,numPackets);
for i = 1:numPackets
    multiPacket = double([i numPackets]); % this is packet "i" out of "numPackets"
    
    startValInds = (i-1)*MAX_PACKET_LENGTH+1; % starting index
    stopValInds = min(length(values_d), i*MAX_PACKET_LENGTH); % stop index         
    valuesPack = values_d(startValInds:stopValInds); % select inds
     
    % update values length header value
    valuesLength = double(length(valuesPack));    
    
    % build multiple packets of all doubles
    packetArray{i} = [ID multiPacket formatLength typeLength ...
            varNameLength valuesLength ...
            format_d type_d varName_d valuesPack];
end
    
        

        