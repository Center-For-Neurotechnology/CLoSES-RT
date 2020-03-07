function [variantParams, variantConfig] = InitVariants()

%Montage
variantParams.MONTAGE.REFERENTIAL = Simulink.Variant('variantConfig_IS_BIPOLAR == 0');
variantParams.MONTAGE.BIPOLAR = Simulink.Variant('variantConfig_IS_BIPOLAR == 1');

%Remove Stimulation artifact?
variantParams.PASS_SIGNAL = Simulink.Variant('variantConfig_REMOVE_STIM_FREQ == 0');
variantParams.REMOVE_STIM_FREQ = Simulink.Variant('variantConfig_REMOVE_STIM_FREQ == 1');
variantParams.REMOVE_ONLY_LINE = Simulink.Variant('variantConfig_REMOVE_STIM_FREQ == 2');

%Is Simulation or real world?
%variantParams.REAL_WORLD = Simulink.Variant('variantConfig_IS_SIMULATION == 0');
%variantParams.SIMULATION = Simulink.Variant('variantConfig_IS_SIMULATION == 1');

%Filter
%FIR_FILTER = Simulink.Variant('FILTER_TYPE == 1');
%IIR_FILTER = Simulink.Variant('FILTER_TYPE == 2');
variantParams.FILTER.FIR_HFORIPPLE= Simulink.Variant('variantConfig_FREQ_LOW == 80 && variantConfig_FILTER_TYPE == 1');
variantParams.FILTER.FIR_RIPPLE= Simulink.Variant('variantConfig_FREQ_LOW == 140 && variantConfig_FILTER_TYPE == 1');
variantParams.FILTER.FIR_HIGHGAMMARIPPLE= Simulink.Variant('variantConfig_FREQ_LOW == 65200 && variantConfig_FILTER_TYPE == 1');
variantParams.FILTER.FIR_HIGHGAMMA= Simulink.Variant('variantConfig_FREQ_LOW == 65 && variantConfig_FILTER_TYPE == 1');
variantParams.FILTER.FIR_LOWGAMMA= Simulink.Variant('variantConfig_FREQ_LOW == 30 && variantConfig_FILTER_TYPE == 1');
variantParams.FILTER.FIR_BETA= Simulink.Variant('variantConfig_FREQ_LOW == 15 && variantConfig_FILTER_TYPE == 1');
variantParams.FILTER.FIR_ALPHA= Simulink.Variant('variantConfig_FREQ_LOW == 8 && variantConfig_FILTER_TYPE == 1');
variantParams.FILTER.FIR_THETA= Simulink.Variant('variantConfig_FREQ_LOW == 4 && variantConfig_FILTER_TYPE == 1');

variantParams.FILTER.IIR_HFORIPPLE= Simulink.Variant('variantConfig_FREQ_LOW == 80 && variantConfig_FILTER_TYPE == 2');
variantParams.FILTER.IIR_RIPPLE= Simulink.Variant('variantConfig_FREQ_LOW == 140 && variantConfig_FILTER_TYPE == 2');
variantParams.FILTER.IIR_HIGHGAMMARIPPLE= Simulink.Variant('variantConfig_FREQ_LOW == 65200 && variantConfig_FILTER_TYPE == 2');
variantParams.FILTER.IIR_HIGHGAMMA= Simulink.Variant('variantConfig_FREQ_LOW == 65 && variantConfig_FILTER_TYPE == 2');
variantParams.FILTER.IIR_LOWGAMMA= Simulink.Variant('variantConfig_FREQ_LOW == 30 && variantConfig_FILTER_TYPE == 2');
variantParams.FILTER.IIR_BETA= Simulink.Variant('variantConfig_FREQ_LOW == 15 && variantConfig_FILTER_TYPE == 2');
variantParams.FILTER.IIR_ALPHA= Simulink.Variant('variantConfig_FREQ_LOW == 8 && variantConfig_FILTER_TYPE == 2');
variantParams.FILTER.IIR_THETA= Simulink.Variant('variantConfig_FREQ_LOW == 4 && variantConfig_FILTER_TYPE == 2');
variantParams.FILTER.IIR.GAMMA= Simulink.Variant('variantConfig_FREQ_LOW == 30110 && variantConfig_FILTER_TYPE == 2');
variantParams.FILTER.IIR.SPINDLES= Simulink.Variant('variantConfig_FREQ_LOW == 1216 && variantConfig_FILTER_TYPE == 2');

