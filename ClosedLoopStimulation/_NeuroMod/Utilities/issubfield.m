function [isfound] = issubfield(topStructName,deepfieldName);
% issubfield	returns true (1) if 'deepfieldname' is a nested structure
%				within the known-to-exist structure 'structname'. Used
%				to test for the existence of a nested substructure in 
%				structname.
%
% Usage:
% 	[isfound] = issubfield('topStructName','deepfieldName')
%	
%		topStructName		string name of a structure variable in the caller's workspace; no '.' in name
%		deepfieldName		string specifying a field, possibly nested, to be found in structname;
%								must not start or end with '.'
%		isfound				returns true if deepfieldname is a valid (sub)structure in structname
%
% Example
%		Test whether a nested subfield exists in the loaded SLCdata structure as
%		follows. Unlike the (non-nested) Matlab function "isfield", here the
%		first argument must be a string (naming the top level structure).
%
%			isFound = issubfield('SLCdata','sSLC.ncTX.min_threshold');
%		
% John D. Simeral 10-08-2013
% Copyright (c) 2013 Simeral All Rights Reserved
%------------------------------------------------------------------------------
%warning off;
subfieldStarts = findstr('.',deepfieldName) + 1;
subfieldStarts = [1 subfieldStarts];
subfieldEnds = findstr('.',deepfieldName) - 1 ;
subfieldEnds = [subfieldEnds length(deepfieldName)];

testStructName = topStructName;
isfound = [];
n=0;
while isempty(isfound)
	n=n+1;
	subfieldTest_str = deepfieldName(subfieldStarts(n):subfieldEnds(n));
	evalstr = ['isfield(' testStructName ',''' subfieldTest_str ''');'];
	if ~evalin('caller',evalstr);
		isfound = false;
	elseif n == length(subfieldEnds)
		isfound = true;
	else
		testStructName = [testStructName '.' subfieldTest_str];
	end;
end;

% END issubfield
