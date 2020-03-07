function ClosedLoopStimConsole(dirBase)
% ClosedLoopStimConsole is largely based in NeuroModCosole by Anish
% Modified to generlaize UDP packets and to adapt to simulink real time 
%
% Sent UDP data is now:
% 1. nspTime
% 2-5: each correspond to 1xtime vector with 0-1 values
% 2. stimHappenning (STIMULATION is actually happening) - probably MOST important information
% 3. isEventDetected (1 if event was detected)
% 4. shamDetection (only useful for epilepsy related experiments)
% 5. isUpdatingThreshold (RIZ: NOT sure if useful!)
% 6->on:  data, each corresponds to nVizChannels x time - defined by sCoreParams.decoders.txDetector.channel1-2(sCoreParams.viz.channelInds) 
% NOTE: 7 is NOT actually in position 7 but in position 6 + sCoreParams.viz.channelInds, 8 is in 6 + 2* sCoreParams.viz.channelInds, etc
% 6. features
% 7. threshold 
% 8. filtered data
% 9. EEGData (raw unfiltered data , usually bipolar data)


%Global environment variable
global gEnv
if isempty(gEnv)
    gEnv = getEnvironment;
end
if ~exist('dirBase','var')
    dirBase=pwd; %Compiled program to send should be dirBase/CompileFiles/ClosedLoopStimXpcTarget
end
        
%Create Figure
h_console = figure('Name','Neural Control Console', 'MenuBar','none','NumberTitle','off',...
    'ToolBar','none','Position',[400   200   835     633],'Color','black',...
    'CloseRequestFcn',@CloseConsole);
axis off;
% initialize spanning variables
h_waiting = text('Position',[0 0],'String','Waiting for xPC...','FontSize',18,'Color','green');
h_compile = uicontrol('Parent',h_console,'Position',[550 100 80 60],'Style','pushbutton','Callback',@UserCompile,'Enable','off','String','Compile Model');
h_go = uicontrol('Parent',h_console,'Position',[450 100 80 60],'Style','pushbutton','Callback',@GoSwitch,'Enable','off','String','Start Block');
h_start = uicontrol('Parent',h_console,'Position',[650 100 80 60],'Style','pushbutton','Callback',@StartSwitch,'Enable','off','Visible','off','String','Re-Start');
h_stop = uicontrol('Parent',h_console,'Position',[750 100 80 60],'Style','pushbutton','Callback',@StopSwitch,'Enable','off','Visible','off','String','STOP');

% Initialize receiver
pause(1);
pnet('closeall')
vizSocket = InitUDPreceiver('127.0.0.1',59124);

%Initialize variables
IS_TEST_RUN = 1; % set to 1 if NSP are not connected and this is simply used to test (avoids checking for nspTime increase)
targetConnected = false;
blockRunning = false;
userApprovedStart = false;
tg = [];
h_featureTrace = [];
h_thresh = [];
h_lockout = [];
h_shamDetected = [];
h_eventDetected = [];
h_rawEEGTrace = [];
h_realStimTrace = [];
h_triggeredWave = [];
h_titleCount = [];
sCoreParams = [];
packetDepthSamp = 0;
waveSpan = 0;
totalStim = 0;
totalRandStim = 0;
expectedDataWidth = 0;
dataStreamHistory = [];
pulseTriggeredWave = [];

%Constants to define inputs from UDP:
NSP_TIME = 1;
STIM_HAPPENNING = 2;
EVENT_DETECTED = 3;
SHAM_DETECTED = 4;
UPDATING_TH = 5;
FIRST_FEATURE = 6;
featurePositions =[];
thresholdPositions=[];
filteredDataPositions=[];
EEGDataPositions=[];
%For threshold, filteredData and unfiteredEEGData the position is
%determined in real time to account for multiple channels
% IF UDP packeges sent are changes in OutputToVisualization.slx -> modify numbers here

