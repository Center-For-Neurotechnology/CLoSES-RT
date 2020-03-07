function [startBlocksSec, endBlocksSec, chNumberTrigger, triggerFromFirstSec] = findExperimentTimeToCreateSimulatedDataset(fileNameNSx, startToLookSec, ainChName)

distBetweenBlocksSec = 60; % larger than this in sec is considered 2 blocks

dataNEV = openNSx(fileNameNSx, 'read', 'report');

if ~exist('startToLookSec','var') 
    startToLookSec = 0;
end
if ~exist('ainChName','var') 
    ainChName = 'trig';
end

% Find electrode name "trig"
{dataNEV.ElectrodesInfo.Label}'
chNumberTrigger = find(cellfun(@isempty,strfind({dataNEV.ElectrodesInfo.Label},ainChName))==0)

%figure; plot(dataNEV.Data(chNumberTrigger,:))

% Find start of experiment
Fs = dataNEV.MetaTags.SamplingFreq;
startToLookSamples = startToLookSec * Fs +1;
samplesTrigger = find(dataNEV.Data(chNumberTrigger,startToLookSamples:end)>1000);

indBlockEnds = find(diff(samplesTrigger)>Fs*distBetweenBlocksSec);
timeStartBlockSamples = [samplesTrigger(1),samplesTrigger(indBlockEnds+1)] 
timeEndBlockSamples = [samplesTrigger(indBlockEnds), samplesTrigger(end)] 

startBlocksSec = timeStartBlockSamples /Fs;
endBlocksSec = timeEndBlockSamples /Fs;

triggerFromFirstSec = (samplesTrigger - samplesTrigger(1))/Fs;
%figure;stem(triggerFromFirstSec)
