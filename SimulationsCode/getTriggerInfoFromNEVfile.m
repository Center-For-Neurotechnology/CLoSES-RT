function [triggerVals, ImageOn]= getTriggerInfoFromNEVfile(fileNameNSx, thLengthAbortedBlockSamples)

% This function is based on Angelique's pre-processing extraction code
%  e.g.  Preprocessing_Fieldtrip_XXXXXX
if ~exist('thLengthAbortedBlockSamples','var') 
    thLengthAbortedBlockSamples = 5000;
end

[path, onlyFileName] = fileparts(fileNameNSx);
NEVFileName = [path, filesep, onlyFileName, '.nev'];

NEV= openNEV(NEVFileName,'overwrite');
NSXheader = openNSx(fileNameNSx,'noread');
Fs = NSXheader.MetaTags.SamplingFreq;
dataPtsNSXFile = NSXheader.MetaTags.DataPoints;

    r_event_time=NEV.Data.SerialDigitalIO.TimeStampSec;
    r_event_index_all=round(r_event_time/(1/Fs));

    r_event_indval=NEV.Data.SerialDigitalIO.UnparsedData-65280;

        
    response_event_idx= find((NEV.Data.SerialDigitalIO.UnparsedData-65280)>0);
    
%      BlockStart=find((NEV.Data.SerialDigitalIO.UnparsedData-65280)==64);
%      BlockStartTime=r_event_time((NEV.Data.SerialDigitalIO.UnparsedData-65280)==64);
%     RespStart=find((NEV.Data.SerialDigitalIO.UnparsedData-65280)==83);
%     RespStartTime=r_event_time((NEV.Data.SerialDigitalIO.UnparsedData-65280)==83);
%      FixStart=find((NEV.Data.SerialDigitalIO.UnparsedData-65280)==0);
%      FixStartTime=r_event_time((NEV.Data.SerialDigitalIO.UnparsedData-65280)==0);

     tmp_event=zeros(1,dataPtsNSXFile);
%     tmp_event_timing=NEV.Data.SerialDigitalIO.TimeStampSec(response_event_idx);
%     tmp_event_timing_idx=round(round(tmp_event_timing/dt)/2);
%     TimingMatrix=zeros(size(r_event_indval,1),10);
    
    vrbit=dec2bin(r_event_indval,8);
    
%      tmp_event(5, r_event_index_all(r_event_indval==4))=1; %Fixation
%      tmp_event(6, r_event_indval==0)=1; %TrialStart
%      tmp_event(7, r_event_indval==64)=1; %BlockStart

%     CongruentOnset=str2num(vrbit(:,3));
%     ValenceOnset=str2num(vrbit(:,4));
    ImageOnset=str2num(vrbit(:,7));
    DiffImageOn=find(diff([0; ImageOnset])==1);
    DiffImageOff=find(diff([ImageOnset; 0])==-1) +1; % + 1 to ensure at least 2 pulses per trigger

    %Remove blocks that were cancelled (assume very long pulses come from aborted blocks)
    indFatTrials = find(r_event_index_all(DiffImageOff)-r_event_index_all(DiffImageOn) > thLengthAbortedBlockSamples);
    DiffImageOn(indFatTrials)=[];
    DiffImageOff(indFatTrials)=[];

    %Create Triggers
    for GH=1:length(DiffImageOff)
        tmp_event(1, r_event_index_all(DiffImageOn(GH)):r_event_index_all(DiffImageOff(GH)))=1; %Image
    end
triggerVals = tmp_event(1,:);
ImageOn=find(diff(tmp_event(1,:))>0);

%     Response=find(diff(tmp_event(8,:))>0);
%     Fixation=find(diff(tmp_event(5,:))>0);
%     StimOnset=find(diff(tmp_event(2,:))>0);
%     StimOffset=find(diff(tmp_event(2,:))<0);
%      TrialStart=find(diff(tmp_event(6,:))>0);
%      BlockStart=find(diff(tmp_event(7,:))>0);


