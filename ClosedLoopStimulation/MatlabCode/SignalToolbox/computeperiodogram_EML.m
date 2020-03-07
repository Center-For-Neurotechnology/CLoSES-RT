function [Pxx,F,RPxx,Fc] = computeperiodogram_EML(x,win,nfft,esttype,Fs,options)
%COMPUTEPERIODOGRAM_EML was modified from COMPUTEPERIODOGRAM to run in simulink real time
% @Rina Zelmann 20160831
%
%COMPUTEPERIODOGRAM   Periodogram spectral estimation.
%   This function is used to calculate the Power Spectrum Sxx, and the
%   Cross Power Spectrum Sxy.
%
%   Sxx = COMPUTEPERIODOGRAM(X,WIN,NFFT) where x is a vector returns the
%   Power Spectrum over the whole Nyquist interval, [0, 2pi).
%
%   Sxy = COMPUTEPERIODOGRAM({X,Y},WIN,NFFT) returns the Cross Power
%   Spectrum over the whole Nyquist interval, [0, 2pi).
%
%   Inputs:
%    X           - Signal vector or a cell array of two elements containing
%                  two signal vectors.
%    WIN         - Window
%    NFFT        - Number of frequency points (FFT) or vector of
%                  frequencies at which periodogram is desired
%    ESTTYPE     - A string indicating the type of window compensation to
%                  be done. The choices are: 
%                  'ms'    - compensate for Mean-square (Power) Spectrum;
%                            maintain the correct power peak heights.
%                  'power' - compensate for Mean-square (Power) Spectrum;
%                            maintain the correct power peak heights.
%                  'psd'   - compensate for Power Spectral Density (PSD);
%                            maintain correct area under the PSD curve.
%     REASSIGN   - A logical (boolean) indicating whether or not to perform
%                  frequency reassignment
%
%   Output:
%    Sxx         - Power spectrum [Power] over the whole Nyquist interval. 
%      or
%    Sxy         - Cross power spectrum [Power] over the whole Nyquist
%                  interval.
%
%    F           - (vector) list frequencies analyzed
%    RSxx        - reassigned power spectrum [Power] over Nyquist interval
%                  has same size as Sxx.  Empty when 'reassigned' option
%                  not present.
%    Fc          - center of gravity frequency estimates.  Same size as
%                  Sxx.  Empty when 'reassigned' option not present.
%
%   Copyright 1988-2015 The MathWorks, Inc.

narginchk(5,7);
if nargin<6
  reassign = false;
  range = 'twosided';
else
  reassign = options.reassign;
  range = options.range;
end


% use normalized frequencies when Fs is empty
if isempty(Fs)
  Fs = 2*pi;
end

% Validate inputs and convert row vectors to column vectors.
[x,~,y,is2sig,win] = validateinputs(x,win,nfft); %RIZ removed part of validation -> assumes CORRECT inputs

% Window the data
xw = bsxfun(@times,x,win);


% Compute the periodogram power spectrum [Power] estimate
% A 1/N factor has been omitted since it cancels

%[Xx,F] = computeDFT_FFT_EML(xw,nfft,Fs);
[Xx,F] = computeDFT_FreqBin_EML(xw,nfft,Fs);
if reassign
  xtw = bsxfun(@times,x,dtwin(win,Fs));
  %Xxc = computeDFT_FFT_EML(xtw,nfft,Fs);
  Xxc = computeDFT_FreqBin_EML(xtw,nfft,Fs);
  Fc = -imag(Xxc ./ Xx);
  Fc(~isfinite(Fc)) = 0;
  Fc = bsxfun(@plus,F,Fc);
end

% if two signals are used, we are being called from welch and are not
% performing reassignment.
yw=[]; % RIZ: added to conform with Simulink coder
if is2sig
  yw = bsxfun(@times,y,win);
end 

