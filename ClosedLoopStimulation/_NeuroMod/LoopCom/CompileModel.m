function CompileModel(modelName,paramStruct,paramStructName)
if ~exist('initFcn','var')
   initFcn = 'InitCoreParams';
end
if ~exist('paramStructName','var')
    paramStructName = 'sCoreParams';
    tunableParams = NameTunableParams;
end

if ~exist('paramStruct','var')
    paramStruct = eval(initFcn);
end

FlattenAndTune(paramStruct,paramStructName,tunableParams);

prevDir = pwd;
if isdir('CompileFiles')
    cd('CompileFiles')
else
    mkdir('CompileFiles')
    cd('CompileFiles')
end


try
rtwbuild(modelName)
cd(prevDir);

catch e
cd(prevDir);
error(e.message)
end