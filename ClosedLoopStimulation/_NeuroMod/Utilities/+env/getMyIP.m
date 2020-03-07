function [localIP] = getMyIP(subnet)
% getMyIP	Get the current machine's IP address or addresses
%
% Usage
%	localIP = getMyIP(subnet)
%
%			With no subnet input, all IPv4 IP addresses for the
%			local machine are returned.
%
%			If subnet is specified then the IP address(es) of the
%			local machine on the specified subnet is/are returned.
%			Presumably there will only be one IPv4 for this machine
%			on this subnet but 'localIP' will contain any and all.
%
% Inputs
%	subnet	char string 'sss.sss.sss.xxx' of digits [optional]
%
% Outputs
%	localIP	cell array of IP addresses
%
%			If 'subnet' is specified, the machine's IP address on
%			the subnet sss.sss.sss.xxx is returned, where the (irrelevant)
%			xxx of the incoming	subnet specification is 
%			replaced to yield the actual IP address of the machine
%			on that subnet.
%
%			If the local machine is not on the specified subnet then
%			localIP is returned empty.
%
%			If 'subnet' is not specified then all IPv4 addreses
%			for the local machine are returned in a cell array. If
%			the local machine has no Ethernet connections then
%			localIP is returned empty.
%
% Purpose			
%			This function is developed for the pnet UDP receive
%			command sequence
%				receivesock=pnet('udpsocket',portnum)
%				pnet(receivesock, 'udpconnect', 'localhost', portnum);
%			where 'localhost' must be specified exactly.
%
%			The local machine may have multiple Ethernet connections/cards.
%			Hence the user can call this function without 'subnet' to
%			determine what Ethernet connections are available.
%
%			In the case of NCS, the subnet is known (determined by
%			the NSP fixed IP address of 192.168.137.128) and we want to
%			determine the NCS machine's IP address on this subnet. In this
%			case the subnet is specified to getMyIP and the appropriate
%			ethernet adapter IP address is returned.
%
% Coding
%			This function is dependent on the DOS system call to ipconfig.
%			It also assumes, by virtue of the regular expressions used,
%			that IPv4 IP addresses are to be reported.
%
% copyright 2008-2011 John D. Simeral, All Rights Reserved
% -------------------------------------------------------------------------

if isunix % Linux
    localIP = {''};
    cmd = '/sbin/ifconfig';
    if ~exist(cmd)
        fprintf('WARNING[%s]: Missing Linux function to get local IP address:\n',mfilename);
        fprintf('                  %s\n',cmd);
    end;
    a=(strread(evalc(['!' cmd]),'%s','delimiter','\n'));
    
    if ~nargin 
        % Report all unique IPv4 addresses

        % capture the lines with IPv4 addresses
        s = regexp(a,'inet addr:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}','once');
        s_i = find(~cellfun('isempty',s));

        % Pull out just the IP part of each case:
        IP = regexp(a(s_i),'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}','match');
        % just keep the 'inet addr' portion, not 'Bcast' or 'Mask'
        for i = 1:length(IP)
            localIP{i} = IP{i}{1};
        end
    else
        % report this machine's IPv4 address on the specified subnet

        % strip off 4th component of incoming 'subnet' leaving first 3 parts
        subnet3 = regexp(subnet,'\d{1,3}\.\d{1,3}\.\d{1,3}','match','once');

        % find the IPv4 entries with this exact subnet
        s = regexp(a,['inet addr:' subnet3 '\.\d{1,3}'],'once');
        s_i = find(~cellfun('isempty',s));

        % Pull out just the IP part of each case:
        IP = regexp(a(s_i),[subnet3 '\.\d{1,3}'],'match');
        % just keep the 'inet addr' portion, not 'Bcast' or 'Mask'
        for i = 1:length(IP)
            localIP{i} = IP{i}{1};
        end
    end;

elseif ismac
    localIP = {''};
    
else % assume Windows OS
    
    % get a long DOS report of IP configuration information
    cmd = 'C:\windows\system32\ipconfig.exe' ;
    if ~exist(cmd)
        fprintf('WARNING[%s]: Missing Windows function to get local IP address:\n',mfilename);
        fprintf('                  %s\n',cmd);
    end;
    a=(strread(evalc(['!' cmd]),'%s','delimiter','\n'));

    if ~nargin 
        % Report all unique IPv4 addresses

        % capture the lines with IPv4 addresses
        s = regexp(a,'IPv4.+\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}','match');
        s_i = find(~cellfun('isempty',s));

        % Pull out just the IP part of each case:
        localIP = regexp(a(s_i),'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}','match');
    else
        % report this machine's IPv4 address on the specified subnet

        % strip off the fourth component of the incoming 'subnet' leaving first 3 parts
        subnet3 = regexp(subnet,'\d{1,3}\.\d{1,3}\.\d{1,3}','match','once');

        % find the IPv4 entries with this exact subnet
        s = regexp(a,['IPv4.+' subnet3 '\.\d{1,3}'],'match');
        s_i = find(~cellfun('isempty',s));

        % Pull out just the IP part of each case:
        localIP = regexp(a(s_i),[subnet3 '\.\d{1,3}'],'match');
    end;

    localIP = unique(cellstr(char([localIP{:}])));

end; % end of else ifunix

