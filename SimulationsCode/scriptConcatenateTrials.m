

dirGralData = 'D:\Data\';
pName = 'P1';
graFileName = [pName,'_NSP2_25ch']; 


dirFiles = [dirGralData, filesep,pName,filesep,'Simulations'];
fileNamesOutput = [dirFiles, filesep,graFileName,'_allTrials.mat'];

concatenateSimulatedData(dirFiles, pName, graFileName, fileNamesOutput)
