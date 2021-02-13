function FlattenAndTune(S,SName,tunableParams)

if ~exist('SName','var')
    SName = inputname(1);
end
if ~exist('tunableParams','var')
    tunableParams = {};
end
if isstruct(S)
    subfields = fieldnames(S);
    for subfieldInd = 1:length(subfields)
        thisField = subfields{subfieldInd};
        Snew = S.(thisField);
        SnewName = [SName '_' thisField];
        FlattenAndTune(Snew,SnewName,tunableParams)
    end
    
else
    if any(ismember(SName,tunableParams))
        simParam = Simulink.Parameter;
        simParam.Value = S;
        simParam.CoderInfo.StorageClass = 'ExportedGlobal';
        assignin('base',SName,simParam);
    end
end