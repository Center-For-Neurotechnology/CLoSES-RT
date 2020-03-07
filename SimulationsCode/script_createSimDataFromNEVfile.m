function script_createSimDataFromNEVfile(fileNameNSx, simMATFileName, channelNamesInput, chNumberTrigger, startNSxSec, endNSxSec, areChNamesBipolar,trigger)
% This file is used to create simulation MAT files from NSX files
% See example on stepByStepCreateSimulatedDataSet to see how to run it.
%
% Example Inputs:
%   fileNameNSx = 'C:\DATA\Patients\P1_d15-003.ns3';
%   pName = 'P1'; 
%   simMATFileName = ['C:\DATA\Simulations\SimData_MSIT_LMF_',pName,'.mat'];
%   channelNamesInput = {'LAF1','LAF2','LMF2','LMF3','LMF9','LMF10','RAF6','RAF7'};
%   channelNumbers = [ 1,2, 28, 29, 35, 36, 122, 123];
%   chNumberTrigger = 131;
%   startNSxSec = 0;
%   endNSxSec = 360;
%   areChNamesBipolar if 1 indicates that channelNames are Bipolar, if 0 channelNames are referential
%   trigger: vector with trigger information, if empty it gets it from chNumberTrigger

%% RUN findExperiementTimeToCreateSimulatedDataset ONCE to find timings
%[startBlocksSec, endBlocksSec, indTriggerChannel] = findExperimentTimeToCreateSimulatedDataset(fileNameNSx, startToLookSec)

%% Config
if ~exist('chNumberTrigger','var') 
    chNumberTrigger=[];
end
if ~exist('startNSxSec','var') 
    startNSxSec=0;
end
if ~exist('endNSxSec','var') 
    endNSxSec=[];
end
if ~exist('areChNamesBipolar','var') 
    areChNamesBipolar = 0;
end
if ~exist('trigger','var')
    trigger=[];
end

%% Read data of selected channels from NSx file
%Open NS3 file
dataNEV = openNSx(fileNameNSx, 'read', 'report');
downSampleBy = 1; % DO NOT downsample

%General Information
hdr=[];
hdr.FsOrig      = dataNEV.MetaTags.SamplingFreq; 
hdr.Fs          = dataNEV.MetaTags.SamplingFreq / downSampleBy; % RIZ: POOR HACK to downsample data!!!!!
hdr.nChans      = dataNEV.MetaTags.ChannelCount;
hdr.nSamples    = dataNEV.MetaTags.DataPoints;
hdr.orig        = dataNEV.MetaTags; % remember the original header

% Interval of interest
if isempty(endNSxSec)
    endNSxSec = dataNEV.MetaTags.DataDurationSec;
end
%indTimeSamples = round(startNSxSec*hdr.Fs+1: endNSxSec*hdr.Fs); % THIS is the one that should be used!
%indTimeSamples = round(startNSxSec*hdr.FsOrig+1 :2: endNSxSec*hdr.FsOrig); % VERY poor HACK to downsampling to 1kHz -> note absence of FILTER!!! data is acquired with a 500Hz filter anyways

% adapt Data from int16 to double  (copied from Angelique's pre-processing)
indSamples = max(startNSxSec*hdr.FsOrig,0)+1 : min(endNSxSec*hdr.FsOrig,dataNEV.MetaTags.DataPoints);
dataNEVScaled=zeros(length(dataNEV.ElectrodesInfo),length(indSamples));
downsampledData=zeros(length(dataNEV.ElectrodesInfo),ceil(length(indSamples)/downSampleBy));
for iCh=1:length(dataNEV.ElectrodesInfo)
    elecinfo      = dataNEV.ElectrodesInfo(iCh);
    coef          = (double(elecinfo.MaxAnalogValue) - double(elecinfo.MinAnalogValue)) /  (double(elecinfo.MaxDigiValue) - double(elecinfo.MinDigiValue));
    dataNEVScaled(iCh,:)=double(dataNEV.Data(iCh,indSamples))*coef;
    %Downsample data -> Could probably remove after testing new simulation inputs
    if downSampleBy>1
        downsampledData(iCh,:) = decimate(dataNEVScaled(iCh,:), downSampleBy);
    else
        downsampledData(iCh,:) =dataNEVScaled(iCh,:);
    end
end



lTime = size(downsampledData,2);


% if input is bipolar channels get referential from bipolar name
if areChNamesBipolar == 1
    splitChNamesBipolar = split(channelNamesInput,' ');
    if length(size(splitChNamesBipolar))>2 % check if it needs to traspose
        splitChNamesBipolar = split(channelNamesInput',' ');
    end
    arrChannelNames = unique(splitChNamesBipolar);
    channelNames = cell(1,length(arrChannelNames));
    for iCh=1:length(arrChannelNames)
        channelNames{iCh} = arrChannelNames{iCh}; % channelNames are the referential channels (should probably be "contacts")
    end
else
    channelNames = channelNamesInput;
end

% Channels of interest
allChNamesInNSX = {dataNEV.ElectrodesInfo.Label}';
nChannels = length(channelNames);
channelNumbersInNSX = zeros(1, nChannels);
channelNumbersInChannelName = zeros(1, nChannels);
isChannelInNSX = zeros(1, nChannels);
for iCh=1:nChannels % find selected contacts numbers
    chNumber = find(strncmpi(allChNamesInNSX, channelNames{iCh},length(channelNames{iCh})),1);
    if ~isempty(chNumber)
        channelNumbersInNSX(iCh) = chNumber;
        isChannelInNSX(iCh) = 1; % indicates whether channel is in NSX file
        channelNumbersInChannelName(iCh) = iCh;
    else
        disp(['No corresponding channel in NSx file ',fileNameNSx,' for channelName = ',channelNames{iCh}]);
    end
end
channelNumbersInNSX = nonzeros(channelNumbersInNSX);
channelNumbersInChannelName = nonzeros(channelNumbersInChannelName);
channelNames = channelNames(find(isChannelInNSX));  % only keep channelNames found in NSX file
nChannels = length(channelNumbersInNSX);

% Preselect channels to use (from bipolar names)
channel1=[];
channel2=[];
if areChNamesBipolar == 1
    for iCh=1:size(splitChNamesBipolar,1)
        indBipolarCh1 = find(strcmpi(channelNames, splitChNamesBipolar{iCh,1}),1);
        indBipolarCh2 = find(strcmpi(channelNames, splitChNamesBipolar{iCh,2}),1);
        if ~isempty(indBipolarCh1) && ~isempty(indBipolarCh2)
            channel1 = [channel1, indBipolarCh1];
            channel2 = [channel2, indBipolarCh2];
        end
    end
end

% Get EEG data for the selected channels
EEGVals = zeros(nChannels, lTime);
for iCh=1:nChannels
    EEGVals(iCh,:) = downsampledData(channelNumbersInNSX(iCh),:);
end
timeVals = linspace(0, lTime/hdr.Fs , lTime);

% Get Triggers information if exist
triggerVals = zeros(1, lTime);
if ~isempty(chNumberTrigger) && isempty(trigger)==1
    triggerVals = downsampledData(chNumberTrigger,:);
elseif isempty(trigger)==0   
    if downSampleBy>1        
        triggerVals = decimate(trigger,downSampleBy);
    else
        triggerVals = trigger;
    end
end

%% Save simulation data
save(simMATFileName, 'EEGVals', 'triggerVals', 'timeVals', 'channelNames', 'channelNumbersInNSX', 'nChannels', 'chNumberTrigger', 'channelNamesInput','startNSxSec','endNSxSec', 'hdr', 'channel1', 'channel2','-v7.3');

