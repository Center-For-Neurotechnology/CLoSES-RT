function [sumCoherencePerChannel, avCoherence, coherenceValue, pairChannels] = runCoherence_NoDownsampling_EML(filteredData, lowFreq, highFreq, Fs, detectChannelInds)
%#codegen
% Returns magnitude-square coherence averaged across channels.
% Coherence is computed between pairs of channels for the whole time window in the specified frequency bins
% Run mscohere in filteredData
% Could probably be made quicker by computing only Pxy (cross PSD) instead of coherence

%Inputs:
%   1. filteredData time x channels matrix with data from which to compute coherence
%   2. freqBins: specify frequencies of interest (to avoid computing coherence in whole spectrum)
%   3. Fs: Sampling Frequency
%
%Output:
%   1. magnitude-square coherence. diagonal is 1 as it is the coherence of channels with themselves.
%coder.extrinsic('tic');
%coder.extrinsic('toc');
%coder.extrinsic('num2str');

%tStart = tic;
nFreqs = 4; % RIZ: This is really the number of points of interest t FIX because it is needed for simulink real time!
nChannels = size(filteredData,2);
nPairs =  nChannels * (nChannels-1) /2;
coherenceValueAllFreqs = zeros(nFreqs/2+1, nPairs);
coherenceValue = zeros(1, nPairs);
sumCoherencePerChannel = zeros(1, nChannels); %Sum of coherence for each channel -> use to have same dimensionality as every other feature
avCoherence=0;      %Average coherence across all channels
pairChannels = zeros(1, nPairs);
if sum(filteredData(:))==0
    return;
end

freqBins = linspace(lowFreq, lowFreq+highFreq, nFreqs);
options.nfft = freqBins; %RIZ: DO NOT CHANGE! - only FFT method can be used in simulink real time and I had to hardcode NFFT=32 in computeDFT_FFT_EML.m!!! freqBins; %At which frequenceies to compute periodogram
options.Fs = Fs;
filteredDataSlow = filteredData; %downsample(filteredData,25); %round(Fs/(highFreq*10))); % keep 10 times highest frequency (could be less)
if all(size(filteredDataSlow)>1) 
    %Configuration (modified in part from pwelchparse
    lenData = size(filteredDataSlow,1);
    L = fix(lenData./2.5);    %ONLY 4 sections to reduce time! %fix(lenData./4.5);    % 8 sections
    noverlap = fix(0.5.*L); % 50% overlap
    win = hamming(L); % use Hamming window
    % Compute the number of segments
    k = round((lenData-noverlap)./(L-noverlap));
    %   coherenceValue1 = mscohere(filteredData, filteredData, windowType, noverlap, freqBins, Fs);
    %mscohere is NOT supported by CODER -> we need to compute using FFT
    % Cxy = (Sxy)^2 / (Sxx Syy)
    %coherenceValue = welch({filteredData, filteredData},'mscohere', windowType, noverlap, freqBins, Fs);
    %code modified from welch.m
    LminusOverlap = L-noverlap;
    xStart = 1:LminusOverlap:k*LminusOverlap;
    xEnd   = xStart+L-1;
    Sxx = zeros(nFreqs,nChannels,class(filteredDataSlow));
    Sxy = zeros(nFreqs,1,class(filteredDataSlow));
    cmethod = @plus;
    [Pxx,w] = localComputeSpectra(Sxx,filteredDataSlow,[],xStart,xEnd,win,options,'mscohere',k,cmethod);
    %Pyy = localComputeSpectra(Syy,y,[],xStart,xEnd,win,options,esttype,k,cmethod,freqVectorSpecified);
    % Cross PSD.  The frequency vector and xunits are not used.
    %Create list of pairs:
    pairChannels = getPairsChannels([1:nChannels]) ;
    
    for iPair=1:size(pairChannels,1) % Only compute pxy for paris of values!
        if ~isempty(intersect(detectChannelInds, iPair)) %Only compute for those pairs that will be used for detection!
            indCh1 = pairChannels(iPair,1);
            indCh2 = pairChannels(iPair,2);
            Pxy = localComputeSpectra(Sxy, filteredDataSlow(:,indCh1),filteredDataSlow(:,indCh2), xStart, xEnd, win, options,'mscohere',k,cmethod);
            coherVal = (abs(Pxy).^2)./bsxfun(@times,Pxx(:,indCh1),Pxx(:,indCh2)); % Cxy
            coherenceValueAllFreqs(1:size(Pxy,1), iPair) = coherVal;
            coherenceValue(1,iPair) = mean(coherVal,1); 
        end
    end
    % end of code from welch.m
    
    %[psdx, freq] = computePSDusingFFT(x, N, Fs)
    avCoherence = mean(coherenceValue);    % average across all intereactions
    sumCoherencePerChannel = sum(coherenceValue, 2);   % Sum of coherence per channel
%    tElapsed = toc(tStart);
%disp(['Elapsed Time Coherence: ',num2str(tElapsed)])
else
    disp(['Warning: filtered data is too small - do you have more than 1 channel? (dim: ', size(filteredDataSlow),')'])
end

end

function [Pxx,w] = localComputeSpectra(Sxx,x,y,xStart,xEnd,win,options,esttype,k,cmethod)

    if isempty(y),
        for ii = 1:k
            [Sxxk,w] = computeperiodogram_EML({x(xStart(ii):xEnd(ii),:)},win,options.nfft,esttype,options.Fs);
            Sxx  = cmethod(Sxx,real(Sxxk));
        end
    else
        for i = 1:k
            [Sxxk,w] =  computeperiodogram_EML({x(xStart(i):xEnd(i),:),y(xStart(i):xEnd(i),:)},win,options.nfft,esttype,options.Fs);
            Sxx  = cmethod(Sxx,real(Sxxk));
        end
    end
    Sxx = Sxx./k; % Average the sum of the periodograms

    % Compute the 1-sided or 2-sided PSD [Power/freq] or mean-square [Power].
    % Also, corresponding freq vector and freq units.
    %[Pxx,w,units] = computepsd(Sxx,w,options.range,options.nfft,options.Fs,esttype);
    %[Pxx, w] = computeMeanSquarePower(Sxx, w, options.nfft);
    [Pxx, w] = computeMeanSquarePower(Sxx, w, numel(options.nfft));
end

function [Sxx, w] = computeMeanSquarePower(Sxx, w, nfft)
   if rem(nfft,2),
      select = 1:(nfft+1)/2;  % ODD
      Sxx_unscaled = Sxx(select,:); % Take only [0,pi] or [0,pi)
      Sxx = [Sxx_unscaled(1,:); 2*Sxx_unscaled(2:end,:)];  % Only DC is a unique point and doesn't get doubled
   else
      select = 1:nfft/2+1;    % EVEN
      Sxx_unscaled = Sxx(select,:); % Take only [0,pi] or [0,pi)
      Sxx = [Sxx_unscaled(1,:); 2*Sxx_unscaled(2:end-1,:); Sxx_unscaled(end,:)]; % Don't double unique Nyquist point
   end
   w = w(select);
end

function [psdx, freq] = computePSDusingFFT(x, N, Fs)

    xdft = fft(x);
    xdft = xdft(1:N/2+1);
    psdx = (1/(Fs*N)) * abs(xdft).^2;
    psdx(2:end-1) = 2*psdx(2:end-1);
    freq = 0:Fs/length(x):Fs/2;
end


