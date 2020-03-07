function CompileModelComplete(modelName, dirCompileFiles)

%inputs
if ~exist('dirCompileFiles','var')
    dirCompileFiles = pwd;
end

%parameters
sCoreParams=InitCoreParams;
FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);

%Buses
load('buses.mat');

%Variants
[variantParams, variantConfig] = InitVariants();
[variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
FlattenAndTuneVariants(variantParams,'variantParams',variantParamsFlatNames);
FlattenAndTune(variantConfig,'variantConfig',variantConfigFlatNames);

%Directory
prevDir = pwd;
if isdir(dirCompileFiles)
    cd(dirCompileFiles)
else
    mkdir(dirCompileFiles)
    cd(dirCompileFiles)
end

%Compile
try
    rtwbuild(modelName)
    cd(prevDir);
    
catch e
    cd(prevDir);
    error(e.message)
end