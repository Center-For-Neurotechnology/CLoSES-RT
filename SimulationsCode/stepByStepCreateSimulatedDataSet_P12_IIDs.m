% LAB PC
dirGral = 'E:\DATA\ClosedLoopPhysiology\Patients'; 

%% Patient Name
pName = 'P12';

%% Directories and Files
dirGralResults =  [dirGral, filesep, pName, filesep, 'ResultsAnalysis']; 
dirGralData = [dirGral, filesep, pName, filesep, 'ClosedLoopPhysiology_IIDs_STIM'];
if ~exist(dirGralResults,'dir'), mkdir(dirGralResults); end
simulationsDirName = [dirGral, filesep, pName, filesep, 'Simulations',filesep,'IIDsSimulationDataset'];

fileNameNSxPerNSP{1} = [dirGralData, filesep,'NSP1',filesep,'ds1',filesep,'ds1-010','.ns3'];

%% CHANNELS
stimAINP.chNames = {'ainp1','ainp5','ainp7'}; % % all stim, detected stim, random stim - 'SYNC'=ainp1,'SEND STIM'=ainp3,'SHAM'=ainp4,'DETECTED'=ainp5
stimAINP.chRealNames = {'STIM','DETECT','RANDOM','SEND STIM'}; % % all stim, detected stim, random stim - 'SYNC'=ainp1,'SEND STIM'=ainp3,'SHAM'=ainp4,'DETECTED'=ainp5


if ~exist(simulationsDirName,'dir'), mkdir(simulationsDirName); end

%% Obtain Channels of Interest
%Channels
recChannInfo.pName =pName;
recChannInfo.chNames = {'RPH01','RPH04','RPH05','RAH1','RAH2','RAH3','LAH1','LAH2'}; 
recChannInfo.chNumberBipolar = [1,2;2,3;4,5;5,6;7,8];%;9,10;11,12;12,13];
recChannInfo.useBipolar =0;
recChannInfo.useAbsolute =0;

stimChannInfo.stimChNames = {'RPH02','RPH03'}; %,STIM in RPH02-3

%% Find  TRiggers -STIM
[startBlocksSecLeft, endBlocksSecLeft, chNumberTriggerLeft] = findExperimentTimeToCreateSimulatedDataset(fileNameNSxPerNSP{1}, 0, stimAINP.chNames{1});
triggerVals =[];

%% Get trigger values from NEV instead of from ainp
%[triggerVals, ImageOn]= getTriggerInfoFromNEVfile(fileNameNSxPerNSP{1});

%% All Blocks per File
startNSxSec = 0; %startBlocksSecLeft(1) - 30; % data strarts 30 seconds before first STIM
endNSxSec = endBlocksSecLeft(end) + 30; % data ends 30 seconds after last trigger of first block

simMATFileName = [simulationsDirName,filesep,pName, '_IIDs_stCh',stimChannInfo.stimChNames{1},'_detCh',recChannInfo.chNames{1},'.mat'];
script_createSimDataFromNEVfile(fileNameNSxPerNSP{1}, simMATFileName, recChannInfo.chNames, chNumberTriggerLeft, startNSxSec, endNSxSec, 0, triggerVals)


