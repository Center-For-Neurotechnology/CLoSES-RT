function [Xx,f] = computeDFT_FreqBin_EML(xin,f,Fs)
%COMPUTEDFT_EML was modified from COMPUTEDFT to run in simulink real time
% @Rina Zelmann 20160831
%
%COMPUTEDFT Computes DFT using FFT or Goertzel
%   This function is used to calculate the DFT of a signal using the FFT 
%   or the Goertzel algorithm. 
%
%   [XX,F] = COMPUTEDFT(XIN,NFFT) where NFFT is a scalar and computes the 
%   DFT XX using FFT. F is the frequency points at which the XX is 
%   computed and is of length NFFT.
%
%   [XX,F] = COMPUTEDFT(XIN,F) where F is a vector with at least two 
%   elements computes the DFT XX using the Goertzel algorithm. 
%
%   [XX,F] = COMPUTEDFT(...,Fs) returns the frequency vector F (in hz)
%   where Fs is the sampling frequency
%
%   Inputs:
%   XIN is the input signal
%   NFFT if a scalar corresponds to the number of FFT points used to 
%   calculate the DFT using FFT.
%   NFFT if a vector corresponds to the frequency points at which the DFT
%   is calculated using goertzel.
%   FS is the sampling frequency 

% Copyright 2006-2014 The MathWorks, Inc.

% [1] Oppenheim, A.V., and R.W. Schafer, Discrete-Time Signal Processing,
% Prentice-Hall, Englewood Cliffs, NJ, 1989, pp. 713-718.
% [2] Mitra, S. K., Digital Signal Processing. A Computer-Based Approach.
% 2nd Ed. McGraw-Hill, N.Y., 2001.

%narginchk(2,3);


    %f = nfft(:); % if nfft is a vector then it contains a list of freqs
    
    % see if we can get a uniform spacing of the freq vector
    fstart = f(1);
    fstop = f(end);
    npts = numel(f);
    %[fstart, fstop, m, maxerr] = getUniformApprox(f);
    
    % check if the number of steps in Goertzel ~  1 k1 N*M is greater
    % than the expected number of steps in CZT ~ 20 k2 N*log2(N+M-1)
    % where k2/k1 is empirically found to be ~80.
    n = size(xin,1);
   % islarge = npts > 80*log2(nextpow2(npts+n-1));

    % Use CZT to compute raw DFT

    % start with initial complex weight 
    Winit = exp(2i*pi*fstart/Fs); 

    % compute the relative complex weight 
    Wdelta = exp(2i*pi*(fstart-fstop)/((npts-1)*Fs)); 

    % feed complex weights into chirp-z transform 
    Xx = czt_EML(xin, npts, Wdelta, Winit); 
end
