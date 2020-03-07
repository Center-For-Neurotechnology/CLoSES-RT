function [sCoreParams, variantConfig] = ConfigurationFile_NHP_Continuous_AlphaPower(sCoreParams, variantConfig)
% This file contains the specific configuration for an experiment

% This configuration is to trigger stimulation when power in ALPHA band *increases*
% relative to a baseline .

% It can be configured for each patient - CHANGE NAME to: ConfigXXX_PATIENTNAME.m
% File must be on Path (ideally in Configuration folder)
%
% Default is CONTINUOUS default (No Task) with baseline based threshold re-computed every 2 minutes (this we might want to change to after N
% stimulations)
%
% Specific parameters (probably the only ones to modify)
%
% Parameters:
% - sCoreParams.decoders.txDetector.channel1 / 2                % Contact numbers from NSP
% - sCoreParams.decoders.txDetector.txRMS = 2.5;                % How many times above Th
% - sCoreParams.decoders.txDetector.txSign =1;                  % +1 = Above Th / -1=Below Th
% - sCoreParams.decoders.txDetector.nDetectionsRequested = 3;   % How many consecutive detection needed for stimulation
% - sCoreParams.decoders.txDetector.detectionDurationSec = 3;   % For how long should we try to detect after trigger
% - sCoreParams.Features.Baseline.initialThresholdValue = 0;      % Could be used to specify a fix or initial value of threshold (e.g.: to have same value during the whole experiment specify value here and set sCoreParams.Features.Baseline.weightPreviousThreshold=1)
% - sCoreParams.Features.Baseline.weightPreviousThreshold = 0.1; % Indicate the weight of the previous threshold. newTh =(1-weight)* Th + weightPreviousThreshold * PrevTh
% - sCoreParams.Features.Baseline.durationSec = 10;             % duration of baseline segment in seconds 
%
% Variant Selection:
% - freqBandName = 'HIGHGAMMA';         % Options: THETA / ALPHA / BETA / LOWGAMMA / HIGHGAMMA / HIGHGAMMARIPPLE / RIPPLE
% - featureName =  'SMOOTHBANDPOWER';   % Options: SMOOTHBANDPOWER / VARIANCEOFPOWER / COHERENCE 
% - stimulationType = 'REALTIME';       % Options: REALTIME / NEXTTRIAL
% - detectorType = 'CONTINUOUS';        % Options: CONTINUOUS /TRIGGER / MULTISITE / IED
% - triggerType = 'FIXEDPERIOD';        % Options: EEGDATA / FIXEDPERIOD / FOLLOWINGSTIM
%
% NOTE: Do NOT modify Inputs or outputs
%
% If you need to modify additional parameters look in file InitCoreParams.m for defaults and parameters names
% @Rina Zelmann 2016

%%%%%%%%%%

%% Core
sCoreParams.core.NumberNSPs = 1;            % Number of NSPs available (@ MGH=2 /at BW=1)
sCoreParams.core.maxChannelsPerNSP = 32 * sCoreParams.core.NumberNSPs;   % max number of NSP channels (considering both NSPs)
sCoreParams.core.samplingRate = 1000;       % sampling rate of DAQ 
sCoreParams.core.maxChannelsTriggers = sCoreParams.core.maxChannelsPerNSP; % Same in both

%% Bipolar Channels -
% We could have N (default 10) channels as long as channel1 & channel2 consist of vectors (bipolar channels are channel1[i]-channel2[i]) 
% channel1 & channel2 are contact numbers from NSP 
sCoreParams.decoders.txDetector.channel1 = 1:sCoreParams.decoders.txDetector.MaxNumberChannels; %[1:sCoreParams.core.maxChannelsPerNSP-1]; %[1 2];
sCoreParams.decoders.txDetector.channel2 = [2:sCoreParams.decoders.txDetector.MaxNumberChannels+1]; 
sCoreParams.decoders.txDetector.triggerChannel = 16; % Channel were digital input corresponding to image onset is (usually: 129 - for simulation: 201)  
sCoreParams.decoders.txDetector.stimTriggerChannel = sCoreParams.decoders.txDetector.triggerChannel; %use same trigger for image onset and stim trigger

%Control Stimulation
sCoreParams.decoders.chanceDetector.useChanceDetector = 1;      % Whether to use a Random (Sham) Detector
sCoreParams.decoders.chanceDetector.randStimEventsPerSec = 50;  % how many Random Events per second to send (proba =  step /stimProbabilitySec)
sCoreParams.decoders.txDetector.ProbabilityOfStim = .75;        % Given a detected event, what is the proba of actually sending a stimulation pulse


%Do not change this line:
sCoreParams.decoders.txDetector.nChannels = min(length(sCoreParams.decoders.txDetector.channel1),length(sCoreParams.decoders.txDetector.channel2));
%%%%%%%%%%

