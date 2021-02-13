function Struct2UDPrec(S,socket_h, Sname)

% Struct2UDPrec(S,socket_h, Sname)
%   Called exclusively from Struct2UDP.m
%
% Description:
%   Recursive function call that digs into struct fields, packs up the
%   field names and values (by calling BuildDoublePacket), and sends out
%   the packets for each field via socket_h (pnet socket).
% 
% INPUTS:
%   S: Structure to send via UDP
%   socket_h: pnet socket handle
%   Sname: structure name passed recursively to fcn 
%
% created by Dan Bacher 2013.03.19

% recursively dig into structure and send var definition string via UDP for
% each param
if isstruct(S)
    % if input is a struct, keep digging into the fields
    f = fieldnames(S); 
    for i = 1:length(f) 
        % create new struct with fields in f
        newSname = [Sname '.' f{i}]; 
        eval([Sname '= S;']); 
        newS = eval(newSname); 
        
        % recursively call self
        Struct2UDPrec(newS,socket_h,newSname);             
    end
else
    % process param def and value pair and send param via UDP
    varName = Sname;        
    varVal = S;
    %disp(varName);
    
    % create packet array out of variable name and value
    packetArray = BuildDoublePacket(varName, varVal);    
    
    
    % send field packet via pnet UDP
    try
        % loop through packet cell array and send each as own packet
        for i = 1:length(packetArray)
            SendUDP(socket_h,packetArray{i});               
        end              
        
    catch
        % keeping this catch in here just for testing
        keyboard;
    end
end



% EOF