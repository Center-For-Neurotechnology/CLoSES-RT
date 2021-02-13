function NeuroModConsole
global gEnv
if isempty(gEnv)
    gEnv = getEnvironment;
end

h_console = figure('Name','Neural Control Console',...
    'MenuBar','none','NumberTitle','off',...
    'ToolBar','none',...
    'Position',[400   200   835     633],'Color',[1 1 1],'CloseRequestFcn',@CloseConsole);
% initialize spanning variables
h_waiting = text('Position',[0 0],'String','Waiting for xPC...','FontSize',18);
h_compile = uicontrol('Parent',h_console,'Position',[200 100 80 60],'Style','pushbutton','Callback',@UserCompile,'Enable','off','String','Compile Model');
h_go = uicontrol('Parent',h_console,'Position',[100 100 80 60],'Style','pushbutton','Callback',@GoSwitch,'Enable','off','String','Start Block');


axis off;
pause(1);
pnet('closeall')
vizSocket = InitUDPreceiver('127.0.0.1',59124);
targetConnected = false;
blockRunning = false;
userApprovedStart = false;
tg = [];
h_topTrace = [];
h_thresh = [];
h_lockout = [];
h_thirdTrace = [];
h_secondTrace = [];
h_fourthTrace = [];
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
waveTriggerYax = [-200 200];
waveColors = {[.2 .8 .8]
    [.1 .5 .1];
    [.8 .8 .1];
    [.4 .4 .4];
    [.9 .1 .9];    
};
agentTimer = timer('TimerFcn',@CheckAgents,'Period',1,'BusyMode','drop','ExecutionMode','fixedRate');
assignin('base','vizTimer',agentTimer);
start(agentTimer)


    function UpdateViz(~,~,~)
        persistent timeStampPrev
        if isempty(timeStampPrev)
            timeStampPrev = 0;
        end
        if blockRunning
            if ishandle(h_console)
                set(0,'CurrentFigure',(h_console));
            end
            newData = ReceiveUDP(vizSocket,'latest','double');
            if isempty(newData) || numel(newData) < packetDepthSamp*expectedDataWidth
                return
            end

            newData = reshape(newData(1:(packetDepthSamp*expectedDataWidth)),[packetDepthSamp,expectedDataWidth]);
            dataStreamCandidate = [dataStreamHistory((packetDepthSamp+1):end,:); newData];
            timeStamp = dataStreamCandidate(end,1);
            
            % Note 2016.08.15 ANISH AND RINA: This if statement checks
            % whether a given packet is any timesteps later than what we've
            % seen previously. However, if there is no data, this means
            % that the console will simply display nothing. It would be
            % good to at least indicate that some data is arriving but
            % we're ignoring it, because the timestamp comes from the NSP
            % and sometimes we debug with the NSP off.
            if timeStamp > timeStampPrev
                dataStreamHistory = dataStreamCandidate;
            end
%             else
%                 padLen = timeStamp-timeStampPrev;
%                 if timeStampPrev > 0 && padLen > 0
%                     padData = zeros(padLen,size(newData,2));
%                     
%                     for ii = 1:size(newData,2)
%                         padData(:,ii) = linspace(dataStreamHistory(end,ii),newData(1,ii),padLen);
%                     end
%                     padData = [padData; newData];
%                     padLen = padLen + size(newData,1);
%                 elseif padLen == 0
%                     padData = [];
%                     padLen = 0;
%                 else
%                     padData = newData;
%                     padLen = size(newData,1);
%                     
%                 end
%                 if padLen < size(dataStreamHistory,1)
%                 dataStreamHistory = [dataStreamHistory((padLen+1):end,:); padData];
%                 else
%                     dataStreamHistory = nan(size(dataStreamHistory));
%                 end
%             end
            
            % Search for stim events

            isNewStim = find((dataStreamHistory(1:(end-sCoreParams.viz.postTriggerSamp-1),7) < .9) & (dataStreamHistory(2:(end-sCoreParams.viz.postTriggerSamp),7) > .9))+1;
            isRandStim = 0*(isNewStim(dataStreamHistory(isNewStim,5) > .5));
            totalRandStim = totalRandStim + length(isRandStim);
            isNewStim = isNewStim(dataStreamHistory(isNewStim,4) > .5);
            if ~isempty(isNewStim)

                dataStreamHistory(isNewStim,7) = .5;
                
                newStim = zeros(length(sCoreParams.viz.channelInds)*length(isNewStim),waveSpan);
                for stimInd = 1:length(isNewStim)
                    thisStim = isNewStim(stimInd);
                    for chInd = 1:length(sCoreParams.viz.channelInds)
                        uniqueInd = (stimInd-1) * length(isNewStim) + chInd;
                        snipInds = (thisStim-sCoreParams.viz.preTriggerSamp):(thisStim+sCoreParams.viz.postTriggerSamp);
                        newStim(uniqueInd,:) = dataStreamHistory(snipInds,7+chInd);
                    end
                end
                pulseTriggeredWave = [pulseTriggeredWave(size(newStim,1)+1:end,:); newStim];
                totalStim = totalStim + length(isNewStim);
            end

            set(h_topTrace,'YData',dataStreamHistory(:,2));
            set(h_thresh,'YData',dataStreamHistory(:,3));
            lockoutThresh = nan(size(dataStreamHistory(:,3)));
