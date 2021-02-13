
function tunableParams = NameTunableParams
tunableParams = {
    'sCoreParams_decoders_txDetector_channel1'
    'sCoreParams_decoders_txDetector_channel2'
    'sCoreParams_decoders_txDetector_triggerChannel'   
    'sCoreParams_decoders_txDetector_stimTriggerChannel'

    'sCoreParams_decoders_txDetector_detectChannelInds'

    'sCoreParams_viz_channelInds'
    'sCoreParams_viz_featureInds'
    'sCoreParams_stimulator_startupTimeSec'
    'sCoreParams_stimulator_refractoryPeriodSec'
    'sCoreParams_stimulationFrequencyHz'
    'sCoreParams_decoders_txDetector_anyAll'
    'sCoreParams_stimulator_possibleStimRealChannelNumbers'
    'sCoreParams_decoders_chanceDetector_randStimEventsPerSec'
    'sCoreParams_decoders_txDetector_ProbabilityOfStim'
    'sCoreParams_decoders_txDetector_delayAfterStimSteps'
        
    'sCoreParams_decoders_txDetector_txRMS'
    'sCoreParams_decoders_txDetector_txRMSLower'
    'sCoreParams_decoders_txDetector_txSign'
    'sCoreParams_decoders_txDetector_nDetectionsRequested'
    'sCoreParams_Features_Baseline_initialThresholdValue'
    'sCoreParams_Features_Baseline_weightPreviousThreshold'
    'sCoreParams_Features_Data_SmoothWindowsDurationSamples'
    'sCoreParams_stimulator_stimAfterDelaySteps'
    
    %'sCoreParams_decoders_txDetector_nChannels'
    %'sCoreParams_decoders_txDetector_nFeatures' 
    %'sCoreParams_decoders_txDetector_realTimeUpdateThreshold'
    %'sCoreParams_core_stopSimulation'
    %'sCoreParams_decoders_txDetector_behavioralChannel'
    %'sCoreParams_Features_Baseline_thresholdAboveValue'
    %'sCoreParams_Features_Baseline_thresholdBelowValue'
    %'sCoreParams_neuralModelParams_initialXPre'
    
    };

end
%    'sCoreParams_decoders_txDetector_detectChannelMask' % UNSOLVED: Live-tuning Masks
