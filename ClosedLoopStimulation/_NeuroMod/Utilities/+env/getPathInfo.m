function sPaths = getPathInfo()
% getPathInfo		Get information about paths to session and Windows folders for BG2.
%					Software that relies on these paths should be able to run code
%					residing on any parent path, not just C:\Session\Software (an SVN
%					path, for example).
%
%					Data storage folders are HARD-CODED to DL:\Session\Data on the drive
%					from which this function executes. NCS allows selection of a different
%					drive for data storage,in which case NCS must modify these data paths
%					so that data gets redirected to the intended drive. Note that if the
%					software does not reside in \Session\Software then the data may
%					be stored in a folder separate from the software. This is justified
%					in the code comments.
%
% Usage:
%	pathStruct = getPathInfo
%
% Inputs:
%	None
%
% Outputs:
%	sPaths		Structure with details of relevant software and data paths.
%
% History:
%	2013.01.17		Adapted from code in NCS. [Simeral]

% ----------------------------------------------------------------------------------------
% Coding:
%	This function will NOT change the Matlab path.
%	Do NOT add C:\Windows or any of its subdirectories to the Matlab path!
%	NO folders are created here.
%	Capitalization of path names is maintained as returned by Matlab calls, but in 
%		general capitalization should not be considered by BG2 code to be relevant when
%		specifying path names (i.e., code is not generally expected to handle Unix OS).
%
% Assumptions (Hard Codes)
%	This function will point to ...\Software\... and ...\Data\... folders for use by BG2.
%
%	It assumes that this function is running from a folder under a parent ...\Software\...
%	folder. This code then points data storage to a \Data\ folder in parallel with the
%	Software folder. It is not required that these be on the C:\ drive or in a folder
%	parent called \Software\. It hard-codes the standard names of Data subfolders and
%	software subfolders.
%
%	C:\Windows\ is assumed to be where the Windows operating system is installed,
%	although for xCore this may be irrelevant.
%
%	Other installed programs are assumed to be on the C:\ drive at their default
%	installation location (Cerebus Windows Suite, for example).
% ----------------------------------------------------------------------------------------

% --------------------------------------------------------
% Establish Software paths for runtime.
% --------------------------------------------------------
thisFunctionHomeDir = mfilename('fullpath');
sessDirInd = strfind(fileparts(thisFunctionHomeDir),'Session');
if isempty(sessDirInd)
    sPaths.sessionDataRoot = pwd;
    return
end
    thisFunctionDL = thisFunctionHomeDir(1:sessDirInd(1)-1);		% includes colon and slash
sPaths.sessionRoot = [];	% placeholder; I want it first in structure, dont have it yet

% find path up to "...\Software\"
sPaths.sessionSWroot = regexpi(thisFunctionHomeDir,'.+\Software\','match');		
if isempty(sPaths.sessionSWroot)
	% find path up to "...\*Software*\"
	% Yes, you should learn to use regular expressions ("doc regexp")
	sPaths.sessionSWroot = regexpi(thisFunctionHomeDir,'.+Software[^\\]+\\','match','once');

	% still empty? Assume we're in Utilities folder and use its parent
	if isempty(sPaths.sessionSWroot)
		utilDir = (regexpi(thisFunctionHomeDir,'.+\Utilities','match'));
		sPaths.sessionSWroot = fileparts(char(utilDir));
	end;
end;
sPaths.sessionSWroot = char(regexprep(sPaths.sessionSWroot,'\\$',''));	% remove trailing slash if present

sPaths.sessionRoot = fileparts(sPaths.sessionSWroot);	% parent of the detected SW directory

% NCS will refer to these when calling other program's functions

sPaths.swDir_Analysis		= [sPaths.sessionSWroot filesep 'Analysis'];
sPaths.swDir_NCS			= [sPaths.sessionSWroot filesep 'NCS'];
sPaths.swDir_BG2D			= [sPaths.sessionSWroot filesep 'BG2D'];
sPaths.swDir_Utilities		= [sPaths.sessionSWroot filesep 'Utilities'];
sPaths.swDir_Blackrock		= [sPaths.sessionSWroot filesep 'Blackrock'];
sPaths.swDir_SignalVisTool	= [sPaths.sessionSWroot filesep 'SignalVisTool'];
sPaths.swDir_SimulinkCore	= [sPaths.sessionSWroot filesep 'SimulinkCore'];
% --------------------------------------------------------
% Establish Data paths for runtime.
% --------------------------------------------------------

% Data paths are hard coded rather than put in parallel with the software folder, so that
%	(a) running code from an SVN tree will not dump data files into that SVN tree
%	(b) NCS re-direction to a different data drive later (by changing the leading drive
%		letter in these string paths) will create a standard data tree irrespective of
%		where the running software is located.

% To force the Data folder to be in parallel with the detected Software folder, use:
%sPaths.sessionDataRoot = [sPaths.sessionRoot filesep 'Data'];

sPaths.sessionDataRoot  = [thisFunctionDL 'Session' filesep 'Data'];
sPaths.dataSaveDir_figs = [sPaths.sessionDataRoot filesep 'Screen Shots'];
sPaths.dataSaveDir_NCS  = [sPaths.sessionDataRoot filesep 'NCS Data'];
sPaths.dataSaveDir_SLC  = [sPaths.sessionDataRoot filesep 'SLC Data'];
sPaths.dataSaveDir_NSP  = [sPaths.sessionDataRoot filesep 'NSP Data'];

% --------------------------------------------------------
% Operating system and other Windows-level program folders
% --------------------------------------------------------
% TODO: is cerebusCentral still needed with xCore?
sPaths.cerebusCentral	= 'C:\Program Files (x86)\Blackrock Microsystems\Cerebus Windows Suite' ; % to find (and rename) file.exe
sPaths.system32			= 'C:\Windows\System32' ;	% where many "system" and "!" executables are found
% I decided not to include other hard-coded paths for Windows-installed functions and
%	commands here. Instead, then can be hard coded where used.

% END
