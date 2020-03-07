function concatenateSimulatedData(dirFiles, pName, gralFileName, fileNamesOutput)
 
% Concatenates data for simulation (replay) obtained from different NSX
% files that correspond to same channels
% This way all trials used for training are together.
%
% Example inputs:
%   dirFiles = [dirGralData, filesep,pName,filesep,'Simulations'];
%   pName = 'P1';
%   gralFileName = [pName,'_Left_25ch'];
%   fileNamesOutput = [dirFiles, filesep,graFileName,'_allTrials.mat'];

allSimulationFiles = dir(dirFiles);

indCHFile = find(strncmpi(gralFileName,{allSimulationFiles.name},length(gralFileName)));

fileNamesInput=cell(1,0);
for iFile=1:length(indCHFile)
    fileNamesInput{iFile} = [dirFiles, filesep, allSimulationFiles(indCHFile(iFile)).name];
end

EEGVals = [];
timeVals = [];
triggerVals =[];
channelNames=[];
for iFile=1:length(fileNamesInput)    
    stData = load(fileNamesInput{iFile});
    
    % check that channelNames are the same
    if ~isempty(channelNames) && ~all(strcmp(channelNames,stData.channelNames))
        disp('Different channel Names in files! exiting...');
        return;
    end
    channel1 = stData.channel1;
    channel2 = stData.channel2;
    channelNames = stData.channelNames;
    channelNumbersInNSX = stData.channelNumbersInNSX;
    chNumberTrigger = stData.chNumberTrigger;
    nChannels = stData.nChannels;
    startNSxSec(iFile) = stData.startNSxSec;
    endNSxSec(iFile) = stData.endNSxSec;
    hdr{iFile} = stData.hdr;
    
    % concatenate EEG data and trigger data
    EEGVals = [EEGVals, stData.EEGVals];
    timeVals = [timeVals, stData.timeVals];
    triggerVals = [triggerVals, stData.triggerVals];
    
end

save (fileNamesOutput, 'channel1','channel2','channelNames','channelNumbersInNSX','chNumberTrigger','EEGVals','endNSxSec','fileNamesInput','hdr','nChannels','pName','startNSxSec','timeVals','triggerVals');


