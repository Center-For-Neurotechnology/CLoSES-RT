function [pairData1, pairData2, pairChannels]  = getMatrixOfPairedSignals_EML(filteredData)
%creates two vectors with singals of pairs - to be used n correlation


nChannels = size(filteredData,2);
lSignal = size(filteredData,1);

%Create list of pairs:
pairChannels = getPairsChannels([1:nChannels]) ;
nPairs = size(pairChannels,1);

%Initialize
pairData1 = zeros(lSignal, nPairs);
pairData2 = zeros(lSignal, nPairs);

%Re-organize data to have two vectors with data 
for iPair=1:nPairs % Only compute pxy for paris of values!
    indCh1 = pairChannels(iPair,1);
    indCh2 = pairChannels(iPair,2);
    pairData1(:,iPair) = filteredData(:,indCh1);
    pairData2(:,iPair) = filteredData(:,indCh2);
end