%% Features and Thresholds
freqBandName = 'ALPHA';         % Options: THETA / ALPHA / BETA / LOWGAMMA / HIGHGAMMA / HIGHGAMMARIPPLE / RIPPLE
featureName =  'SMOOTHBANDPOWER';    % Options: SMOOTHBANDPOWER / VARIANCEOFPOWER / COHERENCE 

% Baseline
% For FIX Threshold: set weightPreviousThreshold=1; initialThresholdValue= desired Threshold
sCoreParams.Features.Baseline.weightPreviousThreshold = 0.1; % Indicate the weight of the previous threshold. newTh =(1-weight)* Th + weightPreviousThreshold * PrevTh
sCoreParams.Features.Baseline.initialThresholdValue = 0.005;  % Threshold is really this value x sCoreParams.decoders.txDetector.txRMS - Could be used to specify a fix or initial value of threshold (e.g.: to have same value during the whole experiment specify value here and set sCoreParams.Features.Baseline.weightPreviousThreshold=1)
sCoreParams.Features.Baseline.durationSec = 5;         % duration of baseline segment in seconds (e.g. baseline is from 0.5-delayAfterTrigger sec before trigger until trigger +delayAfterTrigger)

%% Triggers
triggerType = 'FIXEDPERIOD';                % Options: EEGDATA / FIXEDPERIOD / FOLLOWINGSTIM
sCoreParams.triggers.periodSec = 60;       % FIXED baseline computation - every 1 minute recompute baseline
%sCoreParams.triggers.numStimulations = 5;  % After HOW many stimulations should we compute baseline again (if in stim based triggers)
%sCoreParams.Features.Baseline.delayAfterTrigger = 0; %delay in samples after trigger to consider baseline  - probably a good idea if computing baseline after STIM
%sCoreParams.decoders.txDetector.delayAfterTriggerSec = 0;   % When to start detecting after Detection Trigger - probably a good idea if computing baseline after STIM

%%%%%%%%%%

%% Detections 
detectorType = 'CONTINUOUS';        % Options: CONTINUOUS /TRIGGER / MULTISITE / IED
% Indexes of Channels/Pairs used for detection:
sCoreParams.decoders.txDetector.detectChannelInds = 1:sCoreParams.decoders.txDetector.nChannels; % use vector of bipolar channels for power feature / use vector of index of pairs for coherence (e.g. [1,2] is 1-2, 1-3 pairs) - pairs are sorted by first channel
sCoreParams.decoders.txDetector.txRMS = 2.5;                % Times above/below Threshold when detection occurs
sCoreParams.decoders.txDetector.txSign = 1;                 % 1 means above threshold / -1 means below threshold
%sCoreParams.decoders.txDetector.nDetectionsRequested = 25;   % Number of consecutive detections required to produce a stiulation (idea of only detecting if feature is large for a certain duration)
sCoreParams.decoders.txDetector.nDetectionsRequestedmSec = 25;   % duration in ms of consecutive detections required to produce a stiulation (idea of only detecting if feature is large for a certain duration)
sCoreParams.decoders.txDetector.anyAll = 0;                 % ANY(or) = 0 / ALL(and) = 1
sCoreParams.decoders.txDetector.delayAfterStimSec = 0.5;         % delay in Seconds after Stimulation occur (to avoid stim artifact being detected)

%%%%%%%%%

%% Stimuation Parameters
stimulationType = 'REALTIME';                  % Options: REALTIME / NEXTTRIAL
removeStim = 'PASSSIGNAL';                     %Options:  PASSSIGNAL / REMOVESTIMFREQ

sCoreParams.stimulator.startupTimeSec = 10;     % Wait in seconds before allowing stimulation
sCoreParams.stimulator.refractoryPeriodSec = 5; % Refractory period in second (most important for real time stim, not for Next trial stim)

%%%%%%%%%%

%% Visualization
sCoreParams.viz.channelInds = 1:min(sCoreParams.viz.MaxNumberChannels, sCoreParams.decoders.txDetector.nChannels);  %First channels - can be changed afterwards keeping the same number
sCoreParams.viz.featureInds = 1:length(sCoreParams.decoders.txDetector.detectChannelInds); %Change to pairs for coherence!

%% Variants CONFIG - DO NOT CHANGE HERE
variantConfig = selectFrequencyBandConfig(freqBandName, variantConfig);
[variantConfig, sCoreParams] = selectFeatureConfig(featureName, variantConfig, sCoreParams);
variantConfig = selectDetectorConfig(detectorType, variantConfig, featureName);
variantConfig = selectWhenToStimulate(stimulationType, variantConfig, detectorType);
variantConfig = selectTriggerTypeConfig(triggerType, variantConfig);
[variantConfig] = selectWhetherToRemoveStimulationArtifact(removeStim, variantConfig);

%%%%%%%%%%

%% DO NOT REMOVE THIS LINE!
sCoreParams = InitCoreParams_Dependent(sCoreParams);
