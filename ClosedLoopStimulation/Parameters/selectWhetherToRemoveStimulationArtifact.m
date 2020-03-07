function [variantConfig] = selectWhetherToRemoveStimulationArtifact(removeStim, variantConfig)

if isempty(removeStim)
    return;
end

switch upper(regexprep(removeStim,'\W*',''))
    case 'PASSSIGNAL'
        variantConfig.REMOVE_STIM_FREQ = 0;
    case 'REMOVESTIMFREQ'
        variantConfig.REMOVE_STIM_FREQ = 1;
    case 'REMOVEONLYLINE'
        variantConfig.REMOVE_STIM_FREQ = 2;
    otherwise
        disp(['No Valid REMOVE_STIM_FREQ specified. Using default: ', num2str(variantConfig.REMOVE_STIM_FREQ)]);
end
