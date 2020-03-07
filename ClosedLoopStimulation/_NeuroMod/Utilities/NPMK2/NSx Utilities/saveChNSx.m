function NSx = saveChNSx(varargin)

% saveNSx
% 
% Saves a given continuous NSx file and saves a subset of the channels in
% the given file into a new NSx file. Ths NSx file has to be opened with 
% openNSx version 5.1.1.0 or later.
% 
% All input arguments are optional. Input arguments can be in any order.
%
%   NSx:          The data structure holding the channel information
%
%   fname:        Name of the file to be saved. If the fname is omitted
%                 the program will automaticallyl save the file using the
%                 original file name with -mod added to the end of the
%                 file.
%                 DEFAULT: Will automatically choose the name.
%
%   Example: 
%   
%   saveChNSx('c:\data\sample.ns5', [1,5:9]);
%
%   In the example above, the file c:\data\sample.ns5 will be opened and
%   channels 1,5,6,7,8,9 out of all the channels in this file will be saved
%   as a new file. If the new file already exists then the user will be
%   prompted if the new file should be overwritten or not.
%
%   Kian Torab
%   Blackrock Microsystems
%   kian@blackrockmicro.com
%
%   Version 2.0.2.0
%

% Validating input arguments
if isempty(varargin)
    [path fname fext] = openFile;
    channels = getChannels;
elseif length(varargin) == 1
    if isnumeric(varargin{1})
        [path fname fext] = openFile;
        channels = varargin{1};
    else
        channels = getChannels;
        [path fname fext] = fileparts(varargin{1});
    end
elseif length(varargin) == 2
    if isnumeric(varargin{1})
        channels = varargin{1};
        [path fname fext] = fileparts(varargin{2});
    else
        channels = varargin{2};
        [path fname fext] = fileparts(varargin{1});        
    end
end

% Validating file name
if fname == 0
    disp('No file was selected.');
    if nargout
        clear variables;
    end
    return;
end

if exist([path fname fext], 'file') ~= 2
    disp('File cannot be found.');
    if nargout
        clear variables;
    end
    return;    
end

% Opening the original file
disp('Openning the original file...');
NSx = openNSx([path fname fext], ['c:' num2str(channels)], 'read');

if NSx.RawData.PausedFile
    disp('At this time it is not possible to extract channels from files that have pauses in them.');
    return;
end

% Writing header into the file
newFilename = [path fname(1:end-4) '-chandec-' fname(end-2:end) fext];
if exist(newFilename, 'file') == 2
    overwriteFlag = input('The file already exists. Overwrite? ', 's');
    if ~strcmpi(overwriteFlag, 'y')
        clear all;
        return;
    end
end
        
FIDw = fopen(newFilename, 'w+', 'ieee-le');
NSx.RawData.Headers(311) = uint8(length(channels));

% Removing the extra channels from the header
channelHeaderBytes = 66;
currentPosition = length(NSx.RawData.Headers);
totalNumberOfChannels = NSx.MetaTags.ChannelCount;
allChannels = totalNumberOfChannels:-1:1;
for chanIDX = 1:totalNumberOfChannels
    if ~ismember(allChannels(chanIDX), channels)
        NSx.RawData.Headers(currentPosition-channelHeaderBytes+1:currentPosition) = [];
    end
    currentPosition = currentPosition - channelHeaderBytes;
end

% Writing the header information
fwrite(FIDw, NSx.RawData.Headers, 'uint8');
fwrite(FIDw, NSx.RawData.DataHeader, 'uint8');

% Writing data into file
disp('Writing into the new file...');
fwrite(FIDw, NSx.Data, 'int16');
fclose(FIDw);
clear all;

function [path fname fext] = openFile
    % Getting the file name
    if ~ismac
        [fname, path] = getFile('*.ns*', 'Choose an NSx file...');
    else
        [fname, path] = getFile('*.*', 'Choose an NSx file...');
    end
    fext = fname(end-3:end);
    fname = fname(1:end-4);

function channels = getChannels
    channels = input('What channels would you like to save as a separate file? ');
    while ~isnumeric(channels)
        disp('The response should be a numberical value (e.g. 3 or [4,6:10]).');
        channels = input('What channels would you like to save as a separate file? ');
    end