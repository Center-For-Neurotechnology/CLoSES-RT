function [sCoreParams, variantConfig] = ConfigurationFile_Continuous_Alpha_AboveBelow(sCoreParams, variantConfig)
% This file contains the specific configuration for an experiment during SLEEP/eyes closed-opened
% The idea is to detect sleep spindles and send stimulation trigger after 200samples
%
% This configuration is to trigger stimulation when power in ALPHA band (8-15Hz) *increases*
% relative to a baseline that is computed every 1 minute.
%
% It can be configured for each patient - CHANGE NAME to: ConfigXXX_PATIENTNAME.m
% File must be on Path (ideally in Configuration folder)
%
% Default is CONTINUOUS default (No Task) with baseline based threshold re-computed every 1 minute (this we might want to change to after N stimulations)
%
% Specific parameters (probably the only ones to modify)
%
% Parameters:
% - sCoreParams.decoders.txDetector.channel1 / 2                    % Contact numbers from NSP
% - sCoreParams.decoders.txDetector.txRMS = 2;                      % How many times above Th
% - sCoreParams.decoders.txDetector.txRMSLower = 5;                 % 1/Times below Threshold when detection occurs
% - sCoreParams.decoders.txDetector.txSign = 1;                     % +1 = Above Th / -1=Below Th
% - sCoreParams.decoders.txDetector.nDetectionsRequested = 200;     % How many consecutive detection needed for stimulation
% - sCoreParams.Features.Baseline.initialThresholdValue = 0;        % Could be used to specify a fix or initial value of threshold (e.g.: to have same value during the whole experiment specify value here and set sCoreParams.Features.Baseline.weightPreviousThreshold=1)
% - sCoreParams.Features.Baseline.weightPreviousThreshold = 0.25;   % Indicate the weight of the previous threshold. newTh =(1-weight)* Th + weightPreviousThreshold * PrevTh
% - sCoreParams.Features.Baseline.durationSec = 10;                 % duration of baseline segment in seconds 
% - sCoreParams.triggers.periodSec = 60;                            % FIXED baseline computation - every 2 minutes recompute baseline
% - sCoreParams.stimulator.stimChannelUpper = [1,2];                % Which channel to stim on when Feature is above UpperThreshold (ONLY used for MULTISITE stim)
% - sCoreParams.stimulator.stimChannelLower = [3,4];                % Which channel to stim on when Feature is below LowerThreshold (ONLY used for MULTISITE stim) - (Default same channels for Lower and Upper)
%
% Variant Selection:
% - freqBandName = 'ALPHA';             % Options: THETA (4-8) / ALPHA (8-15) / BETA (15-30) / LOWGAMMA (30-55) / HIGHGAMMA (65-110) / HIGHGAMMARIPPLE (65-200) / RIPPLE (140-200) / GAMMA (30-110) /SPINDLES (12-16) / NOFILTER
% - featureName =  'SMOOTHBANDPOWER';   % Options: SMOOTHBANDPOWER / VARIANCEOFPOWER / COHERENCE 
% - stimulationType = 'REALTIME';       % Options: REALTIME / NEXTTRIAL
% - detectorType = 'MULTISITE';         % Options: CONTINUOUS /TRIGGER / MULTISITE / IED
% - triggerType = 'FIXEDPERIOD';        % Options: EEGDATA / FIXEDPERIOD / FOLLOWINGSTIM / FOLLOWSTIMORFIXED
%
% NOTE: Do NOT modify Inputs or outputs
%
% If you need to modify additional parameters look in file InitCoreParams.m for defaults and parameters names
% @Rina Zelmann 2016

%%%%%%%%%%
%% Bipolar Channels -
% We could have N (default 10) channels as long as channel1 & channel2 consist of vectors (bipolar channels are channel1[i]-channel2[i]) 
% channel1 & channel2 are contact numbers from NSP 
sCoreParams.decoders.txDetector.channel1 = 1:sCoreParams.decoders.txDetector.MaxNumberChannels; %[1:sCoreParams.core.maxChannelsPerNSP-1]; %[1 2];
sCoreParams.decoders.txDetector.channel2 = [2:sCoreParams.decoders.txDetector.MaxNumberChannels+1]; 

%Do not change this line:
sCoreParams.decoders.txDetector.nChannels = min(length(sCoreParams.decoders.txDetector.channel1),length(sCoreParams.decoders.txDetector.channel2));
%%%%%%%%%%

%% Features and Thresholds
freqBandName = 'ALPHA';         % Options: THETA (4-8) / ALPHA (8-15) / BETA (15-30) / LOWGAMMA (30-55) / HIGHGAMMA (65-110) / HIGHGAMMARIPPLE (65-200) / RIPPLE (140-200) / GAMMA (30-110) /SPINDLES (12-16) / NOFILTER
featureName =  'SMOOTHBANDPOWER';   % Options: SMOOTHBANDPOWER / VARIANCEOFPOWER (never used) / COHERENCE 

