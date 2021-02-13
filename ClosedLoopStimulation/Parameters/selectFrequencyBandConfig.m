function [variantConfig, sCoreParams] = selectFrequencyBandConfig(freqBandName, variantConfig, sCoreParams)

nFreqs =1;
switch upper(freqBandName)
    case 'THETA'
        variantConfig.FREQ_LOW = 4;
        sCoreParams.Features.Coherence.lowFreq = 4;
        sCoreParams.Features.Coherence.highFreq = 8;
    %    sCoreParams.FrameSize = 1024;            % RIZ: change according to filter - 2^n
    case 'ALPHA'
        variantConfig.FREQ_LOW = 8;
        sCoreParams.Features.Coherence.lowFreq = 8;
        sCoreParams.Features.Coherence.highFreq = 15;
    %    sCoreParams.FrameSize = 1024;
    case 'BETA'
        variantConfig.FREQ_LOW = 15;
        sCoreParams.Features.Coherence.lowFreq = 15;
        sCoreParams.Features.Coherence.highFreq = 30;
   %     sCoreParams.FrameSize = 512;
    case 'LOWGAMMA'
        variantConfig.FREQ_LOW = 30;
        sCoreParams.Features.Coherence.lowFreq = 30;
        sCoreParams.Features.Coherence.highFreq = 60;
   %     sCoreParams.FrameSize = 256;        
    case 'HIGHGAMMA'
        variantConfig.FREQ_LOW = 65;
        sCoreParams.Features.Coherence.lowFreq = 65;
        sCoreParams.Features.Coherence.highFreq = 110;
   %     sCoreParams.FrameSize = 256;        
    case 'RIPPLE'
        variantConfig.FREQ_LOW = 140;
        sCoreParams.Features.Coherence.lowFreq = 140;
        sCoreParams.Features.Coherence.highFreq = 200;
   %     sCoreParams.FrameSize = 128;        
    case 'HIGHGAMMARIPPLE'
        variantConfig.FREQ_LOW = 65200;
        sCoreParams.Features.Coherence.lowFreq = 65;
        sCoreParams.Features.Coherence.highFreq = 200;
   %     sCoreParams.FrameSize = 128;        
    case 'GAMMA'
        variantConfig.FREQ_LOW = 30110;        
        sCoreParams.Features.Coherence.lowFreq = 30;
        sCoreParams.Features.Coherence.highFreq = 110;
   %     sCoreParams.FrameSize = 256;        
    case 'SPINDLES'
        variantConfig.FREQ_LOW = 1216;  
        sCoreParams.Features.Coherence.lowFreq = 12;
        sCoreParams.Features.Coherence.highFreq = 16;
   %     sCoreParams.FrameSize = 512;        
    case 'NOFILTER'
        variantConfig.FREQ_LOW = 0;
   %     sCoreParams.FrameSize = 64;        
    case 'THETAALPHAGAMMA'
        variantConfig.FREQ_LOW = 4865200;  
        sCoreParams.Features.Coherence.lowFreq = 4;
        sCoreParams.Features.Coherence.highFreq = 200;
   %     sCoreParams.FrameSize = 1024;
        nFreqs =3;
    otherwise
    disp(['No Valid Frequency specified. Using default: ', num2str(variantConfig.FREQ_LOW)]);
end

%if (nFreqs ~= sCoreParams.decoders.txDetector.nFreqs)
    sCoreParams.decoders.txDetector.nFreqs = nFreqs;
    sCoreParams.decoders.txDetector.nFilteredChannels = sCoreParams.decoders.txDetector.nChannels *  sCoreParams.decoders.txDetector.nFreqs;
%end


