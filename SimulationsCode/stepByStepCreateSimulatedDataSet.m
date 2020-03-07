% stepByStepCreateSimulatedDataSet
gralDir =  'C:\DATA';
gralDirChannels = 'C:\DATA'; 

pName = 'P1';
ainChNames =  {'ainp2','ainp2'};%{'IMAGE', 'IMAGE'}; %
NSXnumber = '001';

%gralDirPatient = [gralDir,filesep,pName,filesep,'MSIT_STIM'];
fileNameNSxLeft = [gralDir, filesep,'NSP1', filesep, 'P1_d06-',NSXnumber,'.ns3'];
fileNameNSxRight = [gralDir,filesep,pName, filesep, 'NSP2', filesep, 'P1_d06-',NSXnumber,'.ns3'];

simulationsDirName = [gralDirChannels,filesep, pName, filesep, 'Simulations'];
if ~exist(simulationsDirName,'dir'), mkdir(simulationsDirName); end
fileNameChannelNames = [gralDirChannels, filesep, pName, '_channels.mat'];

%% Obtain Channels of Interest
stChannelNames = load(fileNameChannelNames);
chBipolarLeft = stChannelNames.left_channels;
chBipolarRight = stChannelNames.right_channels;

%% ******** NSP1 *****************
%% Find Left Triggers from AINP and RUN simulation - LEFT
[startBlocksSecLeft, endBlocksSecLeft, chNumberTriggerLeft] = findExperimentTimeToCreateSimulatedDataset(fileNameNSxLeft, 0, ainChNames{1});

startNSxSec = startBlocksSecLeft(1) - 10; % data strats 10 seconds before first trigger
endNSxSec = endBlocksSecLeft(end) + 10; % data strats 60 seconds after last trigger of first block
simMATFileName = [simulationsDirName,filesep,pName, '_NSP1_',num2str(length(chBipolarLeft)),'ch_NSX_',NSXnumber,'_trigsFromAINP.mat'];
script_createSimDataFromNEVfile(fileNameNSxLeft, simMATFileName, chBipolarLeft, chNumberTriggerLeft, startNSxSec, endNSxSec, 1, triggerVals)

%% Get trigger values from NEV instead of from ainp - LEFT
[triggerVals, ImageOn]= getTriggerInfoFromNEVfile(fileNameNSxLeft);

startNSxSec = max(0, ImageOn(1)/2000 - 10); % data strats 10 seconds before first trigger
endNSxSec = (ImageOn(end)/2000) + 10; % data strats 60 seconds after last trigger of first block
simMATFileName = [simulationsDirName,filesep,pName, '_NSP1_',num2str(length(chBipolarLeft)),'ch_NSX_',NSXnumber,'_trigsFromNEV.mat'];
script_createSimDataFromNEVfile(fileNameNSxLeft, simMATFileName, chBipolarLeft, [], startNSxSec, endNSxSec, 1, triggerVals)


%% ******** NSP2 *****************
%% Find Triggers from AINP and RUN simulation - RIGHT
[startBlocksSecRight, endBlocksSecRight, chNumberTriggerRight] = findExperimentTimeToCreateSimulatedDataset(fileNameNSxRight, 0, ainChNames{1});

startNSxSec = startBlocksSecRight(1) - 10; % data strats 10 seconds before first trigger
endNSxSec = endBlocksSecRight(end) + 10; % data strats 60 seconds after last trigger of first block
simMATFileName = [simulationsDirName,filesep,pName, '_NSP2_',num2str(length(chBipolarRight)),'ch_NSX_',NSXnumber,'_trigsFromAINP.mat'];
script_createSimDataFromNEVfile(fileNameNSxRight, simMATFileName, chBipolarRight, chNumberTriggerRight, startNSxSec, endNSxSec, 1, triggerVals)

%% Get trigger values from NEV instead of from ainp - RIGHT
[triggerVals, ImageOn]= getTriggerInfoFromNEVfile(fileNameNSxRight);

startNSxSec = max(0, ImageOn(1)/2000 - 10); % data strats 10 seconds before first trigger
endNSxSec = (ImageOn(end)/2000) + 10; % data strats 60 seconds after last trigger of first block
simMATFileName = [simulationsDirName,filesep,pName, '_NSP2_',num2str(length(chBipolarRight)),'ch_NSX_',NSXnumber,'_trigsFromNEV.mat'];
script_createSimDataFromNEVfile(fileNameNSxRight, simMATFileName, chBipolarRight, [], startNSxSec, endNSxSec, 1, triggerVals)