% Baseline
% For FIX Threshold: set weightPreviousThreshold=1; initialThresholdValue= desired Threshold
sCoreParams.Features.Baseline.weightPreviousThreshold = 0.1;    % Indicate the weight of the previous threshold. newTh =(1-weight)* Th + weightPreviousThreshold * PrevTh
sCoreParams.Features.Baseline.initialThresholdValue = 0;        % Threshold is really this value x sCoreParams.decoders.txDetector.txRMS - Could be used to specify a fix or initial value of threshold (e.g.: to have same value during the whole experiment specify value here and set sCoreParams.Features.Baseline.weightPreviousThreshold=1)
sCoreParams.Features.Baseline.durationSec = 10;                  % duration of baseline segment in seconds (e.g. baseline is from 0.5-delayAfterTrigger sec before trigger until trigger +delayAfterTrigger)

%% Triggers
triggerType = 'FIXEDPERIOD';                % Options: EEGDATA / FIXEDPERIOD / FOLLOWINGSTIM / FOLLOWSTIMORFIXED
sCoreParams.triggers.periodSec = 60;                % FIXED baseline computation - every 2 minutes recompute baseline
%sCoreParams.triggers.numStimulations = 5;          % After HOW many stimulations should we compute baseline again (if in stim based triggers)
sCoreParams.triggers.initialTriggerSec = 10;        % How long to wait for the first threshold computation

%%%%%%%%%%

%% Detections 
detectorType = 'MULTISITE';        % Options: CONTINUOUS /TRIGGER / MULTISITE / IED
% Indexes of Channels/Pairs used for detection:
sCoreParams.decoders.txDetector.detectChannelInds = 1:sCoreParams.decoders.txDetector.nChannels; % use vector of bipolar channels for power feature / use vector of index of pairs for coherence (e.g. [1,2] is 1-2, 1-3 pairs) - pairs are sorted by first channel
sCoreParams.decoders.txDetector.txRMS = 2;                      % Times above/below Threshold when detection occurs
sCoreParams.decoders.txDetector.txRMSLower = 5;                 % 1/Times below Threshold when detection occurs

sCoreParams.decoders.txDetector.txSign = 1;                     % 1 means above threshold / -1 means below threshold
%sCoreParams.decoders.txDetector.nDetectionsRequested = 200;     % Number of consecutive detections required to produce a stiulation (idea of only detecting if feature is large for a certain duration)
sCoreParams.decoders.txDetector.nDetectionsRequestedmSec = 100;   % duration in ms of consecutive detections required to produce a stiulation (idea of only detecting if feature is large for a certain duration)
sCoreParams.decoders.txDetector.anyAll = 1;                     % ANY(or) = 0 / ALL(and) = 1

% Baseline
sCoreParams.Features.Baseline.weightPreviousThreshold = 0.25;    % Indicate the weight of the previous threshold. newTh =(1-weight)* Th + weightPreviousThreshold * PrevTh
sCoreParams.Features.Baseline.initialThresholdValue = 0;        % Threshold is really this value x sCoreParams.decoders.txDetector.txRMS - Could be used to specify a fix or initial value of threshold (e.g.: to have same value during the whole experiment specify value here and set sCoreParams.Features.Baseline.weightPreviousThreshold=1)

%Control/Chance Stimulation
sCoreParams.decoders.chanceDetector.useChanceDetector = 1;      % Whether to use a Random (Sham) Detector
sCoreParams.decoders.chanceDetector.randStimEventsPerSec = 10;  % how many Random Events per second to send (proba =  step /stimProbabilitySec)
sCoreParams.decoders.txDetector.ProbabilityOfStim = .75;        % Given a detected event, what is the proba of actually sending a stimulation pulse

%%%%%%%%%

%% Stimulation Parameters
stimulationType = 'REALTIME';                   % Options: REALTIME / NEXTTRIAL
sCoreParams.stimulator.startupTimeSec = 10;                 % Wait in seconds before allowing stimulation
sCoreParams.stimulator.refractoryPeriodSec = 5;             % Refractory period in second (most important for real time stim, not for Next trial stim)
sCoreParams.decoders.txDetector.delayAfterStimSec = 0.5;    % delay in Seconds after Stimulation occur (to avoid stim artifact being detected)

% MultiSite Channel configuretion (for OLD CereStim cable use 1-2 and 3-4, for new CereStim cable specify channel numbers)
%IF stiming on same channel it is not necessary to modify this since it is enough with sending a TTL at each stim - stim channel is still sent on parallel port 5-8
%sCoreParams.stimulator.stimChannelUpper = [1,2];    % Which channel to stim on when Feature is above UpperThreshold (ONLY used for MULTISITE stim)
%sCoreParams.stimulator.stimChannelLower = [3,4];    % Which channel to stim on when Feature is below LowerThreshold (ONLY used for MULTISITE stim) - (Default same channels for Lower and Upper)
%sCoreParams.stimulator.controlCerestimFromHost = true; % use host to change CERESTIM CONFIGURATION (only for ECR) - Still needs to send TTL pulse!
%%%%%%%%%%

%% Stimulation Artifact
removeStim = 'PASSSIGNAL';                      % Options:  PASSSIGNAL / REMOVESTIMFREQ - usually PASSSIGNAL since it is single pulse stim
sCoreParams.stimulator.amplitude_mA = 7;        % Stimulation amplitude (1mA) - not used but useful to have in saved Data

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