% Evaluate the window normalization constant.  A 1/N factor has been
% omitted since it will cancel below.
if any(strcmpi(esttype,{'ms','power'}))
  if reassign
    if isscalar(nfft)
      U = nfft*(win'*win);
    else
      U = numel(win)*(win'*win);
    end
  else
    % The window is convolved with every power spectrum peak, therefore
    % compensate for the DC value squared to obtain correct peak heights.
    U = sum(win)^2;
  end
else
    U = win'*win;  % compensates for the power of the window.
end

if is2sig
%  [Yy,F] = computeDFT_FFT_EML(yw,nfft,Fs);
    [Yy,F] = computeDFT_FreqBin_EML(yw,nfft,Fs);

  % We use bsxfun here because Yy can be a single vector or a matrix
  Pxx = bsxfun(@times,Xx,conj(Yy))/U;  % Cross spectrum.
else
  Pxx = Xx.*conj(Xx)/U;                % Auto spectrum.
end

% Perform reassignment
if reassign
  RPxx = reassignPeriodogram(Pxx, F, Fc, nfft, range);
else
  RPxx = []; 
  Fc = [];
end



%--------------------------------------------------------------------------
function [x,Lx,y,is2sig,win] = validateinputs(xin,win,~)
% Validate the inputs to computexperiodogram and convert row vectors to
% column vectors for backwards compatiblility with R2014a and prior
% releases

% Set defaults and convert to row vectors to columns.
y     = [];
is2sig= false;
win   = win(:);
Lw    = length(win);

% Determine if one or two signal vectors was specified.
if iscell(xin),
    if length(xin) > 1,
        y = xin{2};
        %if isvector(y) %RIZ: Assumes correct input if vector
        %    y = y(:);
        %end
        is2sig = true;
    end
    x = xin{1};
end

%RIZ: Assumes correct input if vector
%if isvector(x)
%    x = x(:);
%end

Lx = size(x,1);

%RIZ: removed error handling!
% if is2sig,
%     Ly  = size(y,1);
%     if Lx ~= Ly,
%         error(message('signal:computeperiodogram:invalidInputSignalLength'))
%     end
%     if size(x,2)~=1 && size(y,2)~=1 && size(x,2) ~= size(y,2)
%         error(message('signal:computeperiodogram:MismatchedNumberOfChannels'))
%     end
% end
% 
% if Lx ~= Lw,
%     error(message('signal:computeperiodogram:invalidWindow', 'WINDOW'))
% end
% 
% if (numel(x)<2 || numel(size(x))>2)
%     error(message('signal:computeperiodogram:NDMatrixUnsupported'))
% end

% -------------------------------------------------------------------------
function RP = reassignPeriodogram(P, f, fcorr, nfft, range)

% for each column input of Sxx, reassign the power additively
% independently.

nChan = size(P,2);

nf = numel(f);
fmin = f(1);
fmax = f(end);

% compute the destination row for each spectral estimate
% allow cyclic frequency reassignment only if we have a full spectrum
if isscalar(nfft) && strcmp(range,'twosided')
  rowIdx = 1+mod(round((fcorr(:)-fmin)*(nf-1)/(fmax-fmin)),nf);
else
  rowIdx = 1+round((fcorr(:)-fmin)*(nf-1)/(fmax-fmin));
end

% compute the destination column for each spectral estimate
colIdx = repmat(1:nChan,nf,1);

% reassign the estimates that fit inside the frequency range
P = P(:);
idx = find(rowIdx>=1 & rowIdx<=nf);
RP = accumarray([rowIdx(idx) colIdx(idx)], P(idx), [nf nChan]);

% -------------------------------------------------------------------------
function Wdt = dtwin(w,Fs)
% differentiate window in time domain via cubic spline interpolation

% compute the piecewise polynomial representation of the window
% and fetch the coefficients
n = numel(w);
pp = spline(1:n,w);
[breaks,coefs,npieces,order,dim] = unmkpp(pp);

% take the derivative of each polynomial and evaluate it over the same
% samples as the original window
ppd = mkpp(breaks,repmat(order-1:-1:1,dim*npieces,1).*coefs(:,1:order-1),dim);

Wdt = ppval(ppd,(1:n)').*(Fs/(2*pi));
