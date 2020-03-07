function pairChannels = getPairsChannels(indChannels) 

    %RIZ: If at some point we have channels names -> change here!
    nChannels = length(indChannels);
    nPairs =  nChannels * (nChannels-1) /2;

    %This same code is in GUIClosedLoop - If changed here it SHOULD be changed there!!
    tempCh = zeros(nPairs, 2);
    lastIndCh = 0;
    for iCh=1:nPairs
        indCh = (1:nChannels-iCh) + lastIndCh;
        if ~isempty(indCh)
            tempCh(indCh,1) = indChannels(iCh);
            indOthers = iCh+1:nChannels;
            tempCh(indCh,2) = indChannels(indOthers);
            lastIndCh = indCh(end);
        end
    end
    pairChannels = unique(sort(tempCh,2),'rows');  % pairChannels is (nChannels*(nChannels-1)/2, 2);
    %Copy to GUIClosedLoopConsole - up to here
