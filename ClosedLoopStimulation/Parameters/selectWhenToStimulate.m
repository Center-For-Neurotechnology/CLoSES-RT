function [variantConfig] = selectWhenToStimulate(stimulationType, variantConfig, detectorType)

if isempty(stimulationType)
    return;
end
    
if ~exist('detectorType','var')
    detectorType=[];
end

switch upper(regexprep(stimulationType,'\W*',''))
    case 'REALTIME'
        if strncmpi(detectorType, 'MULTI', length('MULTI')) % Stimulation on multiple site (Usually use MULTISITE)
            variantConfig.STIMULATION_TYPE = 3;
        else                                                % realtime 1 stimulation channel
            variantConfig.STIMULATION_TYPE = 1;
        end
    case 'NEXTTRIAL'
        if strncmpi(detectorType, 'MULTI', length('MULTI')) % Stimulation on multiple site (Usually use MULTISITE)
            variantConfig.STIMULATION_TYPE = 4;
        else
            variantConfig.STIMULATION_TYPE = 2;             % NextTrial 1 stimulation channel
        end
    case 'AMS3800'
        variantConfig.STIMULATION_TYPE = 5;                 % NOT implemented yet!
    otherwise
        disp(['No Valid STIMULATION_TYPE specified. Using default: ', num2str(variantConfig.STIMULATION_TYPE)]);
end
