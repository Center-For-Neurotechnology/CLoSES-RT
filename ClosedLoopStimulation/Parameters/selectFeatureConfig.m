function [variantConfig, sCoreParams] = selectFeatureConfig(featureName, variantConfig, sCoreParams, nEpochs)

if ~exist('nEpochs','var')
   nEpochs = 1;
end

switch upper(featureName)
    case 'BANDPOWER'
        variantConfig.WHICH_FEATURE = 1;
        variantConfig.WHICH_FEATURE_BASELINE = 4;
        variantConfig.WHICH_DETECTOR = 1;
        sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nFilteredChannels; % To have correct number for visualization! - RIZ: it should be improved!        case 'VARIANCEOFPOWER'
    case 'SMOOTHBANDPOWER'
        variantConfig.WHICH_FEATURE = 3;
        variantConfig.WHICH_FEATURE_BASELINE = 3;
        variantConfig.WHICH_DETECTOR = 1;  %change to 8 for neural model
        sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nFilteredChannels; % To have correct number for visualization! - RIZ: it should be improved!        case 'VARIANCEOFPOWER'
    case 'VARIANCEOFPOWER'
        variantConfig.WHICH_FEATURE = 4;
        variantConfig.WHICH_FEATURE_BASELINE = 4;
        variantConfig.WHICH_DETECTOR = 1;
        sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nFilteredChannels; % To have correct number for visualization! - RIZ: it should be improved!        case 'VARIANCEOFPOWER'
    case 'COHERENCE'
        variantConfig.WHICH_FEATURE = 5;
        variantConfig.WHICH_FEATURE_BASELINE = 5;
        variantConfig.WHICH_DETECTOR = 3;  %change to 8 for neural model
        sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nPairs;
    case 'CORRELATION'
        variantConfig.WHICH_FEATURE = 6;
        variantConfig.WHICH_FEATURE_BASELINE = 6;
        variantConfig.WHICH_DETECTOR = 3;
        sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nPairs;
    case 'IED'
        variantConfig.WHICH_FEATURE = 1; %CHANGE!!!! CHANGE for ANISH POWER CODE!!!
        variantConfig.WHICH_FEATURE_BASELINE = 2;
        variantConfig.WHICH_DETECTOR = 2;
        sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nFilteredChannels; % To have correct number for visualization! - RIZ: it should be improved!        case 'VARIANCEOFPOWER'
    case 'LOGBANDPOWER'
        variantConfig.WHICH_FEATURE = 7;
        variantConfig.WHICH_FEATURE_BASELINE = 7;
        variantConfig.WHICH_DETECTOR = 1; %4; - changed to neural model
        sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nFilteredChannels; % To have correct number for visualization! - RIZ: it should be improved!        case 'VARIANCEOFPOWER'
        
    otherwise
        disp(['No Valid Feature specified. Using default: Feat=', num2str(variantConfig.WHICH_FEATURE), ' - BaselineFeat=',num2str(variantConfig.WHICH_FEATURE_BASELINE), ' - Detector=',num2str(variantConfig.WHICH_DETECTOR) ]);
end 
% change based on number of frequency bands (state estimate with neural model)

%sCoreParams.decoders.txDetector.nFeatures = nFreqs * sCoreParams.decoders.txDetector.nFeatures;
        
sCoreParams.decoders.txDetector.detectChannelInds = 1:sCoreParams.decoders.txDetector.nFeatures;
sCoreParams.decoders.txDetector.detectChannelMask = ones(1,sCoreParams.decoders.txDetector.nFeatures);
sCoreParams.decoders.txDetector.nFeaturesUsedInDetection = sCoreParams.decoders.txDetector.nFeatures * nEpochs;
sCoreParams.viz.featureInds = 1:sCoreParams.decoders.txDetector.nFeaturesUsedInDetection;

