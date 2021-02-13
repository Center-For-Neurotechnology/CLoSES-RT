function [rxyCoeff, pVal] = compCorrelation_EML(filteredData)
%Compute correlation coefficient
[pairData1, pairData2, pairChannels]  = getMatrixOfPairedSignals_EML(filteredData);
nPairs = length(pairChannels);
rxyCoeff = zeros(1,nPairs);
pVal = zeros(1,nPairs);
%zeroLag = size(pairData1,1);
for iPair=1:nPairs
%    rxyVec = xcorr(pairData1(:,iPair), pairData2(:,iPair),'coeff'); %RIZ: use 'coeff' normalization??
%    rxy(iPair) = rxyVec(zeroLag);
    [rxyMat, pValMat] = corrcoef(pairData1(:,iPair), pairData2(:,iPair));
    rxyCoeff(iPair) = rxyMat(2,1);
    pVal(iPair) = pValMat(2,1);
end
