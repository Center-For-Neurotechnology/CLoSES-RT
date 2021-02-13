function [sCoreParams] = InitCoreParamsPlexon(sCoreParams)
% Additional parameters specific to Plexon (NHPs) experiments
% - Plexon Acqusition
% - Stimulation
% Spontaneous detection (or move to general InitCoreParams??)

%% sCoreParams
% Plexon Comfiguration
%sCoreParams.plexon.plexonID = 0; %PLEXON Server ID - It should be initialized as: plexonID = PL_InitClient(0); - Needs to be done before running model!
%RIZ: Could we initilize also the stimulator?

%% Core
sCoreParams.core.NumberNSPs = 1;            % Number of NSPs available (@ MGH=2 /at BW=1)
sCoreParams.core.maxChannelsPerNSP = 32 * sCoreParams.core.NumberNSPs;   % max number of NSP channels (considering both NSPs)
sCoreParams.core.samplingRate = 1000;       % sampling rate of DAQ 
sCoreParams.core.maxChannelsTriggers = sCoreParams.core.maxChannelsPerNSP; % Same in both

%% Processing
% Channels
sCoreParams.decoders.txDetector.MaxNumberChannels = min(10,sCoreParams.core.maxChannelsPerNSP); %How many channels can we analize at a given time - WHICH ones can change - total number is FIX
sCoreParams.decoders.txDetector.channel1 = [1:5]; %[1:sCoreParams.core.maxChannelsPerNSP-1]; %[1 2];
sCoreParams.decoders.txDetector.channel2 = [2:6]; %[2 3];
sCoreParams.decoders.txDetector.triggerChannel = 32; % Channel were digital input corresponding to image onset is (usually: 129 - for simulation: 201)  
sCoreParams.decoders.txDetector.stimTriggerChannel = 32;% Channel were digital input corresponding to STIM trigger is (usually idem trigger channel = image onset is (usually: 129 - for simulation: 201)  
sCoreParams.decoders.txDetector.nChannels = min(length(sCoreParams.decoders.txDetector.channel1),length(sCoreParams.decoders.txDetector.channel2));
sCoreParams.viz.channelInds = 1:min(sCoreParams.viz.MaxNumberChannels, sCoreParams.decoders.txDetector.nChannels);  %First channels - can be changed afterwards keeping the same number
sCoreParams.viz.featureInds = sCoreParams.viz.channelInds;                              % Change to nPairs if using COHERENCE! see how to do in real time!!
sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nChannels;  % Change to nPairs if using COHERENCE! see how to do in real time!!

sCoreParams.decoders.txDetector.delayAfterStimSec = 0.1;         % delay in Seconds after Stimulation occur (to avoid stim artifact being detected)

% Triggers - only use defaults if they are not provided
sCoreParams.triggerThresholdValue = 0.2;              % Check Trigger value if using EEGData - otherwise it is a logical/counter output and it is 1.
sCoreParams.triggers.numStimulations = 5;             % After HOW many stimulations should we compute baseline again (if in stim based triggers)
sCoreParams.triggers.periodSec = 60;                 % FIXED baseline computation - every minute recompute baseline

%Baseine - Compute baseline continuously at the beggining and make length of baseline long (for trial based it is only 500ms)
sCoreParams.Features.Baseline.durationSec = 5; %Use 5 second baseline segments
sCoreParams.Features.Baseline.beforeFirstTrigger = 1; % Compute baseline continuously before first trigger (otherwise there will be NO threshold computed before STIm, and thus there will not be a thrshold computed ever)
sCoreParams.Features.Baseline.weightPreviousThreshold = 0.5; %Give 50/50 importnace to previous current baseline - Indicate the weight of the previous threshold. newTh =(1-weight)* Th + weightPreviousThreshold * PrevTh

%Stimulation
sCoreParams.StimulationFrequencyHz = 60; %RIZ: SINGLE PULSE Stimulation -> write as 60Hz to have a second notch at 60 - RIZ: it DOES not make sense!!
sCoreParams.stimulator.trainDuration = 60;  %As long as frequency and duratio are the same, it generates a SINGLE PULSE

%% Do NOT MODIFY
sCoreParams = InitCoreParams_Dependent(sCoreParams);

