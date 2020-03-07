function compileModelToUpdateVariants(modelFileName, curentDir, sCoreParams, variantConfig)

startTime=tic;
FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);
assignin('base','sCoreParams',sCoreParams);

[variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
FlattenAndTune(variantConfig,'variantConfig',variantConfigFlatNames);
assignin('base','variantConfig',variantConfig);

[path, modelName] = fileparts(modelFileName);
cd(path);
rtwbuild(modelName);
cd(curentDir);
disp(['Compiling took ',num2str(toc(startTime)),' seconds']);
