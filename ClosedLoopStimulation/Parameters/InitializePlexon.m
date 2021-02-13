function [sCoreParams, variantParams, variantConfig, variantConfigFlatNames] = InitializeNHPPlexon(sCoreParams, variantConfig)
% Creates fake data to run a quick simulation on the model


%% Config model's Paramteres if not provided
if ~exist('sCoreParams','var') || isempty(sCoreParams)
    sCoreParams=InitCoreParams;    %only run initCore if sCoreParams does not exist
end

%% Config Variants
if ~exist('variantConfig','var') || isempty(variantConfig)
    [variantParams, variantConfig] = InitVariants();
else
    [variantParams] = InitVariants(); % if variantConfig is provided we only need the variant names (variantParams)
end
[variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();

%% NHP specific parameter initialization
[sCoreParams] = InitCoreParamsNHP(sCoreParams); %Careful this implies that WE ALWAYS USE DEFAULTS!!!

%% VARIANTS
variantConfig.SAMPLINGRATE = sCoreParams.core.samplingRate;

% Stimulator
%variantParams.STIMULATION.TOAMS3800 = Simulink.Variant('variantConfig_STIMULATION_TYPE == 5');

%Config
%variantConfig.TRIGGERTYPE = 3;
%sCoreParams.core.maxChannelsTriggers = 1; %RIZ: Depends on the type of TRIGGER!!!! - Correct!!



%% assigin variables to workspace
FlattenAndTuneVariants(variantParams,'variantParams',variantParamsFlatNames);
FlattenAndTune(variantConfig,'variantConfig',variantConfigFlatNames);
FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);


%% Define all system target files - for xpc target!
%set_param(bdroot,'systemTargetFile','slrt.tlc')
