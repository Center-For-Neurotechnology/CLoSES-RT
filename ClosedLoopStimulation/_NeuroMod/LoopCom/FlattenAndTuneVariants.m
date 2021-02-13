function FlattenAndTuneVariants(S,SName,tunableVariants)

if ~exist('SName','var')
    SName = inputname(1);
end
if ~exist('tunableVariants','var')
    tunableVariants = {};
end
if isstruct(S)
    subfields = fieldnames(S);
    for subfieldInd = 1:length(subfields)
        thisField = subfields{subfieldInd};
        Snew = S.(thisField);
        SnewName = [SName '_' thisField];
        FlattenAndTuneVariants(Snew,SnewName,tunableVariants)
    end
    
else
    if any(ismember(SName,tunableVariants))
        simVariant = Simulink.Variant;
        simVariant.Condition = S.Condition;
        %simVariant.CoderInfo.StorageClass = 'ExportedGlobal';
        assignin('base',SName,simVariant);
    end
end