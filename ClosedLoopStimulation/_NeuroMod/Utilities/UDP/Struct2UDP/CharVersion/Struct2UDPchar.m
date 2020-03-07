function Struct2UDPchar(S, socket_h, Sname)

% *** Using all string conversions we will lose numberical precision on
% double!!!!!!! IDIOT!
%  no idea how to deal with this yet
%
% Might want to pack everything up as doubles and conver def portion back
% to strings!!!!!

% Struct2UDP
%
% Description:
%
% INPUTS:
%
% created by Dan Bacher 2013.03.19

% get name of struct passed into fcn
if nargin < 3
    Sname = inputname(1);
end

evalin('base','stat=[];');

% send a start packet
startStr = '[Struct2UDP] Start';
SendUDP(socket_h,startStr);
disp(startStr);

% call recursive Struct2UDPrec function
Struct2UDPrec(S, socket_h, Sname);

% send a stop packet
stopStr = '[Struct2UDP] Stop';
SendUDP(socket_h,stopStr);
disp(stopStr);