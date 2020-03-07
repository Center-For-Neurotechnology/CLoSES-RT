function sDrive = getDriveInfo()
% getDriveInfo		Get information about available data drives (in Windows OS).
%
% Usage:
%	driveStruct = getDriveInfo
%
% Inputs:
%	None
%
% Outputs:
%	sDrive		Structure with details for availabe drives.
%					By convention, variables specifying drive "letters" will be strings
%					that include the colon AND fileseperator ('\')
%
% History:
%	2013.01.17		Adapted from code in NCS. [Simeral]
% ----------------------------------------------------------------------------------------

sDrive.systemDrive = [getenv('systemdrive') '\'];	% includes colon automatically


% Find drives currently mounted that Windows knows about.

FileObj = java.io.File(sDrive.systemDrive);
A = FileObj.listRoots;	% results do not actually depend on drive used to create FileObj
for n = 1:length(A)
	sDrive.availableDrives{n} = char(A(n));
end;

% Former (DOS) method
%	This code can be deleted after the JAVA code is proven to work on the cart and other
%	computers.
%try
%	diskInfoCmd = 'C:\Windows\system32\fsutil fsinfo drives';
%	[status,list_str] = system(diskInfoCmd);
%	list3char_str = regexprep(list_str,'Drives:','','ignorecase');
%	sDrive.availableDrives_cel = regexp(token,'.:\\','match');
%catch
%	fprintf('NOTICE [%s]: This command failed to get Windows drive info"\n',mfilename);
%	fprintf('       %s\n',diskInfoCmd);
%end;

 
% Find total and availalbe space for each drive
%	2012.08.14 AAS, DB
%	2013.01.16 Re-wrote to eliminate hard-coded extraction fields. 2013.01.17 [Simeral]
%	2013.01.17 Re-wrote in java to eliminate too-slow dos function
for n = 1:length(sDrive.availableDrives)
	DL = sDrive.availableDrives{n};
% 	FileObj = java.io.File(DL);
% 	sDrive.totalSpace_GB(n)= round(FileObj.getTotalSpace./1024^3) ;
% 	sDrive.usableSpace_GB(n) = round(FileObj.getUsableSpace./1024^3) ;
sDrive.totalSpace_GB(n) = 100; % HACK
sDrive.usableSpace_GB(n) = 100; % HACK - TALK TO JDS ABOUT WHY THIS FAILS. 2013.12.02
	% If drive C or D is low on space, alert the user
	if (strcmpi(DL,'C:\')) && sDrive.usableSpace_GB(n) < 50
		msg_str = sprintf('WARNING [%s]: Drive %s is low on space (%i GB left).',mfilename,DL,sDrive.usableSpace_GB(n));
		fprintf('%s\n',msg_str);
		msgbox(msg_str);
	end;
end;

% Former dos-based method (works, but takes a few seconds for my 9-drive system and
% Fails when a drive is completely empty ("fail" status, no space data)
%	This code can be deleted after the JAVA code is proven to work on the cart and other
%	computers.
%for n = 1:length(sDrive.availableDrives_cel)
%	DL = sDrive.availableDrives_cel{n};
%	[fail,dirlist_str] = dos(['dir ' char(DL)]);	% returns directory listing in a 1xN string
%	if fail
%	%	fprintf('NOTICE [%s]: failed to get space for drive %s using dos command.\n',mfilename, DL);
%	else
%		noCommas_str = strrep(dirlist_str,',','');									% remove all commas from dir listing
%		freeBytes_cel = regexp(noCommas_str,'\d+ bytes free','ignorecase','match'); % grab numbers with "bytes free" text
%		sDrive.freeGB(1,n) = round(str2num(strrep(freeBytes_cel{1},' bytes free',''))./(1024^3));	% just the numbers now, in GigaBytes
%		%sDrive.drives(n).DL = DL;
%		%sDrive.drives(n).freeSpace_GB = freeGB_num;
%	end;
%end;

% END
