function NSx = openNSxSync

% openNSxSync
% 
% Opens a synced NSx file and removed the extra bit of data from the file.
%
% This function does not take any inputs.
%
%   Kian Torab
%   Blackrock Microsystems
%   kian@blackrockmicro.com
%
%   Version 1.0.0.0
%

%% Openning Synced files and removing the extra piece of data
NSx = openNSx('read');
if iscell(NSx.Data)
    % Removing the extra bit of empty data
    NSx.Data = NSx.Data{2};
    NSx.MetaTags.Timestamp(1) = [];
    NSx.MetaTags.DataPoints(1) = [];
    NSx.MetaTags.DataDurationSec(1) = [];
    % Re-aligning what's left
    NSx.Data = [zeros(NSx.MetaTags.ChannelCount, NSx.MetaTags.Timestamp) NSx.Data];
    NSx.MetaTags.DataPoints = NSx.MetaTags.DataPoints - NSx.MetaTags.Timestamp;
    NSx.MetaTags.DataDurationSec = NSx.MetaTags.DataPoints / NSx.MetaTags.SamplingFreq;
    NSx.MetaTags.Timestamp = 0;
end

%% If user does not specify an output argument it will automatically create a structure.
outputName = ['NS' NSx.MetaTags.FileExt(4)];
if (nargout == 0),
    assignin('caller', outputName, NSx);
    clear all;
else
    varargout{1} = NSx;
end