variantParams.FILTER.FIR_EXTERNAL = Simulink.Variant('variantConfig_FREQ_LOW == -1 && variantConfig_FILTER_TYPE == 1');
variantParams.FILTER.ALLPASS = Simulink.Variant('variantConfig_FREQ_LOW == 0'); % Do NOT filter -> simply pass raw EEG data

variantParams.FILTER.MANYFREQS.THETAALPHAGAMMA  = Simulink.Variant('variantConfig_FREQ_LOW == 4865200 && variantConfig_FILTER_TYPE == 2'); % for state estimate model we need 3 freqs

%Sampling Rate (needed beacuse filters MUST have FIXED sampling rates)
variantParams.SAMPLING.FS1000 = Simulink.Variant('variantConfig_SAMPLINGRATE == 1000');
variantParams.SAMPLING.FS2000 = Simulink.Variant('variantConfig_SAMPLINGRATE == 2000');

%Features 
variantParams.FEATURE.BANDPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE == 1');
variantParams.FEATURE.VARIANCE = Simulink.Variant('variantConfig_WHICH_FEATURE == 2');
variantParams.FEATURE.SMOOTHBANDPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE == 3');
variantParams.FEATURE.VARIANCEOFPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE == 4');
variantParams.FEATURE.COHERENCE = Simulink.Variant('variantConfig_WHICH_FEATURE == 5');
variantParams.FEATURE.CORRELATION = Simulink.Variant('variantConfig_WHICH_FEATURE == 6');
variantParams.FEATURE.LOGBANDPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE == 7');

%Features Baseline
variantParams.FEATURE.BASELINE.WEIGHTEDTIMEPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE_BASELINE == 1'); %Almost the same as WEIGHTEDPOWER
variantParams.FEATURE.BASELINE.BATCHVARIANCE = Simulink.Variant('variantConfig_WHICH_FEATURE_BASELINE == 2');
variantParams.FEATURE.BASELINE.WEIGHTEDPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE_BASELINE == 3');
variantParams.FEATURE.BASELINE.VARIANCEOFPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE_BASELINE == 4');
variantParams.FEATURE.BASELINE.COHERENCE = Simulink.Variant('variantConfig_WHICH_FEATURE_BASELINE == 5');
variantParams.FEATURE.BASELINE.CORRELATION = Simulink.Variant('variantConfig_WHICH_FEATURE_BASELINE == 6');

variantParams.FEATURE.BASELINE.BANDPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE_BASELINE == 7'); %Not really used
variantParams.FEATURE.BASELINE.VARIANCE = Simulink.Variant('variantConfig_WHICH_FEATURE_BASELINE == 8');    %Not really used
variantParams.FEATURE.BASELINE.SMOOTHBANDPOWER = Simulink.Variant('variantConfig_WHICH_FEATURE_BASELINE == 9'); %Not really used

% Detectors
variantParams.DETECTOR.SIMPLEFEATURE = Simulink.Variant('variantConfig_WHICH_DETECTOR == 1');
variantParams.DETECTOR.IED = Simulink.Variant('variantConfig_WHICH_DETECTOR == 2');
variantParams.DETECTOR.COHERENCEFEATURE = Simulink.Variant('variantConfig_WHICH_DETECTOR == 3');
variantParams.DETECTOR.SIMPLEFEATURETRIGGER = Simulink.Variant('variantConfig_WHICH_DETECTOR == 4');
variantParams.DETECTOR.COHERENCEFEATURETRIGGER = Simulink.Variant('variantConfig_WHICH_DETECTOR == 5');
variantParams.DETECTOR.MULTISITESIMPLEFEATURE = Simulink.Variant('variantConfig_WHICH_DETECTOR == 6');
variantParams.DETECTOR.MULTISITECOHERENCETRIGGER = Simulink.Variant('variantConfig_WHICH_DETECTOR == 7');
%variantParams.DETECTOR.STATEESTIMATE = Simulink.Variant('variantConfig_WHICH_DETECTOR == 1');
%variantParams.DETECTOR.MULTISITE = Simulink.Variant('variantConfig_WHICH_DETECTOR == 2');

