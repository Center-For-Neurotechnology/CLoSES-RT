function [EEGData, NSPTime] = readPlexon(plexonID)

data = zeros(1,130);
tInitialPtSec=0;
[nChannels, tInitialPtSec, data] = coder.extrinsic(PL_GetADV(plexonID)); %This is what let me get data from our ephys system % Output: is in VOLTS

EEGData = data(:,129:end);  % Only keep LFP channels
NSPTime = tInitialPtSec;    % Check