%agentTimer = timer('TimerFcn',@CheckAgents,'Period',1,'BusyMode','drop','ExecutionMode','fixedRate');
agentTimer = timer('TimerFcn',@CheckAgentsSRT,'Period',1,'BusyMode','drop','ExecutionMode','fixedRate');
assignin('base','vizTimer',agentTimer);
start(agentTimer)


    function UpdateViz(~,~,~)
        persistent timeStampPrev
        persistent triggerAvData;
        if isempty(timeStampPrev)
            timeStampPrev = 0;
        end
        if isempty(triggerAvData)
            triggerAvData = zeros(size(dataStreamHistory,1),length(EEGDataPositions));
        end
        if blockRunning
            if ishandle(h_console)
                set(0,'CurrentFigure',(h_console));
            end

            newData = ReceiveUDP(vizSocket,'latest','double'); %Get new UDP package
            if isempty(newData) || numel(newData) < packetDepthSamp*expectedDataWidth
                return
            end

            newData = reshape(newData(1:(packetDepthSamp*expectedDataWidth)),[packetDepthSamp,expectedDataWidth]);
            dataStreamCandidate = [dataStreamHistory((packetDepthSamp+1):end,:); newData];
            timeStamp = dataStreamCandidate(end,NSP_TIME);
            
            % Note 2016.08.15 ANISH AND RINA: This if statement checks
            % whether a given packet is any timesteps later than what we've
            % seen previously. However, if there is no data, this means
            % that the console will simply display nothing. It would be
            % good to at least indicate that some data is arriving but
            % we're ignoring it, because the timestamp comes from the NSP
            % and sometimes we debug with the NSP off.
            % RIZ 2016.08.22: added IS_TEST_RUN to be able to use when testing and NSP
            % are not gathering data
            if timeStamp > timeStampPrev || IS_TEST_RUN
                dataStreamHistory = dataStreamCandidate;
                
                set(h_featureTrace,'YData',dataStreamHistory(:,featurePositions));
                set(h_thresh,'YData',dataStreamHistory(:,thresholdPositions));
                %lockoutThresh = nan(size(dataStreamHistory(:,thresholdPositions)));
                %             lockoutThresh(dataStreamHistory(:,UPDATING_TH)> 0.1) = dataStreamHistory(dataStreamHistory(:,STIM_HAPPENNING)>0.1,thresholdPositions);
                %set(h_lockout,'YData',lockoutThresh);
                set(h_eventDetected,'YData',dataStreamHistory(:,EVENT_DETECTED));
                set(h_shamDetected,'YData',dataStreamHistory(:,SHAM_DETECTED));
                set(h_rawEEGTrace,'YData',dataStreamHistory(:,EEGDataPositions));
                set(h_realStimTrace,'YData',dataStreamHistory(:,STIM_HAPPENNING));
                
                % set(h_titleCount,'String',(sprintf('Total stims: %i %i ',totalStim,totalRandStim)));
                timeStampPrev = timeStamp;
                triggerAvData = displayTiggerAverageSignal(triggerAvData);
                
                
            end
        elseif ~blockRunning && targetConnected
            StartBlock;
            blockRunning = true;
        end
    end

    % CheckAgents: XPC target version (MATLAB2013a)
    function CheckAgents(h,~,~)
