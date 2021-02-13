function sA = MergeStructs(sA,sB)

% We need a function that overwrites fields in sA with the equivalent field
% in a equivalently structured but smaller structure sB. sB is thus the
% master.

% because sA and sB might have arbitrary depth, this function needs to be
% recursive, like all our other recursive struct tools. (can we please
% centralize these somehow?)

% USAGE:
% sA.fieldA.A = 1;
% sA.fieldA.B = 2;
%
% sB.fieldA.A = 2;
%
% OUTPUT: sMerged.fieldA.A = 2
%         sMerged.fieldA.B = 2;

allFields = fieldnames(sB);

for ii = 1:length(allFields)
    thisField = allFields{ii};
    if isstruct(sB.(thisField)) && isfield(sA,thisField) % going to have to dive in deeper, merging the substrcuts
        sA.(thisField) = MergeStructs(sA.(thisField),sB.(thisField)); % recursive call
    else % we want to set these to be equivalent
        sA.(thisField) = sB.(thisField);
    end
end