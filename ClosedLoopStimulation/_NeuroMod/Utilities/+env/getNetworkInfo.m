function sNet = getNetworkInfo()
% getNetworkInfo	Get information about available Ethernet networks and find this
%					computer's IPs for the BrainGate .10 and .137 networks. If cart
%					networks are not found then use an available network.
%
% Usage:
%	networkStruct = getNetworkInfo
%
% Inputs:
%	None
%
% Outputs:
%	sNet		Structure with details for each attached network.
%		.IPlist		cell array (of IP strings) returned by getMyIP, one IP per row
%		.numIPs		integer - number of rows in IPlist (number of IPs known to Windows)
%		.nspNetIp	IP address (string) that should be used for nsp network
%		.xpcNetIP	IP address (string) that should be used for xpc network
%		.status		string to describe network condition to user
%		.isProper	boolean
%						true if .30 and .137 networks were found: a proper cart.
%						false otherwise; BG2 software may or may not function over
%						the availalbe networks, and performance may be unreliable
%
% Coding:
%	No network sockets or such are dealt with here. This code merely assigns a string IP
%	value to the cart network variables in the structure for nsp network and xpc network.
%	
% History:
%	2013.01.17		Adapted from code in NCS. [Simeral]

% ----------------------------------------------------------------------------------------

% get the raw list of IPs on this computer
sNet.IPlist   = env.getMyIP;
sNet.isProper = false;
sNet.status = '';

if isempty(sNet.IPlist{1})
	sNet.numIPs = 0;
	fprintf('NOTICE [%s]: No network connections found on this machine.\n',mfilename);
	% try to assign loop back
	% If someone actually uses this, adjust it until it works and then check it into SVN.
	sNet.nspNetIP = '127.0.0.1';
	sNet.xpcNetIP = '127.0.0.1';
	return;
else
	sNet.numIPs   = size(sNet.IPlist,1);
end;

% At least one network connection exists.

% Try to find BrainGate2-specific network IPs
sNet.nspNetIP = char(env.getMyIP('192.168.137.255'));	% Blackrock-specified network for NSP data
sNet.xpcNetIP = char(env.getMyIP('192.168.30.255'));	% Pre-defined non-NSP network for BrainGate


% Handle cases where one or both of the expected cart networks are not present
if isempty(sNet.nspNetIP) && isempty(sNet.xpcNetIP)
	% Neither of the cart networks was found
	fprintf('NOTICE [%s]: Neither cart network was found.\n',mfilename);
	fprintf('       %i non-cart network(s) found.\n',sNet.numIPs);
	fprintf('       Both cart networks will be assigned to %s\n',sNet.IPlist{1});
	if sNet.numIPs > 1
		fprintf('       Ignoring %i other available networks (just picked the first one, sorry).\n', sNet.numIPs-1);
	end;
	sNet.nspNetIP = sNet.IPlist{1};
	sNet.xpcNetIP = sNet.IPlist{1};
	sNet.status = 'Desktop, not cart.';
	sNet.isProper = false;

elseif isempty(sNet.nspNetIP)
	% One cart network is attached; route all traffic here
	fprintf('WARNING [%s]: Only the xpc network was found (%s).  nspNet (usually .137) will use this .30 network too.\n',mfilename,sNet.xpcNetIP);
	fprintf('        However, it is unlikely that the NSP is connected to this network!\n');
	sNet.nspNetIP = sNet.xpcNetIP(1,:);		% indexed so as not to fail if two adapters are connected to xpcNet (erroneously)
	sNet.status = 'No NSP network found (.137).';
	sNet.isProper = false;
	
elseif isempty(sNet.xpcNetIP)
	% One cart network is attached; route all traffic here
	fprintf('WARNING [%s]: Only the nsp network was found (%s).  xpcNet (usually .30) will use this .137 network too.\n', mfilename,sNet.nspNetIP);
	sNet.xpcNetIP = sNet.nspNetIP(1,:);		% indexed so as not to fail if two adapters are connected to nspNet (erroneously)
	sNet.status = 'No xPC network found (.30).';
	sNet.isProper = false;

else
	% both expected cart networks are accounted for.
	sNet.status = 'Normal Cart configuration';
	sNet.isProper = true;
	
end;


% Detect cases where two (or more) adapters are plugged into the same cart switch (same network)
if size(sNet.nspNetIP) > 1
	msg_str = sprintf('WARNING [%s]: This computer has TWO connections to nspNet (192.168.137.x).',mfilename); 
	fprintf('%s.\n',msg_str); 
	sNet.warning = msg_str;
end;
if size(sNet.xpcNetIP) > 1
	msg_str = sprintf('WARNING [%s]: This computer has TWO connections to xpcNet (192.168.30.x).',mfilename); 
	fprintf('%s.\n',msg_str); 
	sNet.warning = msg_str;
end;

sNet.xpc.netBootRunning = false;
% END
