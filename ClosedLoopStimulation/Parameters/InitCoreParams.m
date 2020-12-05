function sCoreParams = InitCoreParams()
%% Version
sCoreParams.version.versionFull = 'CLoSES-RT.2020.03.02';
sCoreParams.version.mode = 'CLoSES-RT';
sCoreParams.version.releaseDate = '2020.03.02';
sCoreParams.version.versionNumber = '2020.03.02';

%% Core signal parameters (channels, sampling frequencies)
sCoreParams.core.stepPeriod = .001;         % sample time in sec 
sCoreParams.core.NumberNSPs = 2;% USE only 1 for DEMO! 2;            % Number of NSPs available (@ MGH=2 /at BW=1)
sCoreParams.core.numChannelsPerNSPs = 200;
sCoreParams.core.maxChannelsAllNSPs = sCoreParams.core.numChannelsPerNSPs * sCoreParams.core.NumberNSPs;   % max number of NSP channels (considering both NSPs)
sCoreParams.core.samplingRate = 2000;       % sampling rate of NSP  
sCoreParams.write.broadcastSec = .1;        %%RIZ: reduce to try to send more channels - original: .1;     MSIT 25 ch-> 0.05   
sCoreParams.core.maxChannelsTriggers = sCoreParams.core.maxChannelsAllNSPs; % Same in both

%%%%%%%%%%
%% Critical Session Parameters
sCoreParams.core.batchPeriod = 60;
sCoreParams.stimulator.startupTimeSec = 5; %20;

