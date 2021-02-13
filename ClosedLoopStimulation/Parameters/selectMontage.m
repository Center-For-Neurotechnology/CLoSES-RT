function [variantConfig] = selectMontage(selMontage, variantConfig)

if isempty(selMontage)
    return;
end

switch upper(regexprep(selMontage,'\W*',''))
    case 'REFERENTIAL'
        variantConfig.IS_BIPOLAR = 0;
    case 'BIPOLAR'
        variantConfig.IS_BIPOLAR = 1;
    otherwise
        disp(['No Valid IS_BIPOLAR specified. Using default: ', num2str(variantConfig.IS_BIPOLAR)]);
end
