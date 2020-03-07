function smoothData = SmoothBox(data,boxLength,dim)

% Generic zero-phase boxcar smoothing utility.

smoothData = zeros(size(data));
if dim == 1
for ii = 1:size(smoothData,2)
    smoothData(:,ii) = filtfilt(ones(boxLength),boxLength,data(:,ii));
end
end
