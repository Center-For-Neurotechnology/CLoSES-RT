function Struct2UDPrecChar(S,socket_h, Sname)

% Struct2UDPrec
%
% Description:
% 
% INPUTS:
%   S: Structure to send via UDP
%   Sname: structure name passed recursively to fcn 
%   socket_h: pnet socket handle
%
% created by Dan Bacher 2013.03.06

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
        
        % recursively call Struct2Vars
        Struct2UDPrecChar(newS,socket_h,newSname);             
    end
else
    % if input not a structure, define the variable ...
    % and put it in the base workspace
    varName = Sname;        
    sizeS = size(S);        
    
    % cell arrays
        % convert each element to string, and make it something like this:
        % [Cell][1]valueElement1[2]valueElement2 ...
    if iscell(S)
        cellValStr = '[cell]';
        for i = 1:length(S)
            cellValStr = [cellValStr '[' num2str(i) ']' S{i}]; 
        end
        valStr = cellValStr;
        
    % column vectors
    elseif sizeS(1) > 1 && sizeS(2) == 1
        St = S';
        headerStr = '[colVec]';
        valStr = [headerStr num2str(St)];
    % 2D matrices
        % [mat][dim1 dim2]val1 val2 val3
    elseif sizeS(1) > 1 && sizeS(2) > 1    
        Sm = reshape(S,1,sizeS(1)*sizeS(2));
        headerStr = ['[mat][' num2str(sizeS) ']'];
        valStr = [headerStr num2str(Sm)]; 
        keyboard
    % strings
    elseif isstr(S)
        headerStr = '[str]';
        valStr = [headerStr S]; 
    % constants or row vectors
    else
        valStr = num2str(S);
    end
    
    try
        sendStr = [varName '=' valStr];
    catch
        keyboard
    end
    disp(sendStr);    
    if length(sendStr) < 1400
        SendUDP(socket_h,sendStr);
    end
    status = pnet(socket_h,'status');  
    %pause(.001);
end



% EOF