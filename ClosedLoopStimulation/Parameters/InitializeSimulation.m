function [sCoreParams, variantParams, variantConfig, variantConfigFlatNames, sInputData, sInputTrigger, sMultiTimeInputData, sMultiTimeInputTrigger] = InitializeSimulation(whatTypeSimulation, sCoreParams, variantConfig, realDataFileName)
% Creates fake data to run a quick simulation on the model


%% Config model's Paramteres if not provided
if ~exist('sCoreParams','var') || isempty(sCoreParams)
    sCoreParams=InitCoreParams;
end
%buses = load('buses.mat');
%assignin('base','features',buses.features);
%assignin('base','thFeatures',buses.thFeatures);
if ~exist('realDataFileName','var') || isempty(realDataFileName)
    realDataFileName = 'C:\DARPA\DATA\Simulations\SimData_CoherencePairs_MG88.mat'; %'C:\DARPA\DATA\Simulations\SimData_ACC_PFDC_MG99.mat';
end

%% Config Variants
if ~exist('variantConfig','var') || isempty(variantConfig)
    [variantParams, variantConfig] = InitVariants();
else
    [variantParams] = InitVariants(); % if variantConfig is provided we only need the variant names (variantParams)
end
[variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();

%% DATA
%inputData= [1:200;rand(1,200)];
%nspTime = 1;
sInputData=[]; sInputTrigger=[]; sMultiTimeInputData=[]; sMultiTimeInputTrigger=[];
switch upper(whatTypeSimulation)
    case 'SINE'
        disp('Creating data for Simulation')
        %Change config for simulation!
        sCoreParams.core.NumberNSPs = 1;
        sCoreParams.core.maxChannelsAllNSPs = 7; % 5 EEG (4 channels) + baseline trigger + stim trigger
        sCoreParams.core.maxChannelsTriggers = sCoreParams.core.maxChannelsAllNSPs; % Same in both
        if (sCoreParams.decoders.txDetector.nChannels > sCoreParams.core.maxChannelsAllNSPs)
            sCoreParams.decoders.txDetector.channel1 = [1: (sCoreParams.core.maxChannelsAllNSPs-3)]; %[1:sCoreParams.core.maxChannelsAllNSPs-1]; %[1 2];
            sCoreParams.decoders.txDetector.channel2 = [2: sCoreParams.core.maxChannelsAllNSPs-2]; %[2 3];
            sCoreParams.decoders.txDetector.nChannels = min(length(sCoreParams.decoders.txDetector.channel1),length(sCoreParams.decoders.txDetector.channel2));
            sCoreParams.decoders.txDetector.detectChannelInds = 1:sCoreParams.decoders.txDetector.nChannels;
            sCoreParams.viz.channelInds = 1:min(sCoreParams.viz.MaxNumberChannels, sCoreParams.decoders.txDetector.nChannels);  %First channels - can be changed afterwards keeping the same number
            sCoreParams.viz.featureInds = sCoreParams.viz.channelInds;                              % Change to nPairs if using COHERENCE! see how to do in real time!!
            sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nChannels;  % Change to nPairs if using COHERENCE! see how to do in real time!!
        end
        sCoreParams.decoders.txDetector.channelNames = cellfun(@num2str,num2cell(1:sCoreParams.core.maxChannelsAllNSPs),'UniformOutput',false);
        sCoreParams.decoders.txDetector.triggerChannel = 7; %sCoreParams.core.maxChannelsAllNSPs;
        sCoreParams.decoders.txDetector.stimTriggerChannel = 7; %sCoreParams.decoders.txDetector.triggerChannel; %For Simulation - use same trigger for image onset and stim trigger
        sCoreParams.stimulator.startupTimeSec = 1;
        sCoreParams.triggerThresholdValue = 0.1;    %For simulation trigger value is 1 - for real -closed loop with input from decider is ~2000
        sCoreParams = InitCoreParams_Dependent(sCoreParams);
    
        nSec = 1000;
        nSamples = nSec * sCoreParams.core.samplingRate;
        % Trigger Data
        trigPeriodSec = 5;
        trigPeriodSamples = trigPeriodSec *sCoreParams.core.samplingRate;
        stimTrigShiftSamples = 0.5 * sCoreParams.core.samplingRate;
        indTriggers = trigPeriodSamples*(1:nSamples/trigPeriodSamples);

        % Events are sine + random noise
        eventDurationSec = 1.5;
        eventDurationSamples = eventDurationSec * sCoreParams.core.samplingRate;   % event occurs for 50ms
        eventAmplitude = 3;
        eventFreq = 5;       %orginally 80Hz                                      % event frequency in Hz
        eventSignal = eventAmplitude * sin(2*pi* eventFreq *(0:1/sCoreParams.core.samplingRate:eventDurationSec));
        eventChannels = [1 3];                                        % channels were event occur (in referential)
      %  eventPeriodSamples = 10 *sCoreParams.core.samplingRate;       % event occurs every 10 seconds (every other trigger) - change to with respect  to trigger
        eventDelaySamples = 0.8 * sCoreParams.core.samplingRate;        % event occurs 0.8 sec after trigger
        sInputData.time=[];
        sInputData.signals.values = rand(nSamples,sCoreParams.core.maxChannelsAllNSPs-2);
        %eventFirstSamples = eventPeriodSamples*(1:nSamples/eventPeriodSamples)+eventDelaySamples;
        eventFirstSamples = indTriggers(1:2:end)+eventDelaySamples; % Create events with respect to triggers (e.g. 0.8 sec after odd triggers)
        for iCh = 1:length(eventChannels)
            for iEv = 1:length(eventFirstSamples)
                sInputData.signals.values(eventFirstSamples(iEv):eventFirstSamples(iEv)+eventDurationSamples,eventChannels(iCh)) = eventSignal;
            end
        end
        sInputData.signals.dimensions=sCoreParams.core.maxChannelsAllNSPs-2;
        
        % Create Trigger Structure
        sInputTrigger.time=[];
       % sInputTrigger.signals.values=zeros(nSamples,2); % it has two channels to represent distinct baseline trigger and stim triggers
        sInputTrigger.signals.values = zeros(size(sInputData.signals.values,1),2);
        sInputTrigger.signals.values(indTriggers(1:5:end)-stimTrigShiftSamples,1) =1;   %Baseline TRigger occurs every 4 of the Detection/STIM trigger - 0.5sec
        sInputTrigger.signals.values(indTriggers(1:5:end)-stimTrigShiftSamples +1,1) =1; %To have 2 samples per pulse!
        sInputTrigger.signals.values(indTriggers,2) = 1;                                %Detection/STIM trigger
        sInputTrigger.signals.dimensions=2;
         
    case 'PREPROCESSED' % This data is from already bipolarized and pre-analysed data 
        stRealDataSim = load(realDataFileName);
        sCoreParams.core.NumberNSPs = 1; % Assume all is from 1 NSP!
        sCoreParams.core.maxChannelsAllNSPs = stRealDataSim.nChannels +2; %one extra for trigger
        sCoreParams.core.maxChannelsTriggers = sCoreParams.core.maxChannelsAllNSPs; % Same in both
        sCoreParams.decoders.txDetector.channel1 = 1:stRealDataSim.nChannels; %[1:sCoreParams.core.maxChannelsAllNSPs-1]; %[1 2];
        sCoreParams.decoders.txDetector.channel2 = 1:stRealDataSim.nChannels; %[2 3];
        sCoreParams.decoders.txDetector.nChannels = stRealDataSim.nChannels;
        sCoreParams.decoders.txDetector.detectChannelInds = 1:sCoreParams.decoders.txDetector.nChannels;
        sCoreParams.viz.channelInds = 1:min(sCoreParams.viz.MaxNumberChannels, sCoreParams.decoders.txDetector.nChannels);  %First channels - can be changed afterwards keeping the same number
        sCoreParams.viz.featureInds = sCoreParams.viz.channelInds;                              % Change to nPairs if using COHERENCE! see how to do in real time!!
        sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nChannels;  % Change to nPairs if using COHERENCE! see how to do in real time!!
        
        sCoreParams.decoders.txDetector.triggerChannel = sCoreParams.core.maxChannelsAllNSPs-1;
        sCoreParams.decoders.txDetector.stimTriggerChannel = sCoreParams.decoders.txDetector.triggerChannel; %For Simulation - use same trigger for image onset and stim trigger
        sCoreParams.stimulator.startupTimeSec = 1;

        % Assign Channel Names - probably needs to change to cell nChannsx1
        sCoreParams.decoders.txDetector.channelNames = stRealDataSim.selChannelNames;
        
        
        %Data
        sInputData.time=[];
        sInputData.signals.values = stRealDataSim.EEGVals';
        sInputData.signals.dimensions=sCoreParams.core.maxChannelsAllNSPs-2;
        % Trigger
        trigPeriodSec = stRealDataSim.lTrialSec;
        triggerDelayInTrial = find(stRealDataSim.timesInTrial>=0,1);
        trigPeriodSamples = trigPeriodSec * sCoreParams.core.samplingRate;
        sInputTrigger.time=[];
        sInputTrigger.signals.values=zeros(length(stRealDataSim.timeVals),2);
        indTriggers = trigPeriodSamples*(0:length(stRealDataSim.timeVals)/trigPeriodSamples) + triggerDelayInTrial;
        sInputTrigger.signals.values(indTriggers,1) =1;
        sInputTrigger.signals.values(indTriggers +1,1) =1; %To have 2 samples per pulse!
        sInputTrigger.signals.dimensions=2;

        sCoreParams.triggerThresholdValue = quantile(sInputTrigger.signals.values,0.99)/10;    %For simulation trigger value 10 times smaller than max - for real -closed loop with input from decider is ~2000
        %Update Dependent
        sCoreParams = InitCoreParams_Dependent(sCoreParams);

        %VARIANTS
        % it is already in Bipolar MONTAGE -> use REFERENTIAL
        variantConfig.IS_BIPOLAR = 0;
 
    case {'REAL','NEV'} % These are MAT files created from NEV or Plexon data - in referential montge, so we assume we can use consecutive channels for bipolar
        stRealDataSim = load(realDataFileName);
        sCoreParams.core.NumberNSPs = 1; % Assume all is from 1 NSP!
        sCoreParams.core.maxChannelsAllNSPs = stRealDataSim.nChannels +2; %two extra for trigger - to have consistency with other simulations (both triggers are the same here)
        sCoreParams.core.maxChannelsTriggers = sCoreParams.core.maxChannelsAllNSPs; % Same in both
        if isfield(stRealDataSim, 'channel1') && ~isempty(stRealDataSim.channel1)
            sCoreParams.decoders.txDetector.channel1 = stRealDataSim.channel1;
        else
            sCoreParams.decoders.txDetector.channel1 =1:stRealDataSim.nChannels-1; %[1 3 5 7];% [1:sCoreParams.core.maxChannelsAllNSPs-1]; %[1 2];
        end
        if isfield(stRealDataSim, 'channel2') && ~isempty(stRealDataSim.channel2)
            sCoreParams.decoders.txDetector.channel2 = stRealDataSim.channel2;
        else
            sCoreParams.decoders.txDetector.channel2 = 2:stRealDataSim.nChannels; %[2 4 6 8]; %[2 3];
        end
        sCoreParams.decoders.txDetector.nChannels = min(length(sCoreParams.decoders.txDetector.channel1),length(sCoreParams.decoders.txDetector.channel2));
        sCoreParams.decoders.txDetector.detectChannelInds = 1:sCoreParams.decoders.txDetector.nChannels;
        sCoreParams.viz.channelInds = 1:min(sCoreParams.viz.MaxNumberChannels, sCoreParams.decoders.txDetector.nChannels);  %First channels - can be changed afterwards keeping the same number
        sCoreParams.viz.featureInds = sCoreParams.viz.channelInds;                              % Change to nPairs if using COHERENCE! see how to do in real time!!
        sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nChannels;  % Change to nPairs if using COHERENCE! see how to do in real time!!
        
        sCoreParams.decoders.txDetector.triggerChannel = sCoreParams.core.maxChannelsAllNSPs-1;    %Last channel is trigger
        sCoreParams.decoders.txDetector.stimTriggerChannel = sCoreParams.decoders.txDetector.triggerChannel; %For Simulation - use same trigger for image onset and stim trigger
        sCoreParams.stimulator.startupTimeSec = 1;
        
       
        %Data
        sInputData.time=[];
        sInputData.signals.values = stRealDataSim.EEGVals';
        sInputData.signals.dimensions=sCoreParams.core.maxChannelsAllNSPs-2;
        % Trigger
        sInputTrigger.time=[];
        sInputTrigger.signals.values = zeros(size(sInputData.signals.values,1),2);
        sInputTrigger.signals.values(:,1) = stRealDataSim.triggerVals(1,:)';
        sInputTrigger.signals.dimensions=2;
        if isfield(stRealDataSim,'channelNames')
            sCoreParams.decoders.txDetector.channelNames = stRealDataSim.channelNames;
            disp('Channel Names: ')
            disp([num2cell(1:length(stRealDataSim.channelNames));stRealDataSim.channelNames])
        else
            sCoreParams.decoders.txDetector.channelNames =  cellfun(@num2str,num2cell(1:sCoreParams.core.maxChannelsAllNSPs),'UniformOutput',false);
        end
        
        % Compute Trigger Threshold
        sCoreParams.triggerThresholdValue = quantile(sInputTrigger.signals.values,0.99)/10;    %For simulation trigger value 10 times smaller than max - for real -closed loop with input from decider is ~2000
        % Assign Channel Names
        
        %Update Dependent
        sCoreParams = InitCoreParams_Dependent(sCoreParams);

    otherwise
        disp('Simulation type must be SINE, PREPROCESSED, REAL, or NEV!')
end

% Convert Data to sCoreParams.core.samplesPerStep at each step
samplesPerStep=sCoreParams.core.samplesPerStep;
nSamples = size(sInputData.signals.values,1);
nChanns = size(sInputData.signals.values,2);
nTimeSteps = floor(nSamples/samplesPerStep);
sMultiTimeInputData.signals.values = zeros(samplesPerStep,nChanns,nTimeSteps);
sMultiTimeInputTrigger.signals.values = zeros(samplesPerStep,2,nTimeSteps);
for t=1:nTimeSteps    
    indPerStep = (t-1)*samplesPerStep+1 : t*samplesPerStep;
    sMultiTimeInputData.signals.values(:,:,t) = sInputData.signals.values(indPerStep,:);
    sMultiTimeInputTrigger.signals.values(:,:,t) = sInputTrigger.signals.values(indPerStep,:);
end
sMultiTimeInputData.time =[];
sMultiTimeInputData.signals.dimensions = [samplesPerStep,nChanns];
sMultiTimeInputTrigger.time =[];
sMultiTimeInputTrigger.signals.dimensions = [samplesPerStep,2];


%% assigin variables to workspace
FlattenAndTuneVariants(variantParams,'variantParams',variantParamsFlatNames);
FlattenAndTune(variantConfig,'variantConfig',variantConfigFlatNames);
FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);


%% Define all system target files - for xpc target!
%set_param(bdroot,'systemTargetFile','slrt.tlc')
