function sMon = getMonitorInfo(bSetDefaultMonitor)
% getMonitorInfo	Get information about available monitors
%
% Usage:
%	monitorStruct = getMonitorInfo(bSetDefaultMonitor)
%
% Inputs:
%	bSetDefaultMonitor		boolean; TRUE sets the Matlab default figure location
%							to be on the monitor where the cursor is located when
%							this function is called. [true]
%
% Outputs:
%	sMon		Structure with details for each attached monitor. Note that the
%				display IDs (indices) in the structure are not intended to match
%				Windows' labels for which monitor is "1", "2", etc. Rather, monitors
%				should be mapped to the real world by their Names which describe their
%				physical location ("left", "right"). If these are innacurate, make sure
%				the Windows display configuration has the monitors in their correct
%				locations.
%
% Coding:
%	See detailed comments in code.
%
% History:
%	2013.01.16		Adapted from code in NCS.m and 

% -------------------------------------------------------------------------------------------
% Multiple monitor handling:
%	Assumes multiple monitors are adjacent in X, not stacked. Vertical stacks will	fail.
%	Sets things up to place all windows on the screen where	the mouse pointer is
%	located when this code is called.

% A monitor position will be negative X when the main (primary) monitor is to the right
%	of the secondary monitor (as established in the Windows screen management control
%	panel; main/primary refers to the selected monitor "This is your main display"
%	irrsepective of whether that display is number 1, 2, or higher in the Windows display
%	manager).
% "sortrows" is used to order the monitor information here from LEFT monitor (first row
%	of sorted monitoPositions) to RIGHT (last row of sorted monitorPositions). Of course 
%	the user ust ensure that the Windows screen management panel matches the actual
%	physical position (left / right) of each monitor.

% Get screen size(s) in pixels and characters and pixels.
%	MonitorPositions comes back (in Windows) as	[xmin,ymin,xmax,ymax] where
%	min and max refer to the total combined monitor pixel coverage across all monitors
%	(not individual screen sizes).
% -------------------------------------------------------------------------------------------

% manage inputs
if ~nargin
	bSetDefaultMonitor = true;
end;

% Get monitor X/Y info as Matlab knows it

sMon.numMonitors = [];				% placeholder; I want this to appear first in the structure

originalUnits = get(0,'units');		% save original units of the command for later

set(0,'units','pixels');
sMon.monitorPositions_pix = sortrows(get(0,'MonitorPositions'));
set(0,'units','characters');
sMon.monitorPositions_char = sortrows(get(0,'MonitorPositions'));

set(0,'units','pixels');
sMon.cursorPosition_pix = get(0,'PointerLocation');
set(0,'units','characters');
sMon.cursorPosition_char = get(0,'PointerLocation');

set(0,'units',originalUnits);		% leave the matlab command units as we found them


% Build up our more detailed monitor information structure
sMon.numMonitors = size(sMon.monitorPositions_pix,1);

switch sMon.numMonitors
	case 1
		display(1).monitorName = 'Single Display';
	case 2
		display(1).monitorName = 'Left Display';
		display(2).monitorName = 'Right Display';
	case 3
		display(1).monitorName = 'Left Display';
		display(2).monitorName = 'Center Display';
		display(3).monitorName = 'Right Display';
	case 4
		display(1).monitorName = 'Left Display (of 4)';
		display(2).monitorName = 'Center Left Display';
		display(3).monitorName = 'Center Right Display';
		display(4).monitorName = 'Right Display (of 4)';
	otherwise
		fprintf('ERROR[%s]: %i monitors, really?\n',mfilename,sMon.numMonitors);
		fprintf('    Write your own damn code.\n');
		return
end;

% Compute useful coordinates and limits for each display in pixels (for graphics)
%		and in characters (for accurate placement of text)

xsizesPixels = sMon.monitorPositions_pix(:,3)-sMon.monitorPositions_pix(:,1)+1;
ysizesPixels = sMon.monitorPositions_pix(:,4)-sMon.monitorPositions_pix(:,2)+1;

xsizesChars = sMon.monitorPositions_char(:,3)-sMon.monitorPositions_char(:,1)+1;
ysizesChars = sMon.monitorPositions_char(:,4)-sMon.monitorPositions_char(:,2)+1;


% edit AAS 2013.11.05: we want this to have a default value, because it's
% actually possible that cursor does not register as being on any monitor!
sMon.cursorOnMonitor_i = 1;

for n = 1:sMon.numMonitors
	display(n).isPrimary = sMon.monitorPositions_pix(n) == 1;	% boolean; true for Windows "Main Display"

	display(n).xsize_pix = xsizesPixels(n);
	display(n).ysize_pix = ysizesPixels(n);
	display(n).xmin_pix  = sMon.monitorPositions_pix(n,1);
	display(n).xmax_pix  = sMon.monitorPositions_pix(n,3);
	display(n).ymin_pix  = sMon.monitorPositions_pix(n,2);
	display(n).ymax_pix  = sMon.monitorPositions_pix(n,4);
	display(n).xcenter_pix = display(n).xmin_pix + 0.5*display(n).xsize_pix;
	display(n).ycenter_pix = display(n).ymin_pix + 0.5*display(n).ysize_pix;

	display(n).xsize_char = xsizesChars(n);
	display(n).ysize_char = ysizesChars(n);
	display(n).xmin_char  = sMon.monitorPositions_char(n,1);
	display(n).xmax_char  = sMon.monitorPositions_char(n,3);
	display(n).ymin_char  = sMon.monitorPositions_char(n,2);
	display(n).ymax_char  = sMon.monitorPositions_char(n,4);
	display(n).xcenter_char = display(n).xmin_char + 0.5*display(n).xsize_char;
	display(n).ycenter_char = display(n).ymin_char + 0.5*display(n).ysize_char;

	if sMon.cursorPosition_pix(1) > display(n).xmin_pix
		sMon.cursorOnMonitor_i = n;
	end;
end; % looping through size calcs for all displays

% For the record, was the cursor's monitor set as default?
% Force to string, since boolean "1" gets confused with display "1"
if bSetDefaultMonitor;
	sMon.setDefaultMonitor = 'yes';
else
	sMon.setDefaultMonitor = 'no';
end;


if bSetDefaultMonitor
	% Set the Matlab DefaultFigurePosition X and Y location to be on the display
	% where the cursor is currently located. Do not change the default figure size.
	% This code is all in pixels.

	currentDefaultFigPosision = get(0,'defaultFigurePosition');		% always in pixels regardless of (0,'units')
	defaultXsize = currentDefaultFigPosision(3);
	defaultYsize = currentDefaultFigPosision(4);
	newXpos  = display(sMon.cursorOnMonitor_i).xcenter_pix - 0.5*(defaultXsize);
	newYpos  = display(sMon.cursorOnMonitor_i).ycenter_pix - 0.5*(defaultYsize);

	set(0,'DefaultFigurePosition',[newXpos newYpos defaultXsize defaultYsize]);
end; % setting default monitor position (if requested)

sMon.dispInfo = display;		% add our local variable to the return structure.

% END
