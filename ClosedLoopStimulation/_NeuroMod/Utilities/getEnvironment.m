function sEnv = getEnvironment(bSetDefaultMonitor, callAgent)
% getEnvironment	Returns a structure where other BrainGate code can find information
%					about monitors; networks and IP addresses; hard drives and removable
%					drives; paths on other computers when available; and paths to
%					data folders, to session software elements, and to Windows OS programs.
%
% In addition to providing a single source for commonly-needed system information, this
%	returns path information that will allow programs that use this information to
%	run in Software folders that are not on the C drive or are not in C:\Session\Software.
%
% Usage:
%	bSetDefaultMonitor = true; callAgent = 'workspace';
%	sEnv = getEnvironment(bSetDefaultMonitor, callAgent);
%
% Inputs:
%	bSetDefaultMonitor	optional boolean. TRUE makes the current monitor (where the cursor
%						is located) the default location for future Matlab figures.
%
%	callAgent			optional string that identifies the agent calling this function,
%						to be saved in the returned structure for informational purposes
%						only. ['unspecificed']
%
% Oututs:
%	sEnv			structure with the runtime environment information in these fields:
%		.caller		information about who called this and when
%		.disp		information about displays attached and recognized by Windows
%		.net		information about networks (IPs) known to this computer
%		.drives		information about total and usable space on each drive know to Windows
%		.paths		collection of paths commonly used within Braingate sessions
%
% History:
%	2012.01.17		Created so that xCore release code can begin replacing hard-coded
%					references to C: drive and session folder paths with information
%					from this structure. [Simeral]
%
% copyright 2013 John D. Simeral

% ----------------------------------------------------------------------------------------
% Coding:
%	The functions called here are placed in a subfolder named "+env", a private Matlab folder.
%		A functions xxx in +env is accessed using the env.xxx synax below. The functions
%		are not visible except through this syntax (i.e. the Matlab search path will not find them).
%	See the various called functions for coding details, assumptions, and hard-codes.
% --------------------------------------------------------------------------------  --------

if ~nargin
	callAgent = 'unspecified';		% Just used
end;
if nargin < 2
	bSetDefaultMonitor = [];		% Use default set in the called function
end;

% Who called this function?
sEnv.caller.computerName = getenv('computername');		% e.g., ShuttlePC1
sEnv.caller.computerType = computer;					% e.g., PCWIN64
sEnv.caller.datestr = datestr(date,'yyyy.mm.dd');		% Standard BrainGate date format
sEnv.caller.agent = callAgent;							% e.g., NCS, BG2D, DEKAMODEL


% Monitors that are available
sEnv.disp = env.getMonitorInfo(bSetDefaultMonitor);

% Networks that are available
sEnv.net = env.getNetworkInfo;

% Drives that are available
sEnv.drives = env.getDriveInfo;

% Assemble session folder path info 
sEnv.paths = env.getPathInfo;

% Determine if this code is running on a proper cart
sEnv.isProperCart = sEnv.net.isProper;
sEnv.cartTestMode = 'off';

% Check for unique cart / participant identifier in "My Documents"
% Added by AAS on 2013.07.31. We want to know a number of things about
% participant-related prefs. This is for defaults only -- should be GUIable
myDocsPath = 'C:\Users\operator\Documents\'; % windows cart standard
checkForID = dir([myDocsPath '*cartID*.txt']);
if size(checkForID,1) == 1
   sEnv.participantID = checkForID.name(length('cartID_')+1:end-length('.txt'));
elseif isempty(checkForID)
    sEnv.participantID = [];
    fprintf('[getEnvironment]: Couldn''t find a cart identifier file in my docs. Defaulting to empty.\n')
elseif size(checkForID,1) > 1
    error('Why are there two cart identifier files in my documents?? GET RID OF ONE.')
end

% END
