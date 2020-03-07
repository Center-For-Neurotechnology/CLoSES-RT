function S = UDP2StructChar(socket_h)

% UDP2Struct
%
% Description:
%
% INPUTS:
%
% created by Dan Bacher 2013.03.19

% special headers
specialHeaders = {'[cell]' '[colVec]' '[mat]'}; 
dataArray = cell(1,1);
n = 0; % counter
P = [];
% read off all packets off of network card
%   find start packet
collectPackets = false;
while 1
    [data, packetSize] = ReceiveUDP(socket_h,'next','char');
    P = [P packetSize];
    status = pnet(socket_h,'status');
    if status ~= 6
        keyboard;
    end
    if isempty(data)
        disp('[UDP2Struct]: No UDP Struct param data is there, IDIOT!');
        keyboard
        S = [];
        return;
    else
        if strcmp(data,'[Struct2UDP] Start')
            disp('[UDP2Struct]: Start packet received');
            collectPackets = true;                                
        end
        
        if collectPackets
            n = n + 1;
            dataArray{n} = data;
            
            if strcmp(data,'[Struct2UDP] Stop')
                disp('[UDP2Struct]: Received stop packet. Parsing param structure...');
                break;
            end            
        end        
    end
end

%keyboard

% *** sender may have sent 2 or more of them, and we always want the most recent.
% So the strategy might have to be to collect all packets into a cell array
% and then find the LAST start packet, and have code below loop through the
% cell array

% extract all params until hit stop packet
for i = 1:length(dataArray)
    
    % churn through packets
    %data = ReceiveUDP(socket_h,'next','char');
    data = dataArray{i};
    disp(data);
    
    specialCase = false;
    varVal = 0; % re-cast as double (cast as cell in cell case)
    
    % hope this doesn't happen
    if isempty(data)
        disp('[UDP2Struct]: Empty packet? Are you serious, IDIOT?');
        %S = [];
        %return;
        keyboard
        specialCase = true;
    end
    
    % check for stop packet
    if strcmp(data,'[Struct2UDP] Stop')
        % what is the name of the struct?
            % name of def string up to the first field '.'
        firstDot = strfind(defStr,'.');
        structName = defStr(1:firstDot-1);
        
        % set output
        eval(['S = ' structName ';']);
        
        disp('[UDP2Struct]: Done extracting params');
        return;
    end

    % parse input strings only if special case
    %   otherwise just evaluate the string    
    
    
    % SPECIAL CASES
       
    %  cell arrays 
    % [Cell][1]valueElement1[2]valueElement2 ...
    cellStr = '[cell]';
    cellInd = strfind(data,cellStr);
    if cellInd
        specialCase = true;
        defStr = data(1:cellInd-1);
        
        cellVarStr = data(cellInd+length(cellStr):end);
        c = 0;
        varVal = cell(1,1);
        while true
            c = c + 1;
            valTagStr1 = ['[' num2str(c) ']'];
            valTagStr2 = ['[' num2str(c+1) ']'];
            valInd1 = strfind(cellVarStr,valTagStr1);
            valInd2 = strfind(cellVarStr,valTagStr2);
            
            % if both tags exist, it means there's a valid value in between
            % tags and that we should keep going in the loop
            if ~isempty(valInd1) && ~isempty(valInd2)
                tempVarStr = cellVarStr(valInd1+length(valTagStr1):valInd2-1);
                varVal{c} = tempVarStr;
            % if only have first tag, it means we are at the end.
            %   define this one and break out of loop
            elseif ~isempty(valInd1) && isempty(valInd2)
                tempVarStr = cellVarStr(valInd1+length(valTagStr1):end);
                varVal{c} = tempVarStr;
                break;
            end
            
        end % while
               
    end % cell arrays

    %  col vectors
    colStr = '[colVec]';
    colInd = strfind(data,colStr);
    if colInd
        specialCase = true;
        defStr = data(1:colInd-1);
        varStr = data(colInd+length(colStr):end);
        varVal = str2num(varStr);
        varVal = varVal'; % turn back into row vector        
    end

    %  matrices
    % [mat][dim1 dim2]val1 val2 val3
    matStr = '[mat]';
    matInd = strfind(data,matStr);
    if matInd
        specialCase = true;
        defStr = data(1:matInd-1);
                
        % find out size of matrix, i.e. extract [dim1 dim2]
        matSizeStrIndStart = matInd+length(matStr)+1;
        matSizeStrIndEnd = find(data(matSizeStrIndStart+1:end) == ']',1,'last')-1;
        matSizeStr = ...
            data(matSizeStrIndStart:matSizeStrIndStart+matSizeStrIndEnd);
        matSize = str2num(matSizeStr);
        
        % extract data out of string
        varVecStr = data(matSizeStrIndStart+matSizeStrIndEnd+2:end);
        varVec = str2num(varVecStr);
        
        % reshape into it's original matrix using size
        varVal = reshape(varVec,matSize(1),matSize(2));
        
        
    end
    
    % strings
    strStr = '[str]';
    strInd = strfind(data,strStr);
    if strInd
        specialCase = true;
        defStr = data(1:strInd-1);
        varStr = data(strInd+length(strStr):end);
        varVal = varStr;
    end
    
    % empties
    if ~isempty(data) && data(end) == '='
        specialCase = true;       
        defStr = data;     
        varVal = [];
    end
    
    %  default (constants or numeric row vectors)
    if ~specialCase       
        equalInd = strfind(data,'=');
        defStr = data(1:equalInd);
        varStr = data(equalInd+1:end);
        varVal = str2num(varStr);
    end
    

    % eval string to make struct fields
    try              
        eval([defStr 'varVal;']);
    catch
        disp('[UDP2Struct]: you fucked up');
        keyboard;
    end
    
    %keyboard
    %pause(.001);
end


