function [ene_tf] = ene(varname)
% ene	returns true (1) if 'varname' is a variable which exists and
%	is not an empty matrix [].
%
% Usage:
% 	[ene_tf] = ene('varname')
%	
%		varname		the name of a variable to test, in quotes
%		ene_tf		returns 1 if varname exists and is not empty
%
% John D. Simeral 6-28-98
% Copyright (c) 1997 by Wake Forest University School of Medicine

%------------------------------------------------------------------------------
query  = ['exist(''' varname ''',''var'')'];

if ~evalin('caller',query)
    ene_tf = 0;			% variable does not exist
else
    if isempty(evalin('caller',varname))
        ene_tf = 0;		% variable exists but is empty []
    else
        ene_tf = 1;
    end;
end; 

% END