%             lockoutThresh(dataStreamHistory(:,6)> 0.1) = dataStreamHistory(dataStreamHistory(:,7)>0.1,3);
            set(h_lockout,'YData',lockoutThresh);

            set(h_secondTrace,'YData',dataStreamHistory(:,4));
            set(h_thirdTrace,'YData',dataStreamHistory(:,5));
            set(h_fourthTrace,'YData',dataStreamHistory(:,8));
            set(h_realStimTrace,'YData',dataStreamHistory(:,7));
            for waveInd = 1:size(pulseTriggeredWave,1)

                set(h_triggeredWave(waveInd),'YData',pulseTriggeredWave(waveInd,:));
            end
            set(h_titleCount,'String',(sprintf('Total stims: %i %i ',totalStim,totalRandStim)));
            timeStampPrev = timeStamp;
        elseif ~blockRunning && targetConnected
            StartBlock;
            blockRunning = true;
        end
    end

    function CheckAgents(h,~,~)
        
        try
            if gEnv.net.xpc.netBootRunning && ~targetConnected
                % The lack of a semicolon here is necessary!
                % Otherwise, the xpc object doesn't actually re-check.
                tg = xpctarget.xpc('xCoreTarget')
            end
            set(h_waiting,'String',sprintf('Searching for xPC...is it on? %0.f',h.TasksExecuted));
            
            if ~isempty(tg) && strcmpi(tg.Connected,'Yes')
                targetConnected = true;
                set(h_waiting,'String','Target Connected');
                set(h_go,'Enable','on');
                set(h_compile,'Enable','on');
                pause(.001);
                if userApprovedStart
                    set(h_waiting,'String','Initializing...');
                    pause(.001);
                    StartBlock;
                    delete(h_go);
                    delete(h_compile);
                    if ishandle(h_waiting)
                        set(h_waiting,'String','');
                    end
                    pause(.5);
                    stop(h);
                end
                
            else
                if ~gEnv.net.xpc.netBootRunning && exist('xpcnetboot.bat','file');
                    set(h_waiting,'String',sprintf('Setting up boot agent...'));
                    pause(.001);
                    setxpcenv('USBSupport','off');
                    bootpath = which('xpcnetboot.bat');
                    updatexpcenv;
                    system(bootpath);
                    gEnv.net.xpc.netBootRunning = true;
                    tg = [];
                    set(h_waiting,'String',sprintf('Searching for xPC...%0.f',h.TasksExecuted));
                    pause(.001);
                    
                elseif ~exist('xpcnetboot.bat','file')
                    xpcexplr
                    keyboard
                end
            end
            
        catch e
            disp(e.stack(1));
            disp(e.message);
            targetConnected = false;
        end
        
    end
    function StartBlock

        stop(agentTimer)
        sCoreParams = InitCoreParams;
        assignin('base','sCoreParams',sCoreParams);
        tg.load([pwd filesep 'CompileFiles' filesep 'PulseSessionMaster_SL']);
        tunableParams = NameTunableParams;
        for tuneInd = 1:length(tunableParams)
            startVal = GetRealTimeValue(tg,tunableParams{tuneInd});
            underscores = strfind(tunableParams{tuneInd},'_');
            defaultStrLen = underscores(end-1);
            uicontrol('Parent',h_console,'Position',[500 625-(tuneInd*40) 200  30],'BackgroundColor',[1 1 1],'Style','text','String',tunableParams{tuneInd}(defaultStrLen+1:end));
            uicontrol('Parent',h_console,'Position',[700 625-(tuneInd*40) 80  30],'BackgroundColor',[1 1 1],'Style','edit','Callback',{@ModParam,tunableParams{tuneInd}},'String',num2str(startVal));
        end

        tg.start;
        StartWriter;
        % THE ACTUAL DRAWING
        expectedDataWidth = sCoreParams.write.maxSignalsPerStep;
        streamDepthSamp = sCoreParams.viz.streamDepthSec  / sCoreParams.core.stepPeriod;
        packetDepthSamp = sCoreParams.write.broadcastSec / sCoreParams.core.stepPeriod;
        dataStreamHistory = nan(streamDepthSamp,expectedDataWidth);
        waveSpan = sCoreParams.viz.preTriggerSamp + sCoreParams.viz.postTriggerSamp + 1; 
        pulseTriggeredWave = nan(sCoreParams.viz.maxTriggeredEvents * length(sCoreParams.viz.channelInds),waveSpan);
        subplot(421)
        tAx = linspace(0,sCoreParams.viz.streamDepthSec,streamDepthSamp);
        h_topTrace = plot(tAx,dataStreamHistory(:,2),'k','LineWidth',2);
        hold on;
        axis off
        title('Detection Trace')
        h_thresh = plot(tAx,dataStreamHistory(:,3),'Color',[0 0 1],'LineWidth',2);
        lockoutThresh = nan(size(dataStreamHistory(:,3)));
        lockoutThresh(dataStreamHistory(:,6)> 0.1) = dataStreamHistory(dataStreamHistory(:,7)>0.1,3);
        h_lockout = plot(tAx,lockoutThresh,'Color',[.5 .5 .5],'LineWidth',2);
        box off
        hold on;
        subplot(423)
        
        hold on;
        h_secondTrace = plot(tAx,dataStreamHistory(:,4),'g','LineWidth',2);
        h_thirdTrace = plot(tAx,dataStreamHistory(:,5),'m','LineWidth',2);
        box off
        axis([-Inf Inf -.1 1])
        axis off
        title('Triggers')
        subplot(425)
        h_realStimTrace = plot(tAx,dataStreamHistory(:,7),'k','LineWidth',2);
        axis([-Inf Inf -.1 1])
        box off
        axis off
        title('Real Stim')
        subplot(427)
        h_fourthTrace = plot(tAx,dataStreamHistory(:,8),'b','LineWidth',2);
        box off
        axis off
        title('Raw Data')
        subplot(428)
        h_triggeredWave = zeros(1,size(pulseTriggeredWave,1));
        for waveInd = 1:size(pulseTriggeredWave,1)
            chInd = mod(waveInd-1,length(sCoreParams.viz.channelInds))+1;
            hold on;
            h_triggeredWave(waveInd) = plot(pulseTriggeredWave(waveInd,:),'Color',waveColors{chInd});
        end
        axis([-Inf Inf waveTriggerYax(1) waveTriggerYax(2)]);
        h_titleCount = title(sprintf('Total stims: %i',0));
        box off
        axis off;
        % END DRAWING
        vizTimer = timer('TimerFcn',@UpdateViz,'Period',sCoreParams.write.broadcastSec / 5,'BusyMode','drop','ExecutionMode','fixedRate');
        assignin('base','vizTimer',vizTimer);
        blockRunning = true;
        start(vizTimer)
        
    end
    function UserCompile(~,~,~)
        sCoreParams = InitCoreParams;
        CompileModel('PulseSessionMaster_SL',sCoreParams);
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
    function ModParam(h_self,~,paramStr)
        paramVal = (get(h_self,'String'));
        paramValNum = double(eval(['[' paramVal ']']));
        SetRealTimeValue(tg,paramStr,paramValNum);
    end
end