%Stimulation
variantParams.STIMULATION.REALTIME = Simulink.Variant('variantConfig_STIMULATION_TYPE == 1');
variantParams.STIMULATION.ONNEXTTRIGGER = Simulink.Variant('variantConfig_STIMULATION_TYPE == 2');
variantParams.STIMULATION.MULTISITE.REALTIME = Simulink.Variant('variantConfig_STIMULATION_TYPE == 3');
variantParams.STIMULATION.MULTISITE.NEXTTRIGGER = Simulink.Variant('variantConfig_STIMULATION_TYPE == 4');

%Type of Trigger - Should this be moved to a separate file?
variantParams.TRIGGER.EEGDATA = Simulink.Variant('variantConfig_TRIGGER_TYPE == 1');         % Get trigger from EEG (from Plexus - similar to Image Onset)
variantParams.TRIGGER.FIXEDPERIOD = Simulink.Variant('variantConfig_TRIGGER_TYPE == 2');     % Fixed calculation of baseline - every: sCoreParams.triggers.periodSec
variantParams.TRIGGER.FOLLOWINGSTIM = Simulink.Variant('variantConfig_TRIGGER_TYPE == 3');   % Compute baseline after N stimulations (sCoreParams.triggers.numStimulations )
variantParams.TRIGGER.FOLLOWSTIMORFIXED = Simulink.Variant('variantConfig_TRIGGER_TYPE == 4');   % Compute baseline after N stimulations (sCoreParams.triggers.numStimulations ) or if no stim occurs after sCoreParams.triggers.periodSec seconds

% State variable to use for detection (which state estimate output is compared to threshold)
variantParams.STATEOUTPUT.MEAN = Simulink.Variant('variantConfig_STATEOUTPUT == 1');        % Mean state estiamte is used in ECR
variantParams.STATEOUTPUT.UPPERBOUND = Simulink.Variant('variantConfig_STATEOUTPUT == 2');  % Upper bound estimate is used in MSIT
variantParams.STATEOUTPUT.LOWERBOUND = Simulink.Variant('variantConfig_STATEOUTPUT == 3');

% State Estimate Model  - For now only 1
variantParams.STATEMODEL.NEURALMODEL = Simulink.Variant('variantConfig_STATEMODEL == 1');   

%Config
IS_BIPOLAR = 1;
REMOVE_STIM_FREQ = 0;
%IS_SIMULATION = 1;
FILTER_TYPE = 2;
FREQ_LOW = 65;
WHICH_FEATURE = 3;
WHICH_FEATURE_BASELINE = 3;
WHICH_DETECTOR =1;
STIMULATION_TYPE = 1;
TRIGGER_TYPE = 1;
SAMPLINGRATE = 2000;
STATEOUTPUT = 1; % default is mean state estimate
STATEMODEL = 1;

%Output configuration as struct
variantConfig.IS_BIPOLAR = IS_BIPOLAR;
variantConfig.REMOVE_STIM_FREQ = REMOVE_STIM_FREQ;
%variantConfig.IS_SIMULATION = IS_SIMULATION;
variantConfig.FILTER_TYPE = FILTER_TYPE;
variantConfig.FREQ_LOW = FREQ_LOW;
variantConfig.SAMPLINGRATE = SAMPLINGRATE;
variantConfig.WHICH_FEATURE = WHICH_FEATURE;
variantConfig.WHICH_FEATURE_BASELINE = WHICH_FEATURE_BASELINE;
variantConfig.WHICH_DETECTOR = WHICH_DETECTOR;
variantConfig.STIMULATION_TYPE = STIMULATION_TYPE;
variantConfig.TRIGGER_TYPE = TRIGGER_TYPE;
variantConfig.STATEOUTPUT = STATEOUTPUT;
variantConfig.STATEMODEL = STATEMODEL;