%         
%         try
%             if gEnv.net.xpc.netBootRunning && ~targetConnected
%                 % The lack of a semicolon here is necessary!
%                 % Otherwise, the xpc object doesn't actually re-check.
%                 tg = xpctarget.xpc('xCoreTarget')
%             end
%             set(h_waiting,'String',sprintf('Searching for xPC...is it on? %0.f',h.TasksExecuted));
%             
%             if ~isempty(tg) && strcmpi(tg.Connected,'Yes')
%                 targetConnected = true;
%                 set(h_waiting,'String','Target Connected');
%                 set(h_go,'Enable','on');
%                 set(h_compile,'Enable','on');
%                 pause(.001);
%                 if userApprovedStart
%                     set(h_waiting,'String','Initializing...');
%                     pause(.001);
%                     StartBlock;
%                     delete(h_go);
%                     delete(h_compile);
%                     if ishandle(h_waiting)
%                         set(h_waiting,'String','');
%                     end
%                     pause(.5);
%                     stop(h);
%                 end
%                 
%             else
%                 if ~gEnv.net.xpc.netBootRunning && exist('xpcnetboot.bat','file');
%                     set(h_waiting,'String',sprintf('Setting up boot agent...'));
%                     pause(.001);
%                     setxpcenv('USBSupport','off');
%                     bootpath = which('xpcnetboot.bat');
%                     updatexpcenv;
%                     system(bootpath);
%                     gEnv.net.xpc.netBootRunning = true;
%                     tg = [];
%                     set(h_waiting,'String',sprintf('Searching for xPC...%0.f',h.TasksExecuted));
%                     pause(.001);
%                     
%                 elseif ~exist('xpcnetboot.bat','file')
%                     xpcexplr
%                     keyboard
%                 end
%             end
%             
%         catch e
%             disp(e.stack(1));
%             disp(e.message);
%             targetConnected = false;
%         end
%         
    end

    % CheckAgentsSRT: Simulink Real Time version (MATLAB 2016)
    function CheckAgentsSRT(h,~,~)
        %Similar to CheckAgents but modified for simulink real time
        try
            %if gEnv.net.xpc.netBootRunning && ~targetConnected
            if ~targetConnected
                % The lack of a semicolon here is necessary!
                % Otherwise, the xpc object doesn't actually re-check.
                tg = xpctarget.xpc('xCoreTarget')  %RIZ: check if name is correct or changed in SRT
            end
            set(h_waiting,'String',sprintf('Searching for xPC...is it on? %0.f',h.TasksExecuted));
            
            if ~isempty(tg) && strcmpi(tg.Connected,'Yes')
                targetConnected = true;
                set(h_waiting,'String','Target Connected');
                set(h_go,'Enable','on');
                set(h_compile,'Enable','on');
                pause(.001);
                if userApprovedStart %true when start button pressed
                    set(h_waiting,'String','Initializing...');
                    pause(.001);
                    StartBlock; %STARTS acquisition block!
                    delete(h_go);
                    delete(h_compile);
                    if ishandle(h_waiting)
                        set(h_waiting,'String','');
                    end
                    pause(.5);
                    stop(h);
                end
                
            else
               set(h_waiting,'String',sprintf('xPC target not found...is it on? If not boot and restart! '));
            end
          
        catch e
            disp(e.stack(1));
            disp(e.message);
            targetConnected = false;
        end
        
    end

    function StartBlock
        % Initializes parameters and variants and loads model
        stop(agentTimer)
        sCoreParams = InitCoreParams;
        assignin('base','sCoreParams',sCoreParams);
        [variantParams, variantConfig] = InitVariants();
        [variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
        FlattenAndTuneVariants(variantParams,'variantParams',variantParamsFlatNames);
        FlattenAndTune(variantConfig,'variantConfig',variantConfigFlatNames);
        assignin('base','variantParamsFlatNames',variantParamsFlatNames);
        assignin('base','variantConfigFlatNames',variantConfigFlatNames);

        %tg.load([pwd filesep 'CompileFiles' filesep 'PulseSessionMaster_SL']);
        tg.load([dirBase filesep 'CompileFiles' filesep 'ClosedLoopStimXpcTarget']);
        %Parameters that can be changed in real time
        tunableParams = NameTunableParams;
        for tuneInd = 1:length(tunableParams)
            disp(tunableParams{tuneInd});
            startVal = GetRealTimeValue(tg,tunableParams{tuneInd});
            underscores = strfind(tunableParams{tuneInd},'_');
            defaultStrLen = underscores(end-1);
            uicontrol('Parent',h_console,'Position',[500 625-(tuneInd*40) 195  20],'BackgroundColor','black','ForegroundColor','white','HorizontalAlignment','right',...
                'Style','text','String',tunableParams{tuneInd}(defaultStrLen+1:end));
            uicontrol('Parent',h_console,'Position',[700 625-(tuneInd*40) 80  20],'BackgroundColor','black','ForegroundColor','white','HorizontalAlignment','right',...
                'Style','edit','Callback',{@ModParam,tunableParams{tuneInd}},'String',num2str(startVal));
        end
%         lastControlPos = 625-(tuneInd*40);
%         %Variants Config can be changed in real time
%         [variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
%         for tuneInd = 1:length(variantConfigFlatNames)
%             disp(variantConfigFlatNames{tuneInd});
%             startVal = GetRealTimeValue(tg,variantConfigFlatNames{tuneInd});
%             underscores = strfind(variantConfigFlatNames{tuneInd},'_');
%             defaultStrLen = underscores(end-1);
%             uicontrol('Parent',h_console,'Position',[500 lastControlPos-(tuneInd*40) 195  20],'BackgroundColor','black','ForegroundColor','white','HorizontalAlignment','right',...
%                 'Style','text','String',variantConfigFlatNames{tuneInd}(defaultStrLen+1:end));
%             uicontrol('Parent',h_console,'Position',[700 lastControlPos-(tuneInd*40) 80  20],'BackgroundColor','black','ForegroundColor','white','HorizontalAlignment','right',...
%                 'Style','edit','Callback',{@ModVariant,variantConfigFlatNames{tuneInd}},'String',num2str(startVal));
%         end
        set(h_stop,'Visible','on','Enable','on');
        set(h_start,'Visible','on','Enable','on');
        
        %Starts the model and the data writer
        tg.start;
        StartWriter;
        % THE ACTUAL DRAWING
        expectedDataWidth = sCoreParams.write.maxSignalsPerStep;
        streamDepthSamp = sCoreParams.viz.streamDepthSec  / sCoreParams.core.stepPeriod;
        packetDepthSamp = sCoreParams.write.broadcastSec / sCoreParams.core.stepPeriod;
        dataStreamHistory = nan(streamDepthSamp,expectedDataWidth); % dataStreamHistory is the data coming from UDP
        %waveSpan = sCoreParams.viz.preTriggerSamp + sCoreParams.viz.postTriggerSamp + 1; 
        %pulseTriggeredWave = nan(sCoreParams.viz.maxTriggeredEvents * length(sCoreParams.viz.channelInds),waveSpan);
        %number of EEG channels of data sent with UDP is either the number
        %of analized channels or the subset seleted for visualization
        if sCoreParams.viz.channelInds > 0
            nChannels = length(sCoreParams.viz.channelInds); 
        else
            nChannels = sCoreParams.decoders.txDetector.nChannels;
        end
        featurePositions = FIRST_FEATURE:FIRST_FEATURE+nChannels-1;
        thresholdPositions = featurePositions(end)+1:featurePositions(end)+nChannels;
        filteredDataPositions = thresholdPositions(end)+1:thresholdPositions(end)+nChannels;
        EEGDataPositions = filteredDataPositions(end)+1:filteredDataPositions(end)+nChannels;
       % assignin('base','featurePositions',featurePositions);
       % assignin('base','thresholdPositions',thresholdPositions);
       % assignin('base','filteredDataPositions',filteredDataPositions);
       % assignin('base','EEGDataPositions',EEGDataPositions);

        %Plot 1: Features and Thresholds
        subplot(421)
        tAx = linspace(0,sCoreParams.viz.streamDepthSec,streamDepthSamp);
        h_featureTrace = plot(tAx,dataStreamHistory(:,featurePositions),'LineWidth',1,'LineStyle',':'); %Event detected
        hold on;
        axis off
        title('Detection Trace')
        h_thresh = plot(tAx,dataStreamHistory(:,thresholdPositions),'LineWidth',2);
        %lockoutThresh = nan(size(dataStreamHistory(:,thresholdPositions)));
        %lockoutThresh(dataStreamHistory(:,UPDATING_TH)> 0.1) = dataStreamHistory(dataStreamHistory(:,STIM_HAPPENNING)>0.1,thresholdPositions); %RIZ: ???
        %h_lockout = plot(tAx,lockoutThresh,'Color',[.5 .5 .5],'LineWidth',2);
        box off
        hold on;
        
        subplot(423)
        hold on;
        h_eventDetected = plot(tAx,dataStreamHistory(:,EVENT_DETECTED),'green','LineWidth',2);
        h_shamDetected = plot(tAx,dataStreamHistory(:,SHAM_DETECTED),'cyan','LineWidth',2);
        box off
        axis([-Inf Inf -.1 1])
        axis off
        title('Event/Sham Detections')
        
        subplot(425)
        h_realStimTrace = plot(tAx,dataStreamHistory(:,STIM_HAPPENNING),'magenta','LineWidth',2);
        axis([-Inf Inf -.1 1])
        box off
        axis off
        title('Real Stimulation')
        
        subplot(427)
        h_rawEEGTrace = plot(tAx,dataStreamHistory(:,EEGDataPositions),'LineWidth',1);
        box off
        axis off
        title('Raw Data')
        % END DRAWING
        
        vizTimer = timer('TimerFcn',@UpdateViz,'Period',sCoreParams.write.broadcastSec / 5,'BusyMode','drop','ExecutionMode','fixedRate');
        assignin('base','vizTimer',vizTimer);
        blockRunning = true;
        start(vizTimer)
    end

    function UserCompile(~,~,~)
        CompileModelComplete('ClosedLoopStimXpcTarget'); %Uses FIX parameter/Variant names
    end

    function CloseConsole(h_cons,~,~)
        disp('Closing Console!')
        stop(timerfind);
        evalin('base','StopWriter');
        delete(h_cons);
        
    end

    function GoSwitch(~,~,~)
        userApprovedStart = true;
    end

    function StopSwitch(~,~,~)
        disp('Stoping Closed-Loop Stimulation Control!')
        tg.stop;
        stop(timerfind);
        evalin('base','StopWriter');
        %delete(h_console);
    end

    function StartSwitch(~,~,~)
        disp('Starting Closed-Loop Stimulation Control!')
        StartBlock;
    end

    function ModParam(h_self,~,paramStr)
        paramVal = (get(h_self,'String'));
        paramValNum = double(eval(['[' paramVal ']']));
        SetRealTimeValue(tg,paramStr,paramValNum);
    end

    function ModVariant(h_self,~,paramStr)
        paramVal = (get(h_self,'String'));
        paramValNum = double(eval(['[' paramVal ']']));
        StopSwitch;
        disp(['Assigning new configuration: ', paramStr, paramVal])
        SetRealTimeValue(tg,paramStr,paramValNum);
        StartSwitch;
    end

    function triggerAvData = displayTiggerAverageSignal(triggerAvData)
        stimData = dataStreamHistory(:,STIM_HAPPENNING);
        indStim = find(stimData,1); %only keep the fist stimulation in package (there might be 2, but it is easier and faster this way)
        newData = dataStreamHistory(max(indStim-beforeStimSamples, 0): end, EEGDataPositions);
        indTimeInAv = max(beforeStimSamples-indStim, 0) : min(length(newData),size(triggerAvData,1));
        triggerAvData(indTimeInAv,:) = triggerAvData(indTimeInAv,:) + newData;
    end

end

