function concatenateChannelsSimulatedData(fileNamesInput, fileNameOutput, pName)
 
% Concatenates data for simulation (replay) obtained from different NSPs
% We can assume that they are synchronozie since they are created based on image onset from each NSP
% 

% dirGralData = '/Users/rzelmann/Dropbox (Partners HealthCare)/TRANSFORM/Data for Rina/LFP test';
% pName = 'MG106';
% dirFiles = [dirGralData, filesep,pName,filesep,'Simulations'];
% graFileName = [pName,'_Left_25ch'];
% 
% fileNamesOutput = [dirFiles, filesep,graFileName,'_allTrials.mat'];


EEGVals = [];
timeVals = [];
triggerVals =[];
channelNames=[];
nChannels=0;
channel1=[];
channel2=[];
for iFile=1:length(fileNamesInput)    
    stData = load(fileNamesInput{iFile});

    % check that triggerVals are the same ?
%     if ~isempty(triggerVals) && sum(diff(triggerVals,stData.triggerVals))>eps
%         disp('Different Trigger vals in files! exiting...');
%         return;
%     end
    
    channel1 = [channel1, stData.channel1+nChannels];
    channel2 = [channel2, stData.channel2+nChannels];
    channelNames = [channelNames, stData.channelNames];
    channelNumbersInNSX{iFile} = stData.channelNumbersInNSX;
    chNumberTrigger{iFile} = stData.chNumberTrigger;
    nChannels = nChannels+stData.nChannels;
    startNSxSec{iFile} = stData.startNSxSec;
    endNSxSec{iFile} = stData.endNSxSec;
    hdr{iFile} = stData.hdr;
    
    % concatenate EEG data
    if ~isempty(triggerVals)
        minLen = min(length(triggerVals),length(stData.triggerVals));
        EEGVals = [EEGVals(:,1:minLen); stData.EEGVals(:,1:minLen)];
    else
        minLen = length(stData.triggerVals);
        EEGVals =  stData.EEGVals;
    end
    timeVals = stData.timeVals;
    triggerVals = stData.triggerVals(:,1:minLen); % trigger data should be the same!
    
end

save (fileNameOutput, 'channel1','channel2','channelNames','channelNumbersInNSX','chNumberTrigger','EEGVals','endNSxSec','fileNamesInput','hdr','nChannels','pName','startNSxSec','timeVals','triggerVals');


