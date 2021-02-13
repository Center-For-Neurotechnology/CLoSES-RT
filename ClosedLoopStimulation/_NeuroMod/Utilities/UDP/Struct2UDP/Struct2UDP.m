function Struct2UDP(S, socket_h)

% Struct2UDP(S, socket_h)
%
% Description:
%   Sends an arbitrary structure to another agent via UDP.
%
%   A recursive function is used to dig into the structure fields to send
%   each field (name and value) as an isolated UDP packet.
%   A header is added to each packet to indicate that this is a Struct2UDP
%   packet type (ID = 44), the format of the packet (e.g. array or matrix),
%   and the data type of the elements.  Before sending the data via UDP the
%   variable values must be reshaped and converted to doubles.  All strings
%   in the header are also converted to doubles.
%
% INPUTS:
%   S: the structure to be sent 
%       The struct can have any hierchical structure
%       Formats currently supported: 
%           - single values, vectors, 2D matrices, 1D cell arrays
%           - can be of any standard matlab datatype
%           - currently cell array elements must be all same data type
%   socket_h: the pnet UDP socket to send the structure across
%
% created by Dan Bacher 2013.03.19

% get name of struct passed into fcn
Sname = inputname(1);

% before sending structure, make sure it isn't too big! (that's what she
% said)
MAX_STRUCT_SIZE = 64; % max pnet memory limit (MB)
s_who = whos('S');
structSize = s_who.bytes/1024/1024;
if structSize >= MAX_STRUCT_SIZE
    keyboard
    disp('[Struct2UDP]: Your structure is just too damn big.  Ain''t got no time for that... Aborting'); %IDIOTS (ain't nobody got time)
    return;
end

% components to a packet:
% header, format, type, varName, values

% send a UDP2Struct trigger packet
%   when trigger packet is received in receive timer 
%   it will trigger the UDP2Struct function call
triggerPacket = BuildDoublePacket('trigger','true');
SendUDP(socket_h,triggerPacket{1});
disp('[Struct2UDP]: trigger');

% send a start packet
%   indicates the start of a sequence of parameter name, value packets
startPacket = BuildDoublePacket('start','true');
SendUDP(socket_h,startPacket{1});
disp('[Struct2UDP]: start');

% call recursive Struct2UDPrec function
%   recursively digs into struct to send individual field name and values
%   via UDP
Struct2UDPrec(S, socket_h, Sname);

% send a stop packet
%   tells receiver this batch of parameter packets are done
stopPacket = BuildDoublePacket('stop','true');
SendUDP(socket_h,stopPacket{1});
disp('[Struct2UDP]: stop');