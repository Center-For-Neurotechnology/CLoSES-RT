function script_createSimDataFromPlexonFile(fileNamePlexonStimData, fileNamePlexonGral, simMATFileName, channelNumbers, chNumberTrigger, startPlexonSec, endPlexonSec)

%it is a 1k sampling!!
%simMATFileName = ['C:\DARPA\DATA\Simulations\SimData_NHP_','.mat'];
%channelNumbers = [ 8,9,10,11];
%triggerChNumber = 16; -> usually eye tracker

if ~exist('chNumberTrigger','var') 
    chNumberTrigger=[];
end
if ~exist('startPlexonSec','var') 
    startPlexonSec=0;
end
if ~exist('endPlexonSec','var') 
    endPlexonSec=[];
end
newFS =1000;

%% Read data of selected channels from NSx file

% Interval of interest
if isempty(endPlexonSec)
    endPlexonSec = 100000;
end

%Read EEGdata from Plexon files (there is one per channel)
nChannels = length(channelNumbers);
EEGVals = []; %zeros(lTime, nChannels);
channelNames = cell(1,nChannels);
for iCh=1:nChannels
    fileNamePlexon = [fileNamePlexonGral, num2str(channelNumbers(iCh)-1),'.mat']; % filenames start at ch0 - they are 1 ch difference to the other
    stData = load(fileNamePlexon);
    indTimeSamples = round(startPlexonSec*newFS+1: min(endPlexonSec*newFS, length(stData.DataChan)));
    EEGVals(iCh,:) = stData.DataChan(indTimeSamples);
    channelNames{iCh} = num2str(channelNumbers(iCh));
end
lTime = length(indTimeSamples);

%General Information from STIM file
stStimInfo = load(fileNamePlexonStimData);

hdr=[];
hdr.Fs          = newFS;
hdr.originalFs = stStimInfo.FSStim;

%TimeVals are simply from 0 to duration in sec
timeVals = linspace(0, lTime/hdr.Fs , lTime);

% Get Triggers information if exist
triggerVals = zeros(1, lTime);
if ~isempty(chNumberTrigger)
    fileNameTriggerPlexon = [fileNamePlexonGral, num2str(chNumberTrigger-1),'.mat']; % filenames start at ch0 - they are 1 ch difference to the other
    stData = load(fileNamePlexon);
    triggerVals = stData.DataChan(indTimeSamples);
end

%% Save simulation data
save(simMATFileName, 'EEGVals', 'triggerVals', 'timeVals', 'channelNames', 'channelNumbers', 'nChannels', 'chNumberTrigger', 'startPlexonSec','endPlexonSec', 'hdr');

