function powerVal = conmputeBandPower(inputData, fs, freqRange)
%Computes power in specified frequency band
%Inputs: 
%   1. inputData: unfiltered (or braoadband filtered) EEG [time channels]
%   2. fs: sampling rate
%   3. freqRange: Frequency range of interest [f1 f2] (e.g. [65 100] for high gamma)
%
%Outputs:
%   1. powerVal: Power in requested range (scalar)

powerVal = bandpower(inputData, fs, freqRange); %bandpower uses 

%alternative:
%Using filtered data in freq range
%norm(x,2)^2/numel(x)