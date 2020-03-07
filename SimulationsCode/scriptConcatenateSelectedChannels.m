

dirGralData = 'C:\Data\CLoSES-SEM\ExampleData\DEMO\Simulations\P3_Behavior'; 
pName = 'P3';

fileNamesInput{1} = [dirGralData, filesep, 'P3_NSP1_25ch_NSX_001_trigsFromNEV','.mat'];
fileNamesInput{2} = [dirGralData, filesep, 'P3_NSP1_25ch_NSX_002_trigsFromNEV','.mat'];
    
fileNameChannels = [dirGralData, filesep, 'P3_decoder_model','.mat'];

%% Select some Channels and concatenate
stChannelNamesInput = load(fileNameChannels,'channel_list');
nChanns = size(stChannelNamesInput.channel_list,1);

% NSP1
fileNameOutput = [dirGralData, filesep, pName,'_NSP1','_ch','.mat'];
keepSelectedChannelsSimulatedData(fileNamesInput{1}, fileNameOutput, pName, stChannelNamesInput.channel_list)


%% Concatenate all channels
fileNameOutput = [dirGralData, filesep, pName,'_bothNSPs','_',num2str(nChanns),'ch','.mat'];
concatenateChannelsSimulatedData(fileNamesInput, fileNameOutput, pName)

