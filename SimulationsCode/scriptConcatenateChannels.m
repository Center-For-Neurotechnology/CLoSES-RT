
%% P5
dirGralData = 'C:\DATA\Simulations'; 
pName = 'P5';

fileNamesInput{1} = [dirGralData, filesep, 'P5_NSP1_2ch_NSX_002','.mat'];
fileNamesInput{2} = [dirGralData, filesep, 'P5_NSP2_3ch_NSX_002','.mat'];


%% Concatenate all channels
fileNameOutput = [dirGralData, filesep, pName,'_bothNSPs','_5ch','.mat'];
concatenateChannelsSimulatedData(fileNamesInput, fileNameOutput, pName)


%% Select some Channels and concatenate
