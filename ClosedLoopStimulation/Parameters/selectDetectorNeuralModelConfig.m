function [variantConfig, controlCerestimFromHost] = selectDetectorNeuralModelConfig(detectorType, variantConfig, featureName)

% A specific detector could be specified (to detect only during trial or all the time)- 
% but be careful, there are different detectors for POWER and COHERENCE features
%       Options: CONTINUOUS /TRIGGER / MULTISITE / IED

if isempty(detectorType)
    return;
end
controlCerestimFromHost = false; %Since the control must be modified on host comptuter -> send this info back to GUI

switch upper(detectorType)
    case 'NEURALMODEL'
        variantConfig.WHICH_DETECTOR = 1; %NEURALMODEL Detector - state estimate 1 stim channel (MSIT)
    case 'MULTISITE'
        variantConfig.WHICH_DETECTOR = 2; %MULTISITE Detector - state estimate with 2 possible STIM channels (ECR)
        controlCerestimFromHost = true;

    otherwise
        disp(['No Valid Feature specified. Using default: Feat=', num2str(variantConfig.WHICH_FEATURE), ' - BaselineFeat=',num2str(variantConfig.WHICH_FEATURE_BASELINE), ' - Detector=',num2str(variantConfig.WHICH_DETECTOR) ]);
end 


