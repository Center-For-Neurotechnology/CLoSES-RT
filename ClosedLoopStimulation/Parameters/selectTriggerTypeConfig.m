function [variantConfig] = selectTriggerTypeConfig(triggerType, variantConfig)

if isempty(triggerType)
    return;
end

%Type of Trigger 
switch upper(regexprep(triggerType,'\W*',''))
    case 'EEGDATA'
        variantConfig.TRIGGER_TYPE = 1;                 % Get trigger from EEG (e.g. from Plexus - similar to Image Onset)
    case 'FIXEDPERIOD'                                  
        variantConfig.TRIGGER_TYPE = 2;                 % Fixed calculation of baseline - every: sCoreParams.triggers.periodSec
    case 'FOLLOWINGSTIM'
        variantConfig.TRIGGER_TYPE = 3;                 % Compute baseline after N stimulations (sCoreParams.triggers.numStimulations )
    case 'FOLLOWSTIMORFIXED'
        variantConfig.TRIGGER_TYPE = 4;                 % Compute baseline after N stimulations (sCoreParams.triggers.numStimulations )
    otherwise
        disp(['No Valid TRIGGER_TYPE specified. Using default: ', num2str(variantConfig.TRIGGER_TYPE)]);
end
