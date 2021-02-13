function [variantConfig, controlCerestimFromHost] = selectDetectorConfig(detectorType, variantConfig, featureName)

% A specific detector could be specified (to detect only during trial or all the time)- 
% but be careful, there are different detectors for POWER and COHERENCE features
%       Options: CONTINUOUS /TRIGGER / MULTISITE / IED

if isempty(detectorType)
    return;
end
controlCerestimFromHost = false; %Since the control must be modified on host comptuter -> send this info back to GUI

switch upper(detectorType)
    case 'CONTINUOUS'
    switch upper(featureName)
        case {'BANDPOWER', 'SMOOTHBANDPOWER', 'VARIANCEOFPOWER'}
            variantConfig.WHICH_DETECTOR = 1; %SimpleFeature Detector
        case {'COHERENCE','CORRELATION'}
            variantConfig.WHICH_DETECTOR = 3; %Coherence Detector
        otherwise
            variantConfig.WHICH_DETECTOR = 1; %SimpleFeature Detector
            disp(['No Valid Feature Name specified. Using SimpleFeature CONTINUOUS Detector=', num2str(variantConfig.WHICH_DETECTOR) ]);
    end
    case 'TRIGGER'
    switch upper(featureName)
        case {'BANDPOWER', 'SMOOTHBANDPOWER', 'VARIANCEOFPOWER'}
            variantConfig.WHICH_DETECTOR = 4; %SimpleFeatureTrigger Detector
        case {'COHERENCE','CORRELATION'}
            variantConfig.WHICH_DETECTOR = 5; %CoherenceTrigger Detector
        otherwise
            variantConfig.WHICH_DETECTOR = 4; %SimpleFeatureTrigger Detector
            disp(['No Valid Feature Name specified. Using SimpleFeature TRIGGER Detector=', num2str(variantConfig.WHICH_DETECTOR) ]);
    end
    case 'MULTISITE'
    switch upper(featureName)
        case {'BANDPOWER', 'SMOOTHBANDPOWER', 'VARIANCEOFPOWER'}
            variantConfig.WHICH_DETECTOR = 6; % MultiSite SimpleFeatureTrigger Detector
        case {'COHERENCE','CORRELATION'}
            variantConfig.WHICH_DETECTOR = 7; %MultiSite CoherenceTrigger Detector
            controlCerestimFromHost = true;
        otherwise
            variantConfig.WHICH_DETECTOR = 7; %%MultiSite CoherenceTrigger Detector
            disp(['No Valid Feature Name specified. Using MultiSite CoherenceTrigger Detector=', num2str(variantConfig.WHICH_DETECTOR) ]);
    end
    case 'IED'
        variantConfig.WHICH_DETECTOR = 2; %IED Detector - No check for IED detector...
        if strcmpi( featureName, 'IED') <=0 % check that feature is IED
            disp('WARNING::: IED detector should be associated to IEDs')
        end
    case 'NEURALMODEL'
        variantConfig.WHICH_DETECTOR = 8; %NEURALMODEL Detector - state estimate 
    otherwise
        disp(['No Valid Feature specified. Using default: Feat=', num2str(variantConfig.WHICH_FEATURE), ' - BaselineFeat=',num2str(variantConfig.WHICH_FEATURE_BASELINE), ' - Detector=',num2str(variantConfig.WHICH_DETECTOR) ]);
end 