%% Bipolar Channels - ADDED RIZ
% We could have N channels as long as channel1 & channel2 consist of vectors (bipolar channels are channel1[i]-channel2[i]
sCoreParams.decoders.txDetector.MaxNumberChannels = 5; %How many channels can we analize at a given time - WHICH ones can change - total number is FIX
sCoreParams.decoders.txDetector.channel1 = 1:sCoreParams.decoders.txDetector.MaxNumberChannels; %[1:sCoreParams.core.maxChannelsAllNSPs-1]; %[1 2];
sCoreParams.decoders.txDetector.channel2 = [2:sCoreParams.decoders.txDetector.MaxNumberChannels+1]; %[2 3];
sCoreParams.decoders.txDetector.triggerChannel = 131; % Channel were analog input corresponding to image onset is (usually: 129 - for simulation: 201)  
sCoreParams.decoders.txDetector.stimTriggerChannel = 131;% Channel were analog input corresponding to STIM trigger is (usually idem trigger channel = image onset is (usually: 129 - for simulation: 201)  
sCoreParams.decoders.txDetector.nChannels = min(length(sCoreParams.decoders.txDetector.channel1),length(sCoreParams.decoders.txDetector.channel2));
sCoreParams.decoders.txDetector.behavioralChannel = 132; % Channel were analog input corresponding to behavioral state estimate data is (usually: above 132)  
sCoreParams.decoders.txDetector.behavioralMultiplier = 1/1000;
sCoreParams.decoders.txDetector.channelNames =  cellfun(@num2str,num2cell(1:sCoreParams.core.maxChannelsAllNSPs),'UniformOutput',false);

%% Detections 
sCoreParams.decoders.txDetector.detectChannelInds = 1:sCoreParams.decoders.txDetector.nChannels; %[1:sCoreParams.core.maxChannelsAllNSPs-1]; %RIZ: use vector of bipolar channels for power feature / use vector of index of pairs for coherence (e.g. [1,2] is 1-2, 1-3 pairs) - pairs are sorted by first channel

sCoreParams.decoders.txDetector.txRMS = 2.5;                % Number of time larger than computed threshold (Upper Limit for MultiSite Thresholds)
sCoreParams.decoders.txDetector.txRMSLower = 2.5;           % Lower limit ( only used for MultiSite Detection) -> Th value is DIVIDED by this number!
sCoreParams.decoders.txDetector.txSign = 1;                 % 1 means above threshold / -1 means below threshold
%sCoreParams.decoders.txDetector.nDetectionsRequested = 50;   % Number of consecutive detections required to produce a stiulation (idea of only detecting if feature is large for a certain duration)
sCoreParams.decoders.txDetector.nDetectionsRequestedmSec = 25;   % duration in ms of consecutive detections required to produce a stiulation (idea of only detecting if feature is large for a certain duration)
sCoreParams.decoders.txDetector.delayAfterTriggerSec = 0;   % When to start detecting after Detection (image onset) Trigger
sCoreParams.decoders.txDetector.detectionDurationSec = 1;   % For how long should we try to detect after trigger
sCoreParams.decoders.txDetector.anyAll = 0;                 % ANY(or) = 0 / ALL(and) = 1
%sCoreParams.decoders.txDetector.overrideTXbool = 0;
%sCoreParams.decoders.txDetector.overrideTXval = 100;
%sCoreParams.decoders.txDetector.realTimeUpdateThreshold = 1;

% Random (Sham) Detector (to generate random stimulation)
sCoreParams.decoders.chanceDetector.useChanceDetector = 0;      % Whether to use a Random (Sham) Detector (1=use Random detector / 0= DO NOT use random STIM)
sCoreParams.decoders.chanceDetector.randStimEventsPerSec = 0;  % how many Random Events per second to send (proba =  step /stimProbabilitySec)

% Proba of sending stim given that an event was detected
sCoreParams.decoders.txDetector.ProbabilityOfStim = 1;        % Given a detected event, what is the proba of actually sending a stimulation pulse
sCoreParams.decoders.txDetector.delayAfterStimSec = 1;        % Delay in Seconds to start detecting after Stimulation occur (to avoid stim artifact being detected)

%% Stimulation Parameters
% Stimulation Frequency to remove it - or just as info 
sCoreParams.stimulationFrequencyHz = 60; %160;       % Stimulation frequency in Hz used to specify the notch filter to remove it. = 60 for single pulse
sCoreParams.stimulator.amplitude_mA = 2000;        % Stimulation amplitude (1mA) - we should chanre name!!!
sCoreParams.stimulator.trainDuration = 60; %400;     % Stimulation Train Duration TrainDuration * Freq /1000 = number of pulses in train 60 for single pulse

sCoreParams.stimulator.refractoryPeriodSec = 2;     % Refractory period between allowed consecutive stimulations
sCoreParams.stimulator.delayAfterTriggerSec = 1;    % How long to wait in the case of NEXT TRIAL stim
sCoreParams.stimulator.stimChannelUpper = [1,2];    % Which channel to stim on when Feature is above UpperThreshold (ONLY used for MULTISITE stim)
sCoreParams.stimulator.stimChannelLower = [3,4];    % Which channel to stim on when Feature is below LowerThreshold (ONLY used for MULTISITE stim) - (Default same channels for Lower and Upper)
        
sCoreParams.stimulator.stimAfterDelaySec = 0;       % How long to wait after detection to send stimulation pulse

sCoreParams.stimulator.controlCerestimFromHost = false; %% By default DO NOT use CERESTIM CONFIGURATION (only for ECR) - ONLY TTL output!

sCoreParams.stimulator.maxNStimTrials = 5; % Stimulate on N (maxNStimTrials) out of M trials (default 5 out of 10 trials)
sCoreParams.stimulator.outOfMTrials = 10;    % if M=0 do not take this into account!

%% Processing
sCoreParams.FrameSize = 2; %256 ;            % RIZ: change according to filter - 2^n
sCoreParams.triggerThresholdValue = 1000; %500; % Since EEG values are in the order of uV/mV, ain gets this resolution -> we end up with huge values for the trigger (since it gets up to ~2.5V )
sCoreParams.decoders.txDetector.nFreqs =1;
sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nChannels; % Change to nPairs if using COHERENCE! see how to do in real time!!
sCoreParams.decoders.txDetector.nFeaturesUsedInDetection =  sCoreParams.decoders.txDetector.nFeatures;

% Baseline
sCoreParams.Features.Baseline.thresholdAboveValue = 1000;      % Stim if feature ABOVE this threshold
sCoreParams.Features.Baseline.thresholdBelowValue = -1000;     % Stim if feature BELOW this threshold

sCoreParams.Features.Baseline.weightPreviousThreshold = 0.1; %Indicate the weight of the previous threshold. newTh =(1-weight)* Th + weightPreviousThreshold * PrevTh
sCoreParams.Features.Baseline.initialThresholdValue = 0;      % Could be used to specify a fix or initial value of threshold (e.g.: to have same value during the whole experiment specify value here and set sCoreParams.Features.Baseline.weightPreviousThreshold=1)
sCoreParams.Features.Baseline.durationSec = 0.5; % duration of baseline segment in seconds (e.g. baseline is from 0.5-delayAfterTrigger sec before trigger until trigger +delayAfterTrigger)
sCoreParams.Features.Baseline.delayAfterTrigger = 0; %delay in samples after trigger to consider baseline (to have the option of considering baseline up to image presentation)
sCoreParams.Features.Baseline.SmoothWindowsDurationSamples = 1000;
sCoreParams.Features.Data.SmoothWindowsDurationSamples = 100;
sCoreParams.Features.Power.WindowDurationSec = 0.5; %Power is computed over WindowsDurationSec every FrameSize - SHOULD have overlap!

% Triggers
sCoreParams.Features.Baseline.beforeFirstTrigger = 0;       % Do NOT compute threshold before first trigger (it could be changed to 1 to contnously compute threshold before first trigger)
sCoreParams.triggers.numStimulations = 5;                   % After HOW many stimulations should we compute baseline again (if in stim based triggers)
sCoreParams.triggers.periodSec = 60;                        % FIXED baseline computation - every 2 minutes recompute baseline
sCoreParams.triggers.periodJitterInteger = 25;              % Jitter for FIXED baseline comp or afterStim Trigger - Jitter is this value * samplesPerStep 
sCoreParams.triggers.initialTriggerSec = 10;                % How long to wait for the first threshold computation

sCoreParams.triggers.minDistanceTriggersSec = 1;             % How close triggers could be to each other (to avoid detecting one trigger multiple times)

%% Task specific configuration
sCoreParams.Features.Coherence.WindowDurationSec = 0.5;  %Coherence is computed over WindowsDurationSec every FrameSize - SHOULD have overlap!
sCoreParams.Features.Coherence.lowFreq = 4;     %Frequency band to consider for coherence
sCoreParams.Features.Coherence.highFreq = 8;
% sCoreParams.Features.Coherence.nPoints = 8;
% sCoreParams.Features.Coherence.FsAfterDownSample = 100; %downsample to 50Hz for Theta Coherence!


%% Visualization
% Pre- and Post- trigger time in Seconds
sCoreParams.viz.streamDepthSec = 5;
sCoreParams.viz.MaxNumberChannels = 5; %Maximum number of channels to visualize simultaneously
sCoreParams.viz.channelInds = 1:min(sCoreParams.viz.MaxNumberChannels, sCoreParams.decoders.txDetector.nChannels);  %First channels - can be changed afterwards keeping the same number
sCoreParams.viz.featureInds = sCoreParams.viz.channelInds; %Change to pairs for coherence!
sCoreParams.viz.preTriggerSec = 0.25;
sCoreParams.viz.DurationTriggerAvSec = 1; % duration of visualization average - try to make tit smaller than refractory time, to avoid stim artifact from subsecuent stim
sCoreParams.viz.postTriggerSec = sCoreParams.viz.DurationTriggerAvSec - sCoreParams.viz.preTriggerSec; %10 seconds in total!
sCoreParams.viz.numTrialsPerPlot = 10;
sCoreParams.viz.pulseWidthStimSteps = 250;
sCoreParams.viz.pulseWidthTriggerSamples = 10;
sCoreParams.viz.averagedEEGDownSampling = 20; % 20 correspond to Fs=100Hz Downsampling is needed to reduce number of signals that we send.

%sCoreParams.viz.maxTriggeredEvents = 10;

%% File Target (filenames to use on target computer)
%Filename MUST have 8 characters - and CANNOT BE CHANGED! 
% Name here MUST be the same as they are here to read afterwadrds 
%t = fix(clock);
sCoreParams.target.filenames.featTh = 'FEAT_001.DAT'; % IT CANNOT BE CHANGED!['fea',num2str(t(4)),num2str(t(5)),'<%>.dat'];
sCoreParams.target.filenames.eeg = 'EEG_001.DAT'; % IT CANNOT BE CHANGED!['eeg',num2str(t(4)),num2str(t(5)),'<%>.dat'];
sCoreParams.target.filenames.stimInfo = 'STIM_001.DAT'; % IT CANNOT BE CHANGED!['det',num2str(t(4)),num2str(t(5)),'<%>.dat'];add HHMM to have something sort of unique.

%% UDP ports used for each type of data
sCoreParams.write.continuousData = 59123; % the internal UDP port is +1
sCoreParams.write.trialByTrialData = 59133;
sCoreParams.write.averagedData = 59143;

%% System network configs
sCoreParams.network.bufferPoolSizes = [8192 512 4096 65535];
sCoreParams.network.maxMtu = 1518;
sCoreParams.network.txThreshold = 224;
sCoreParams.network.txBuffers = 4096;
sCoreParams.network.rxBuffers = 8192;
sCoreParams.network.packetChainSize = 50;


%% Net-specific hardware
%     %We are USING CLOSES 2
%     sCoreParams.network.pciBus = [4 3 0];
%     sCoreParams.network.pciSlot = [0 3 25];
%     sCoreParams.network.numNSPs = 1;
    
% PROVIDENCE
% sCoreParams.network.pciBus = [2 3 3];
% sCoreParams.network.pciSlot = [0 14 15];
% sCoreParams.network.numNSPs = 1;

% MGH LARGE RIG
if strncmpi( getenv('COMPUTERNAME'),'DESKTOP-U2P22ER',length('DESKTOP-U2P22ER'))
    % We are using CLoSES 1 (changed RIZ 20201205)
    sCoreParams.network.pciBus = [4 5 5]; %5
    sCoreParams.network.pciSlot = [0 13 14]; %12
    sCoreParams.network.numNSPs = 1;

end

% BWH RIG - same as MGH large
if strncmpi( getenv('COMPUTERNAME'),'DESKTOP-OIQPATQ',length('DESKTOP-OIQPATQ'))
    sCoreParams.network.pciBus = [4 5 5];
    sCoreParams.network.pciSlot = [0 13 14];
    sCoreParams.network.numNSPs = 1;
end

%% Dependent 
sCoreParams = InitCoreParams_Dependent(sCoreParams);

%% Sanity Check
% %%%% 
% 
% if sCoreParams.write.maxContinuousSignalsPerStep*sCoreParams.write.broadcastSamp*8 > 65000
%     warndlg(['You''re trying to log too many signals! - use at most ',num2str(floor(65000/8/sCoreParams.write.broadcastSamp)),' features or channels * time'])
% end


%% RIZ: NOT in USE
%sCoreParams.core.stopSimulation = 0;         % RIZ: NOT IMPLEMENTED - if 1 simulation STOPS (useful to change with button in GUI)

% Filter
%sCoreParams.filter.Hd = FIRequirriple_70_100(sCoreParams.core.samplingRate);
%sCoreParams.write.maxSignalsPerStep = 12; %RIZ: HARDCODED value on maximum number of signals per step - moved to dependable because it actually depends on nChannels

%sCoreParams.features.computePower = 1;
%sCoreParams.Features.BeforeTriggerDuration = sCoreParams.FrameSize; %To remove the last frame before fixation - not implemented in code yet
%sCoreParams.Features.Baseline.durationSamples = 512; %Specify sample size directly to ensure 2^n value (for FFT)

%sCoreParams.viz.channelInds: Channels to send back for visualization and storage
%  applies to filtered data, fetures and threshold - if 0 send all detected channels / original [12 12 12 12 12];
%  OJO numbers correspond to already bipolar channels analysed (e.g. 2 is 2nd bipolar channel in  sCoreParams.decoders.txDetector.channel1-2
%sCoreParams.viz.channelInds = 0;  - MOVED to DEPENDENT to specify all indeces based on sCoreParams.decoders.txDetector.channel1/channel2
%sCoreParams.DisplayTriggeredMean = 1;
%sCoreParams.DurationTriggeredMeanSec = 0.05; % how long after stimulus to display averaged data

