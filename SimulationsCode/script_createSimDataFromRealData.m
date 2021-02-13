% This script is not normally used - it needs pre-processed files.
% It was kept for compatibility 
% Use script_createSimDataFromNEVfile.m instead
%
%
% it is already bipolar!
pName = 'P1'; 
expType = 'MSIT'; %'ECR'; %
posFix = ''; %'all'; %does not exist for ECR
gralDir = 'D:\data'; 
useParcelation =0;

selChNames = { 'LOF01 LOF02',    'LOF02 LOF03',    'LAF01 LAF02',    'LAF02 LAF03',    'LAF03 LAF04',    'LAF04 LAF05',    'LAF05 LAF06',    'LAF06 LAF07',    'LMF02 LMF03',    'LMF03 LMF04',    'LMF04 LMF05',    'LMF05 LMF06',    'LVF15 LVF16',    'ROF04 ROF05',    'ROF05 ROF06',    'ROF06 ROF07',    'ROF07 ROF08',    'ROF08 ROF09',    'ROF09 ROF10',    'ROF10 ROF11',    'RMF01 RMF02',    'RMF02 RMF03',    'RMF03 RMF04',    'RMF04 RMF05',    'RMF05 RMF06',    'RVF13 RVF14',    'RVF15 RVF16'};
rawEEGFileName = [gralDir,filesep,pName,filesep,'BIPOLFieldTripFormat_',expType,'_AlignedToImagePresentation_Blocks',pName,'TFR_updated.mat'];
parcelationFileName = [gralDir,filesep,pName,'\',expType,'\UpdatedFT_Analyzed\',expType,'SummaryParcelMapsTake2',pName,'.mat'];

% MORE CONFIG
firstTrial = 1;
nTrials = 413;
nChannels = 20;
lTrialSec = 6; 
%[ft_data3.time{1}(1),  ft_data3.time{1}(1)];

%Load EEG data and parcelation data
load(rawEEGFileName);
lTrial = lTrialSec * ft_data3.fsample; %Number of samples per trial - 6seconds
minProba =0;

if useParcelation==1
    stParcelationInfo = load(parcelationFileName,'TargetLabels','ParcellationValueHeaders','ParcellationValues');
    TargetLabels = stParcelationInfo.TargetLabels;
    ParcellationValueHeaders = stParcelationInfo.ParcellationValueHeaders;
    ParcellationValues = stParcelationInfo.ParcellationValues;    
end
%    chPairs = [ChannelPairNamesBank1; ChannelPairNamesBank2];

% Select channels
indChExclude =[];
if ~isempty(selChNames)
    %if selChannels are specified - use those ones
    indChannels=zeros(1,length(selChNames));
    for iCh=1:length(selChNames)
        indChannels(iCh) = find(strcmpi(ft_data3.label, selChNames{iCh}));
        cNames = strsplit(selChNames{iCh});
        chPairs(iCh,1) = cNames(1);
        chPairs(iCh,2) = cNames(2);
    end
    nChannels = length(indChannels);
else
    chPairs = [ChannelPairNamesBank1; ChannelPairNamesBank2];

    %if NO channel specified, look by region
    indLabelACC = find(strcmpi(TargetLabels, 'caudalanteriorcingulate'));
    indChACC = intersect(find(ParcellationValues(:,8) == indLabelACC),find(ParcellationValues(:,2)> minProba)); %at least 0.5 proba of being in the label
    indLabelDLPFC = find(strcmpi(TargetLabels, 'caudalmiddlefrontal'));
    indChindLabelDLPFC = intersect(find(ParcellationValues(:,8) == indLabelDLPFC),find(ParcellationValues(:,2)> minProba)); %at least 0.5 proba of being in the label
    indLabelLOF = find(strcmpi(TargetLabels, 'lateralorbitofrontal'));
    indChLOF = intersect(find(ParcellationValues(:,8) == indLabelLOF),find(ParcellationValues(:,2)> minProba)); %at least 0.5 proba of being in the label
    indLabelTEMP = find(strcmpi(TargetLabels, 'temporal'));
    indChTEMP = intersect(find(ParcellationValues(:,8) == indLabelTEMP),find(ParcellationValues(:,2)> minProba)); %at least 0.5 proba of being in the label
    
    indChannels = [indChACC; indChindLabelDLPFC];
    indChannels(nChannels+1:end) =[];
    %Remove channels with activity > 50mV
    for iCh=1:nChannels
        if (any(abs(EEGVals(iCh,:)) > 100)) %BAD WAY of removing IED channels!!!
            indChExclude = [indChExclude,iCh];
        end
    end
end

%Get EEG data for the selected channels
EEGVals = zeros(nChannels, nTrials * lTrial);
for iTrial=1:nTrials
    indTime = (iTrial-1) *lTrial +1 : iTrial *lTrial;
    EEGVals(:,indTime) = ft_data3.trial{iTrial+firstTrial-1}(indChannels,:);
end
timeVals = linspace(0,nTrials * lTrial/ft_data3.fsample, nTrials * lTrial);

EEGVals(indChExclude,:) =[];
indChannels(indChExclude) =[];
nChannels = size(EEGVals,1);
%selChannelNames = chPairs(indChannels,:)
selChannelNames = chPairs;
if useParcelation==1
    probaInRegion = ParcellationValues(indChannels,2);
else
    probaInRegion =[];
end
timesInTrial = ft_data3.time{1}; %They should be ALL the same
save(['C:\DARPA\DATA\Simulations\SimData_PREPROCESSED_',num2str(nChannels),'Channels_',expType,'_',pName,'_tr',num2str(firstTrial),'-',num2str(firstTrial+nTrials),'_',date,'.mat'],...
    'EEGVals', 'timeVals', 'lTrialSec', 'lTrial', 'timesInTrial', 'indChannels', 'selChannelNames','nChannels','probaInRegion','firstTrial','nTrials');

