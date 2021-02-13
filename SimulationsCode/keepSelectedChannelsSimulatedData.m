function keepSelectedChannelsSimulatedData(fileNameInput, fileNameOutput, pName, channelNamesInput)
 
% Only keep selected channels from fileNameInput and saves it in fileNameOutput
% 
% Example inputs:
%   dirFiles = [dirGralData, filesep,pName,filesep,'Simulations'];
%   fileNameInput = [dirFiles, filesep,graFileName,'_allTrials.mat'];
%   fileNameOutput = [dirFiles, filesep,graFileName,'_allTrials_someCh.mat'];
%   pName = 'P1';
%   channelNamesInput = {'Ch1-Ch2','Ch3-Ch4'};
% 

% Get individual channels names
splitChNamesBipolar = split(channelNamesInput,' ');
if length(size(splitChNamesBipolar))>2 % check if it needs to traspose
    splitChNamesBipolar = split(channelNamesInput',' ');
end


% Load file
stData = load(fileNameInput);
% Channels of interest
allChNamesInFile = stData.channelNames;
ch1NamesInFile = allChNamesInFile(stData.channel1);
ch2NamesInFile = allChNamesInFile(stData.channel2);
% Find corresponding bipolar channels in stData.
for iCh =1:size(splitChNamesBipolar,1)
        chNumber1 = find(strncmpi(ch1NamesInFile, splitChNamesBipolar{iCh,1},length(splitChNamesBipolar{iCh,1})),1);
        chNumber2 = find(strncmpi(ch2NamesInFile, splitChNamesBipolar{iCh,2},length(splitChNamesBipolar{iCh,2})),1);
    if ~isempty(chNumber1) && (chNumber1==chNumber2)
        indCh(iCh) = chNumber1;
        channel1(iCh) = chNumber1;
        channel2(iCh) = chNumber2;
        isChannelInFile(iCh) = 1; % indicates whether channel is in  file
        channelNumbersInChannelName(iCh) = iCh;
    else
        disp(['No corresponding channel in file ',fileNameInput,' for channelName = ',splitChNamesBipolar{iCh,1},' ',splitChNamesBipolar{iCh,2}]);
    end
end

    
    channelNumbersInFile = stData.channelNumbersInNSX(indCh);
    chNumberTrigger = stData.chNumberTrigger;
    nChannels = length(channel1);
    
    startNSxSec = stData.startNSxSec;
    endNSxSec = stData.endNSxSec;
    hdr = stData.hdr;
    
    % Keep EEG data of selected channels
    EEGVals = stData.EEGVals(channelNumbersInFile,:);
    
    timeVals = stData.timeVals;
    triggerVals = stData.triggerVals; % trigger data should be the same!
    

save (fileNameOutput, 'channel1','channel2','channelNames','channelNumbersInNSX','chNumberTrigger','EEGVals','endNSxSec','fileNamesInput','hdr','nChannels','pName','startNSxSec','timeVals','triggerVals');


