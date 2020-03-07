function [data packetSize] = ReceiveUDP(socket, mode, dtype)
% mode is either
%   'latest' gets the most recent UDP packet in buffer and discards the 
%            older ones.
%   'all'    gets all UDP packets from the buffer.
%   'next'   gets the next UDP packet in buffer.

%
% CHANGES MADE 2012.10.05 to ensure XCORE / 64 Bit Compatibility
%
%   set readtimeout to 0
%   made sure no calls happen on an empty buffer
if nargin < 3
    dtype='double';
end

data=[];
pnet(socket,'setreadtimeout',0);
switch mode
    case 'latest'
        steps = 0;
        packetSize = pnet(socket,'readpacket'); % Check for packet
        prevData = [];
        while  packetSize > 0 ;
            prevData = data;
            steps = steps + 1;
            data = pnet(socket,'read',packetSize,dtype,'intel');
            packetSize = pnet(socket,'readpacket');
        end
        if isempty(data)
            data = prevData;
        end
    case 'all'      % Collects all packets from the last call
        steps = 0;
        packetSize = pnet(socket,'readpacket');        
        while  packetSize ;
            steps = steps + 1;
            data{steps} = pnet(socket,'read',packetSize,dtype,'intel');
            packetSize = pnet(socket,'readpacket') ;
        end
        if ~isempty(data) && isempty(data{steps})
            if (steps == 1)
                data = [];
            else
                data = data(1:steps-1);
            end
        end

    case 'next'
        packetSize = pnet(socket,'readpacket');        
        data = pnet(socket,'read',packetSize,dtype,'intel');
    otherwise
        error(['' mode ' is not a valid ReceiveUDP mode argument'])
end
