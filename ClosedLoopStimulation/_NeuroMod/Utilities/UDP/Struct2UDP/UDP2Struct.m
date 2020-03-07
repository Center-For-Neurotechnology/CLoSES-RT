function S = UDP2Struct(socket_h,mode)

% S = UDP2Struct(socket_h)
%
% Description
%   When triggered by the receive timer that is called from, it jumps into
%   a while loop and reads all encoded Struct2UDP packets, decodes them,
%   and returns the reconstructed structure.
%
% INPUT
%   socket_h: pnet UDP socket handle
%   mode: "next" or "latest"? (not packets, but full structs)
% OUTPUT
%   Reconstructed structure sent via Struct2UDP by sending agent
%
% created Dan Bacher 2013.03.19
% modifed AAS & JAD 2013.07.31 so that we can look for the LAST struct
% sent.

% default args
if nargin < 2
    mode = 'latest';
end

% param
TIMEOUT = 10;

% init
S = [];
structName = [];
structNameFlag = 0;

% enter while loop, but timeout after TIMEOUT seconds so we don't get stuck
whileTimer = tic;
n = 0;

while true
    n = n + 1;
    packet = ReceiveUDP(socket_h,'next');
    
    if ~isempty(packet)
        [varName, varVal] = ExtractDoublePacket(packet, socket_h);
        eval([varName '= varVal;']);
        %disp(varName);
        
        % extract structure name from first struct field returned
        if isempty(structName) && structNameFlag
            firstDot = strfind(varName,'.');
            if ~isempty(firstDot)
                structName = varName(1:firstDot-1);
            else
                structName = varName;
                disp('[UDP2Struct]: a structure wasn''t sent, but here''s your param');
            end
        end
        if strcmp(varName,'start')
            structNameFlag = 1;
        end
        
        % break out and return when stop command comes in
        if strcmp(varName,'stop')
            break;
        end
    else
        if n == 1
            % first packet was empty. Abort.
            disp('[UDP2Struct]: first packet read returned empty. Nothing here.');
        else
            % empty packet after receiving valid packets
            disp('[UDP2Struct]: Empty packet received before stop packet received. Aborting');
        end
        S = [];
        return;
    end
    
    % break out of loop if timeout
    whileTimeElapsed = toc(whileTimer);
    if whileTimeElapsed >= TIMEOUT
        disp('[UDP2Struct]: TIMEOUT. Never received stop packet, IDIOT');
        break;
    end
    
end

% TO DO: add a timestamp as a field on the output struct, IDIOTS

% define output
eval(['S = ' structName ';']);


% Added a "latest" mode on 2013.07.31 AAS & JAD.
% Simply calls UDP2Struct again to look for another, newer start packet. If
% this is not present, it returns an empty immediately and no harm is done.

if ~isempty(S) && (strcmp(mode,'latest')) % (if you have already received a structure and you want to look for another)
    fprintf('[UDP2Struct]: received a structure\n')
    fprintf('[UDP2Struct]: Checking for a more up to date struct...')
    S_recur = UDP2Struct(socket_h,'latest');
    if ~isempty(S_recur)
        S = S_recur;
        fprintf('found one.\n')
    end
end

disp('[UDP2Struct]: received all params');

