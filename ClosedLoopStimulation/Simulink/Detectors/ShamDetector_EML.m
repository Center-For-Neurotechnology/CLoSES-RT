function shamEventDetected = ShamDetector_EML(detectShamBool, targetShamFrequencySec, stepPeriod)
%#codegen

if detectShamBool
    spikeProb = stepPeriod / targetShamFrequencySec;
    shamEventDetected = rand(1) < (spikeProb);
else
    shamEventDetected = false;
end
