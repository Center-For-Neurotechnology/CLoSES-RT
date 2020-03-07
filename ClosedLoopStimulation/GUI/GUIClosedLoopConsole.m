function varargout = GUIClosedLoopConsole(varargin)
% GUICLOSEDLOOPCONSOLE MATLAB code for GUIClosedLoopConsole.fig
%      GUICLOSEDLOOPCONSOLE, by itself, creates a new GUICLOSEDLOOPCONSOLE or raises the existing
%      singleton*.
%
%      H = GUICLOSEDLOOPCONSOLE returns the handle to a new GUICLOSEDLOOPCONSOLE or the handle to
%      the existing singleton*.
%
%      GUICLOSEDLOOPCONSOLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUICLOSEDLOOPCONSOLE.M with the given input arguments.
% 
%      GUICLOSEDLOOPCONSOLE('Property','Value',...) creates a new GUICLOSEDLOOPCONSOLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUIClosedLoopConsole_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUIClosedLoopConsole_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% @Rina Zelmann 2016

% Edit the above text to modify the response to help GUIClosedLoopConsole

% Last Modified by GUIDE v2.5 16-Apr-2019 12:59:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GUIClosedLoopConsole_OpeningFcn, ...
    'gui_OutputFcn',  @GUIClosedLoopConsole_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
% global targetConnected;
% global tg;
% global dataStreamHistory;
end

% --- Executes just before GUIClosedLoopConsole is made visible.
    function GUIClosedLoopConsole_OpeningFcn(hObject, eventdata, handles, varargin)
        % This function has no output args, see OutputFcn.
        % hObject    handle to figure
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        % varargin   command line arguments to GUIClosedLoopConsole (see VARARGIN)
      
        %Initialize variables
        if nargin>4 %Check if inputs specified
            for iVarg=1:2:nargin-3 %first 3 are hObject, eventdata, handles
                handles.(varargin{iVarg}) = varargin{iVarg+1};
            end
        end
        if ~isfield(handles,'patientName') && ~isfield(handles,'PatientName')&& ~isfield(handles,'PATIENTNAME') && ~isfield(handles,'pName') && ~isfield(handles,'PName')
            handles.patientName = 'TEST'; %If patient Name is not specified - use: TEST!
        end    
        if isfield(handles,'PatientName'),handles.patientName = handles.PatientName; end
        if isfield(handles,'PATIENTNAME'),handles.patientName = handles.PATIENTNAME; end
        if isfield(handles,'pName'),handles.patientName = handles.pName; end
        if isfield(handles,'PName'),handles.patientName = handles.PName; end
        
        if ~isfield(handles,'dirBase')
            handles.dirBase = pwd; %Compiled program to send should be dirBase/CompileFiles/ClosedLoopStimXpcTarget or selected on initGUI
        end
        if ~isfield(handles,'sCoreParamConfigFileName')
            handles.sCoreParamConfigFileName = '';  %if not specified - used default sCoreParams for this experiemnt type
        end
        if ~isfield(handles,'dirResults') && ~isfield(handles,'DirResults')&& ~isfield(handles,'DIRRESULTS')
            handles.dirResults = ['C:\Temp']; %handles.dirBase; %RIZ: Could be specified as input
        end
        if isfield(handles,'DIRRESULTS'),handles.dirResults = handles.DIRRESULTS; end
        if isfield(handles,'DirResults'),handles.dirResults = handles.DirResults; end
        if ~exist(handles.dirResults,'dir')
            mkdir(handles.dirResults);
        end
        
        % Temporal File to save data (using ReceiveWrite Model)
        handles.fileNameTemporalInfo = ['saveData.mat'];%MUST correspond to ReceiveWrite Model!!! - HARDCODED to working directory FOR NOW!

        % Global Variables initialization
        global sCoreParams;
        global targetConnected;
        global tg;
        global dataStreamHistory;
        global dataAllDetStim;
        global dataTrialByTrialHistory;
        global dataAveragedEEGHistory;
        
        sCoreParams = [];
        targetConnected = false;
        tg = [];
        dataStreamHistory=[];
        dataAllDetStim=[];
        dataTrialByTrialHistory=[];
        dataAveragedEEGHistory=[];
  %      handles.blockRunning = false;
        %userApprovedStart = false;
        guidata(hObject, handles);

        %For threshold, filteredData and unfiteredEEGData the position is
        %determined in real time to account for multiple channels
        % IF UDP packages sent are changed in OutputToVisualization.slx -> modify numbers here

        %local variables -         
        %Default Model Names:
        defaultSimulationModel = [handles.dirBase filesep 'ClosedLoopStimulation' filesep 'ClosedLoopStim_SimulatedInput'];
        defaultClosedLoopModel = [handles.dirBase filesep 'CompileFiles' filesep 'ClosedLoopStimXpcTarget'];
        defaultNHPModel = [handles.dirBase filesep 'CompileFiles' filesep 'ClosedLoopStimPlexon']; %Since it runs in host computer is the same as simulation (no need for compiled model)!
        
        %Initialize diary (to save command line as log)
        diary([handles.dirResults, filesep, 'log_',handles.patientName,'_',datestr(now,'yymmdd_HHMM'),'.log'])

        
        %Run configuration figure first to select MODE
        [mode, modelFileName, experimentType, configFileName, simulationFileName] = InitDialogfig(hObject); % mode could be: Stimulation or Closed-Loop
        if isempty(mode) || (strcmpi(mode,'No')) % This is returned if option window was closed!
            delete(hObject); 
            %delete(handles.figure1);
            return;
        end
        handles.mode = mode;
        handles.experimentType = experimentType;
        handles.sCoreParamConfigFileName = configFileName;
        handles.simulation.simulationFileName = simulationFileName;
        guidata(hObject, handles);
        
        disp(['Options from InitConfig:'])
        disp(['Mode: ',mode,' -  Experiment Type: ',experimentType])
        disp([' - Simulink Model FileName: ',modelFileName])
        disp([' - Config FileName: ',configFileName])
        disp([' - Simulation FileName: ',simulationFileName])

        % UIWAIT makes GUIClosedLoopConsole wait for user response (see UIRESUME)
        %uiwait(handles.figure1);
        
        %Initialize Variables and Variants 
        initializeVariables(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified
        
        %Initialize UDPCommunication
        InitializeNetwork(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

        %Add a menu to the GUI
        set(hObject,'toolbar','figure');
             
        %Pre-Configure GUI based on experiment type
        configureGUIBasedOnExperimentType(hObject, eventdata, handles, experimentType);
        handles = guidata(hObject); %Get the handles back after they were modified

        % Patient Specific Configuration - It is at the end of all the configuration to avoid being overwriten by a default value
        if ~isempty(handles.sCoreParamConfigFileName )
            patientSpecificConfiguration(hObject, eventdata, handles)
            handles = guidata(hObject); %Get the handles back after they were modified
        end
        
        % Choose default command line output for GUIClosedLoopConsole
        handles.output = hObject;
       
        %Chose execution mode
        handles.modelFileName = modelFileName;
        guidata(hObject, handles);         % Update handles structure
        switch mode
            case 'Simulation'
                if isempty(handles.modelFileName)
                    handles.modelFileName = defaultSimulationModel;
                end
                [~, name] = fileparts(handles.modelFileName);
                handles.modelName = name;
                guidata(hObject, handles);
                InitialSimulation(hObject, handles);
            case 'Closed-Loop'
                if isempty(handles.modelFileName)
                    hWarnDlg = warndlg({'Are you sure you want to run with default SIMULINK model?'},' Missing Simulink Model File!');
                    uiwait(hWarnDlg);
                    handles.modelFileName = defaultClosedLoopModel;
                end
                [~, name] = fileparts(handles.modelFileName);
                handles.modelName = name;
                guidata(hObject, handles);
               % slrtexplr %RIZ20161109: BAD HACK!!! To work on RIG
                InitialClosedLoop(hObject, handles);
            case 'NHP'
                if isempty(handles.modelFileName)
                    handles.modelFileName = defaultNHPModel;
                end
                [~, name] = fileparts(handles.modelFileName);
                handles.modelName = name;
                guidata(hObject, handles);
                % For Real-Time (Decider) NHP
             %   slrtexplr %RIZ20161109: BAD HACK!!! To work on RIG
                InitialClosedLoop(hObject, handles);
                % For Simulated (or USB6009) NHP
                %InitialNHPModelSimulation(hObject, handles);                 
            case 'No'
                disp('Closing Console');
                delete(handles.figure1);
            otherwise
                disp('Closing Console');
                delete(handles.figure1);                
        end 
    end
% --- Outputs from this function are returned to the command line.
    function varargout = GUIClosedLoopConsole_OutputFcn(hObject, eventdata, handles)
        % varargout  cell array for returning output args (see VARARGOUT);
        % hObject    handle to figure
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        
        % Get default command line output from handles structure
        if isfield(handles,'output')
            varargout{1} = handles.output;
        end
    end
    
% --- Depending on experiment type, pre set objects and parameters    
    function configureGUIBasedOnExperimentType(hObject, eventdata, handles, experimentType)
        global sCoreParams;
            switch upper(experimentType)
                case 'MSIT'
                    % Default Config is HighGamma + SmoothBandPower
                    set(handles.popFreq,'Value',5);     % HighGamma
                    set(handles.popFeature,'Value',1);  % SmoothBandPower
                    set(handles.popStimulationType,'Value',2);  % NEXT TRIAL Stimulation (as soon as it detects)
                    set(handles.popDetectorType,'Value',2);     % ONLY detect during trial (baed on image onset)
                    set(handles.popMontage,'Value',2);          % Bipolar
                    sCoreParams.stimulationFrequencyHz = 130;
                    sCoreParams.stimulator.trainDuration = 600;
                    sCoreParams.stimulator.amplitude_mA = 2000;
                    handles.controlCerestimFromHost = false;
                case 'ECR'
                    % Default Config is Theta + Coherence
                    set(handles.popFreq,'Value',1);     % Theta
                    set(handles.popFeature,'Value',3);  % Coherence
                    set(handles.popStimulationType,'Value',2);  % NEXT TRIAL Stimulation (if stim should happen in one trial -> send STIM at trigger of next trial)
                    set(handles.popDetectorType,'Value',2);     % ONLY detect during trial (baed on image onset)
                    set(handles.popMontage,'Value',2);          % Bipolar
                    sCoreParams.stimulationFrequencyHz = 160;
                    sCoreParams.stimulator.trainDuration = 400;
                    sCoreParams.stimulator.amplitude_mA = 4000;
                    handles.controlCerestimFromHost = true;     %Multisite Stim needs that the Cerestim be controlled from host computer
                case 'CONTINUOUS'
                    % Default Config is Ripple + SmoothBandPower
                    set(handles.popFreq,'Value',10);     % Spindle
                    set(handles.popFeature,'Value',1);  % SmoothBandPower
                    set(handles.popDetectorType,'Value',1);     % Real-Time Stimulation
                    set(handles.popTriggerType,'Value',2);      % Periodic trigger
                    set(handles.popMontage,'Value',1);          % Referential
                    sCoreParams.stimulationFrequencyHz = 60; %RIZ: SINGLE PULSE Stimulation -> write as 60Hz to have a second notch at 60 - RIZ: it DOES not make sense!!
                    sCoreParams.stimulator.trainDuration = 60;  %As long as frequency and duratio are the same, it generates a SINGLE PULSE
                    sCoreParams.stimulator.amplitude_mA = 6000;
                    handles.controlCerestimFromHost = false; %For NOW only 1 channel stim! -> change afterwards
                otherwise
                    disp('Error in experiment Type - please configure in GUI');
            end
%         if (patientSpecificConfig == true) % use default for experiment
%             possibleFreqLow = [4,8,15,30,65,140,65200,80,30110,1216,0]; %Poor HACK!!
%             possibleFeaturesInPopMenu = [3,4,5,2]; %Poor HACK!! Corresponds to: SmoothBandPower=3, VarianceOfPower=4, Coherence=5, IED=2
%             possibleDetectorsInPopMenu = [1,3;4,5;6,7;2,2]; %Poor HACK!! Corresponds to: CONTINUOUS: WHICH_DETECTOR={1,3} / TRIGGER: WHICH_DETECTOR={4,5} / MULTISITE: WHICH_DETECTOR={6,7} / IED: WHICH_DETECTOR=2
%             possibleStimTypeInPopMenu = [1,3;2,4]; %Poor HACK!! Corresponds to: CONTINUOUS: WHICH_DETECTOR={1,3} / TRIGGER: WHICH_DETECTOR={4,5} / MULTISITE: WHICH_DETECTOR={6,7}
%             set(handles.popFreq,'Value',find(possibleFreqLow==handles.variant.variantConfig.FREQ_LOW));
%             set(handles.popFeature,'Value',find(possibleFeaturesInPopMenu==handles.variant.variantConfig.WHICH_FEATURE));
%             [row, col] = find(possibleStimTypeInPopMenu==handles.variant.variantConfig.STIMULATION_TYPE);
%             set(handles.popStimulationType,'Value', row(1));
%             [row, col] = find(possibleDetectorsInPopMenu == handles.variant.variantConfig.WHICH_DETECTOR);
%             set(handles.popDetectorType,'Value', row(1));
%             set(handles.popTriggerType,'Value',handles.variant.variantConfig.TRIGGER_TYPE);
%             set(handles.popMontage,'Value',handles.variant.variantConfig.IS_BIPOLAR+1); %IS BIPOLAR IS 0 or 1, add one to move it to 1 based
%         end
        
        %Call the pop objects callbacks to update the variants
        popFreq_Callback(handles.popFreq, eventdata, handles);
        handles = guidata(handles.popFreq); %Get the handles back after they were modified
        popFeature_Callback(handles.popFeature, eventdata, handles);
        handles = guidata(handles.popFeature); %Get the handles back after they were modified
        popDetectorType_Callback(handles.popDetectorType, eventdata, handles);
        handles = guidata(handles.popDetectorType); %Get the handles back after they were modified
        popStimulationType_Callback(handles.popStimulationType, eventdata, handles);
        handles = guidata(handles.popStimulationType); %Get the handles back after they were modified
        popTriggerType_Callback(handles.popTriggerType, eventdata, handles);
        handles = guidata(handles.popTriggerType); %Get the handles back after they were modified
        popMontage_Callback(handles.popMontage, eventdata, handles);
        handles = guidata(handles.popMontage); %Get the handles back after they were modified
        guidata(hObject, handles);
    end
    

% Send configuration parameters and variants to BASE WORKSPACE before RUNNING
    function configureModelParams(hObject, handles)
        %Assign changes variables to workspace - then restart model
        global tg;
        global sCoreParams;
        if (handles.paramChanged == true)
            sCoreParams = InitCoreParams_Dependent(sCoreParams);
            FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);
            assignin('base','sCoreParams',sCoreParams);
        end
        % Configure Variants based on Freq & Feature selections - Requires re-starting model!
        if (handles.variantChanged == true)
            [variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
            FlattenAndTune(handles.variant.variantConfig,'variantConfig',variantConfigFlatNames);
        end
        if strcmpi(handles.mode,'Closed-Loop') || strcmpi(handles.mode,'NHP')
            if (handles.variantChanged == true || handles.needsToReCompile == true)
                % Needs to Compile model - VARIANTS cannot be changed directly ALWAYS NEED TORECOMPILE (RIZ: not sure why!!)
                set(handles.txtStatus,'String',sprintf('Compiling model...  please wait'));
                compileModelToUpdateVariants(handles.modelFileName, pwd, sCoreParams, handles.variant.variantConfig);
                set(handles.txtStatus,'String',sprintf('Compilation Done!'));
            elseif (handles.paramChanged == true)
                % Update tunable parameters
                tg.load(handles.modelFileName); % Not sure if necessary, but just in case!
                updateTargetParams(hObject, handles);
            else
                tg.load(handles.modelFileName); % Not sure if necessary, but just in case!
            end
        end
        handles.paramChanged = false;
        handles.variantChanged = false;
        handles.needsToReCompile = false;
        guidata(hObject, handles);
    end
    

    function txtTriggerChannel_Callback(hObject, eventdata, handles)
        % hObject    handle to txtTriggerChannel (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        
        % Hints: get(hObject,'String') returns contents of txtTriggerChannel as text
        %        str2double(get(hObject,'String')) returns contents of txtTriggerChannel as a double
        global sCoreParams;
        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
        paramStr = get(hObject,'UserData');
        sCoreParams.decoders.txDetector.triggerChannel = paramValue;
        handles.paramChanged = true;
        guidata(hObject, handles);

    end

% --- Executes during object creation, after setting all properties.
    function txtTriggerChannel_CreateFcn(hObject, eventdata, handles)
        % hObject    handle to txtTriggerChannel (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    empty - handles not created until after all CreateFcns called
        
        % Hint: edit controls usually have a white background on Windows.
        %       See ISPC and COMPUTER.
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end
    end

% --- Executes on button press in btnStart.
    function btnStart_Callback(hObject, eventdata, handles)
        global stimInfo;
        global dataAllDetStim;
        
        handles.paramChanged = true;
        %Assign changed variables to workspace
        hObjectGUI = hObject.Parent;
        configureModelParams(hObjectGUI, handles);
        handles = guidata(hObjectGUI);
        
        %Initialize Plots and lists
        initializePlots(hObjectGUI, handles);
        handles = guidata(hObjectGUI);
        initializeWithControlValues(hObjectGUI, handles)
        handles = guidata(hObjectGUI);
        
        %add time information
        handles.startTime = datestr(now,'HH:MM:SS');
        guidata(hObjectGUI, handles);

        %Initialize dataTrials and stimInfo to only save this experiment
        dataAllDetStim = [];
        stimInfo = [];
        
        %Initialize UDPCommunication
        InitializeNetwork(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

        % Disable This START button until STOP is pressed (to ensure only it is run only once)
        set(hObject,'Enable','off');
        % Disable also the COMPILE button until STOP is pressed (to ensure  it not run while running system)
        set(handles.btnCompile,'Enable','off');
        % Disable also controls that cannot be changed in real-time
        set(handles.chkFixThreshold,'Enable','off');
        set(handles.txtInitialThreshold,'Enable','off');
        set(handles.txtPrevThWeight,'Enable','off');
        set(handles.txtStimulationTriggerChannel,'Enable','off');
        set(handles.txtSmoothDuration,'Enable','off');
        set(handles.txtStimAfterDelay,'Enable','off');
        set(handles.txtDetectionSign,'Enable','off');
        set(handles.txtStimAfterDelay,'Enable','off');
        set(handles.txtBeforeStimSec,'Enable','off');

        
        
        %updateDetVizChannelsList(hObject, handles);
        if strcmpi(handles.mode,'Closed-Loop') || strcmpi(handles.mode,'NHP')
            disp('Starting Closed-Loop Stimulation Control!')
            %StartClosedLoop(hObject, handles);
            StartAquisitionBlock(hObjectGUI, handles);
        elseif strcmpi(handles.mode,'Simulation')
            disp('Starting Simulation mode')
            %StartSimulation(hObject, handles);
            RunSimulation(hObjectGUI, handles);
        else
            disp(['Warning wrong mode: ', handles.mode,' - it must be Closed-Loop or Simulation'])
        end
    end

% --- Executes on button press in btnStop.
    function btnStop_Callback(hObject, eventdata, handles)
        %Just in case STOP everything - eventhough it would actually be the
        %target PC or simulation
        global tg;
        tic
        evalin('base','StopWriter()');
        
        %Save experimental Data
        disp('Saving Closed-Loop Stimulation HOST Files!')
        SessionDataConfig = saveExperimentData(hObject, handles);
        
        % Stop visualization 
        if isfield(handles,'vizTimer')
            stop(handles.vizTimer);
        end
        
        % Stop Simulink
        % Stop Simulink
        if strcmpi(handles.mode,'Simulation') 
            disp('Stoping Closed-Loop Stimulation Control - Simulation!')
            try
                set_param(handles.modelName,'simulationcommand','stop');
            catch
                disp('Error Closing Model!')
            end
            saveSimulationFilesInHost(hObject, handles, SessionDataConfig);

 %       elseif strcmpi(handles.mode,'NHP') 
 %           disp('Stoping Closed-Loop Stimulation Control - NHP Plexon!')
 %           set_param(handles.modelName,'simulationcommand','stop');
          %  stopPlexonServer(handles.plexon);
        else %Assumes that it is running on decider (human or NHP)
            disp('Stoping Closed-Loop Stimulation Control!')
            if strcmpi(get(tg,'Status'), 'running')
                tg.stop;
            end
            if isfield(handles,'cerestim') && ~isempty(handles.cerestim)
                disconnectCereStim(handles.cerestim);
            end
            % Move files from Target computer to HOST
            disp('Saving Closed-Loop Stimulation TARGET Files!')
            saveTargetFilesInHost(hObject, handles);
            disp('Saving Performance Information!')
            saveTargetPerformanceInfo(hObject, handles, SessionDataConfig);
        end
        
        %assignin('base','streamDataHeaders',handles.plotInfo);
        %assignin('base','resultsDir',handles.dirResults);
        set(handles.txtStatus,'String','');
        set(handles.btnStart,'Enable','on'); % Enable START button again
        set(handles.btnCompile,'Enable','on'); % Enable also Compile button again
        % Enable back  controls that cannot be changed in real-time
        set(handles.chkFixThreshold,'Enable','on');
        set(handles.txtInitialThreshold,'Enable','on');
        set(handles.txtPrevThWeight,'Enable','on');
        set(handles.txtStimulationTriggerChannel,'Enable','on');
        set(handles.txtSmoothDuration,'Enable','on');
        set(handles.txtStimAfterDelay,'Enable','on');
        set(handles.txtDetectionSign,'Enable','on');
        set(handles.txtBeforeStimSec,'Enable','on');

        toc
    end

    function SessionDataConfig = saveExperimentData(hObject, handles)
       % SessionData.header = {'NSP Time','Detector Channel','Threshold','Event-Trigger',...
       %     'Rand Trigger','Raw Data','Threshold Is Updating','Real Stim'};
       global dataAllDetStim;
       global sCoreParams;
       global stimInfo;
       
       SessionDataConfig = [];
       fileNameSessionData = [handles.dirResults, filesep, 'DeciderData_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.mat'];
       fileNameSessionDetStimData = [handles.dirResults, filesep, 'DeciderDetStimData_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.mat'];
       if exist(handles.fileNameTemporalInfo, 'file') && ~exist(fileNameSessionData, 'file')
           set(handles.txtStatus,'String','Saving Data... Please wait');
           %           stData = load(handles.fileNameTemporalInfo); %Load temporal data
           %           SessionData.streamData = stData.savedData; %stData.ans;  %
           SessionDataConfig.patientName = handles.patientName;
           SessionDataConfig.experimentType = handles.experimentType;
           SessionDataConfig.sCoreParams = sCoreParams;
           SessionDataConfig.savedDataHeaders = handles.plotInfo;
           SessionDataConfig.feature = handles.feature;
           SessionDataConfig.freqBandName = handles.freqBandName;
           SessionDataConfig.detectorType = handles.detectorType;
           SessionDataConfig.selMontage = handles.selMontage;
           SessionDataConfig.variants = handles.variant;
           SessionDataConfig.mode = handles.mode;
           SessionDataConfig.modelFileName = handles.modelFileName;
           SessionDataConfig.startTime = handles.startTime;
           SessionDataConfig.endTime = datestr(now,'HH:MM:SS');
           SessionDataConfig.date = datestr(now,'yyyymmdd');
           SessionDataConfig.files.modelFileName = handles.modelFileName;
           SessionDataConfig.files.sCoreParamConfigFileName = handles.sCoreParamConfigFileName;
           SessionDataConfig.files.simulationFileName = handles.simulation.simulationFileName;
           SessionDataConfig.simulationInfo = handles.simulation;
           SessionDataConfig.channelNames = sCoreParams.decoders.txDetector.channelNames;
           SessionDataConfig.channelInfo = handles.channelInfo;
           SessionDataConfig.bipolarChannelNames = sCoreParams.decoders.txDetector.bipolarChannelNames;
           stimulationDataFromContinuous = stimInfo;
           detectionStimData = dataAllDetStim;

           save(fileNameSessionDetStimData,'SessionDataConfig','detectionStimData','stimulationDataFromContinuous'); % Save detection and stim data first (it is way smaller)
           copyfile(handles.fileNameTemporalInfo,fileNameSessionData,'f'); % copy instead of move to keep temporary file as backup
           save(fileNameSessionData,'SessionDataConfig','stimulationDataFromContinuous','detectionStimData','-append');
           set(handles.txtStatus,'String','Saving Data... Done!');
           disp(['Data Saved to ',fileNameSessionData,' - Do not forget to get it!']);
           guidata(hObject, handles);
       else
           disp(['Could not find ',handles.fileNameTemporalInfo,' savedData file! if you already hit STOP it was saved then.']);
       end
    end
 
    function saveTargetFilesInHost(hObject, handles)
    %Gets info from target computer and saves them on host
        global tg;
        global sCoreParams;

        currentDir = pwd;
     %   fileNameSessionDataFeat = [handles.dirResults, filesep, 'DeciderTARGETData_Feat_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.dat'];
        fileNameSessionDataEEG = [handles.dirResults, filesep, 'DeciderTARGETData_EEG-', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.dat'];
        fileNameSessionDataStim = [handles.dirResults, filesep, 'DeciderTARGETData_Stim_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.dat'];

        try
            cd(handles.dirResults)
            % Get files from TARGET computer
     %       SimulinkRealTime.copyFileToHost(tg, sCoreParams.target.filenames.featTh);
            SimulinkRealTime.copyFileToHost(tg, sCoreParams.target.filenames.eeg);
            SimulinkRealTime.copyFileToHost(tg, sCoreParams.target.filenames.stimInfo);
            % change name to keep all files
     %       copyfile(sCoreParams.target.filenames.featTh,fileNameSessionDataFeat,'f')
            copyfile(sCoreParams.target.filenames.eeg,fileNameSessionDataEEG,'f')
            copyfile(sCoreParams.target.filenames.stimInfo,fileNameSessionDataStim,'f')

            cd(currentDir);
        catch
            warning('Problem Transfering data from TARGET. Remember to copy it after!');
            cd(currentDir);
        end
        %To read them
        % idFeatFile=fopen('FEAT_001.dat')
        % dataFeatTh = fread(idFeatFile);
        % fclose(idFeatFile);
        % x=SimulinkRealTime.utils.getFileScopeData(dataFeatTh);
    
    end
    
    function saveTargetPerformanceInfo(hObject, handles, SessionDataConfig)
    
        global tg;
        fileNamePerformance = [handles.dirResults, filesep, 'DeciderPerformance_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.mat'];
        
        %consoleLog = SimulinkRealTime.utils.getConsoleLog(tg,1);
        
        infoPerformance.TETLog = tg.TETLog;
        infoPerformance.MinTET = tg.MinTET;
        infoPerformance.MaxTET = tg.MaxTET;
        infoPerformance.CPUoverload = tg.CPUoverload;
        infoPerformance.SessionTime =  tg.SessionTime;
        infoPerformance.ExecTime = tg.ExecTime;
        infoPerformance.SampleTime=tg.SampleTime;

        %infoPerformance.consoleLog = consoleLog;        
         save(fileNamePerformance,'SessionDataConfig','infoPerformance')    
    end
    
    
    function saveSimulationFilesInHost(hObject, handles, SessionDataConfig)
    %Gets info from target computer and saves them on host
%         fileNameFeaturesFromModel = [handles.dirResults, filesep, 'SimulationData_Feat_', handles.experimentType,'_',handles.patientName,'_', datestr(now,'yymmdd_HHMM'),'.mat'];
%         try
%             % Get files from TARGET computer
%             copyfile('saveFeaturesFromModel.mat',fileNameFeaturesFromModel,'f');
%             save(fileNameFeaturesFromModel,'SessionDataConfig','-append');
%         catch
%             warning('Problem Saving data from Simulation File. Remember to copy it after!');
%         end
    end
    
    
    function InitialSimulation(hObject, handles)
        %global targetConnected;
        global sCoreParams;
        %Generate Random data or load from file
        %[sCoreParams, sInputData, sInputTrigger] = initializationScript('SIMULATION', sCoreParams, handles.freqBandName, handles.feature,  handles.stimulationType,  handles.detectorType, contactNumbers1, contactNumbers2, detectChannelInds, triggerChannel, whatTypeSimulation, realDataFileName);

        if isfield(handles,'simulation') && ~isempty(handles.simulation.simulationFileName)
            if ~isempty(strfind(handles.simulation.simulationFileName,'PREPROCESSED'))
                handles.simulation.typeSimulation = 'PREPROCESSED'; % if 'PREPROCESSED' is in the name is a preprocessed file from ft(bipolar)
            else
                handles.simulation.typeSimulation = 'REAL';     % otherwise is a referential raw EEG data 
            end
        else
            handles.simulation.simulationFileName =[];  %in case it didn't exist
            handles.simulation.typeSimulation = 'SINE'; %if file is not specified assume sine+rand
        end
       %[sCoreParams, variantConfig, sInputData, sInputTrigger, sRandomStimulation] = initializationScript(whatToDo, sCoreParams, freqBandName, featureName, stimulationType, detectorType, triggerType, contactNumbers1, contactNumbers2, triggerChannel, whatTypeSimulation, realDataFileName)
 %       [sCoreParams, variantConfig, sInputData, sInputTrigger] = initializationScript('SIMULATION', sCoreParams, handles.freqBandName, handles.feature, handles.stimulationType, handles.detectorType, handles.triggerType, [],[],[], handles.simulation.typeSimulation, handles.simulation.simulationFileName, handles.variant.variantConfig);
        [sCoreParams, variantConfig,  sInputDataOdd, sInputTriggerOdd, sInputDataEven, sInputTriggerEven] = initializationScript('SIMULATION', sCoreParams, handles.freqBandName, handles.feature, handles.stimulationType, handles.detectorType, handles.triggerType, handles.selMontage, [],[],[], handles.simulation.typeSimulation, handles.simulation.simulationFileName, handles.variant.variantConfig);
        %[sCoreParams, variantParams, variantConfig, variantConfigFlatNames, sInputData, sInputTrigger] = InitializeSimulation('SIMULATION');
        handles.sCoreParams = sCoreParams;
        handles.variant.variantConfig = variantConfig;
       % handles.sInputData = sInputData;
       % handles.sInputTrigger = sInputTrigger;
        guidata(hObject, handles);
        initializeParameters(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

        %assignin('base','sCoreParams',sCoreParams);
        %assignin('base','variantParams',variantParams);
        %assignin('base','variantConfig',variantConfig);
        %assignin('base','sInputData',sInputData);
        %assignin('base','sInputTrigger',sInputTrigger);
        
        %Load system - This is done every time we start the simulation to allow modification of fix length parameters 
        load_system(handles.modelName);
         % Update handles structure
        guidata(hObject, handles);
        
        % Get Default values and update GUI objects
        updateGUIObjectsFromCurrent(hObject, handles);

        %Initialize plots with empty dataStreamHistory
        %Initialize Plots and lists
        updateDetVizChannelsList(hObject, handles);
        handles = guidata(hObject);
        initializePlots(hObject, handles);
        handles = guidata(hObject);
        initializeWithControlValues(hObject, handles)
        handles = guidata(hObject);
       %handles = guidata(handles.popFeature); %Get the handles back after they were modified
        %targetConnected = true;

    end
    
    function InitialNHPModelSimulation(hObject, handles)
        global sCoreParams;
        %Initilize parameters and variants
        [sCoreParams, variantConfig] = initializationScript('NHP', sCoreParams, handles.freqBandName, handles.feature, handles.stimulationType,  handles.detectorType, handles.triggerType, handles.selMontage,[],[],[],[], handles.variant.variantConfig);
        %[sCoreParams, variantConfig, sInputData, sInputTrigger] = initializationScript('SIMULATION', sCoreParams, handles.freqBandName, handles.feature,  handles.stimulationType,  handles.detectorType, handles.triggerType, handles.selMontage, contactNumbers1, contactNumbers2, detectChannelInds, triggerChannel);
        handles.sCoreParams = sCoreParams;
        handles.variant.variantConfig = variantConfig;
        guidata(hObject, handles);
        
        % Initiliaze Parameters
        initializeParameters(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

        %Load system - This is done every time we start the simulation to allow modification of fix length parameters
        load_system(handles.modelName);
        % Update handles structure
        guidata(hObject, handles);

        % Get Default values and update GUI objects
        updateGUIObjectsFromCurrent(hObject, handles);

        %Initialize plots with empty dataStreamHistory
        updateDetVizChannelsList(hObject, handles);
        handles = guidata(hObject);
        initializePlots(hObject, handles);  %Initialize Plots and lists
        handles = guidata(hObject);
        initializeWithControlValues(hObject, handles)
        handles = guidata(hObject);
   end
    
    function InitialNHPModelRealTime(hObject, handles)
        global sCoreParams;
        [sCoreParams, variantParams, variantConfig, variantConfigFlatNames] = InitializeNHPPlexon( sCoreParams);
        handles.sCoreParams = sCoreParams;
        handles.variant.variantConfig = variantConfig;
        guidata(hObject, handles);
    end
    
    function RunSimulation(hObject, handles)
        %Load simulation model
        disp('Running simulation')

 %       simMode = get_param(modelName, 'SimulationMode');
        %Start Simulation
%        handles.simModel = sim(handles.modelFileName, 'StopTime', '1000', 'ZeroCross','on', 'SaveTime','on','TimeSaveName','tout', ...
%            'SaveOutput','on','OutputSaveName','youtNew',...
%            'SignalLogging','on','SignalLoggingName','logsout');

        load_system(handles.modelName);
        set_param(handles.modelName,'simulationcommand','start');
        assignin('base','guiParamsTempFilename',handles.fileNameTemporalInfo);
        evalin('base','StartWriter');

        %Start Visualization
        set(handles.txtStatus,'String','Running Simulation');
        disp('Starting Visualization Update');
        guidata(hObject, handles);
        StartVisualizationBlock(hObject, handles);
       % save(simOut)
    end

    function InitialClosedLoop(hObject, handles)
        agentTimer = timer('TimerFcn',{@CheckAgentsSRT, hObject, handles} ,'Period',1,'BusyMode','drop','ExecutionMode','fixedRate');
        assignin('base','agentTimer',agentTimer);
        handles.agentTimer = agentTimer;
        guidata(hObject, handles);
        agentTimer.TimerFcn = {@CheckAgentsSRT, hObject, handles}; %Reassign to have itself in the handles - RIZ:There is probably a cleaner way!
        start(agentTimer)
    end

%% Function that actualy do something (based on Anish's NeuroModConsole)
    function CheckAgentsSRT(h,~, hObject, handles)
        %Similar to CheckAgents but modified for simulink real time
        global targetConnected;
        global tg;

        try
            if ~targetConnected
                % The lack of a semicolon here is necessary!
                % Otherwise, the xpc object doesn't actually re-check.
                %tg = xpctarget.xpc('xCoreTarget')  %RIZ: check if name is correct or changed in SRT
                tg =  SimulinkRealTime.target('xCoreTarget')
            end
            set(handles.txtStatus,'String',sprintf('Searching for xPC...is it on? %0.f',h.TasksExecuted));
            
            if ~isempty(tg) && strcmpi(tg.Connected,'Yes')
                targetConnected = true;
                set(handles.txtStatus,'String','Target Connected');
                disp('Target Connected - Starting Closed-Loop');
                pause(.001);
                set(handles.txtStatus,'String','Initializing...');
                pause(.001);
                InitialAquisitionBlock(hObject, handles); %STARTS acquisition block!
                handles = guidata(hObject); %Get the handles back after they were modified
                if ishandle(handles.txtStatus)
                    set(handles.txtStatus,'String','');
                end
                pause(.5);
                stop(h);
            else
               set(handles.txtStatus,'String',sprintf('xPC target not found...is it on? If not boot and restart! '));
            end
            % Update handles structure
            guidata(hObject, handles);
            
        catch e
            disp(e.stack(1));
            disp(e.message);
            targetConnected = false;
        end
        
 end

    function InitialAquisitionBlock(hObject, handles)
        global tg;
        global sCoreParams;

        % Perhaphs this step is not necessary... but it won't hurt to have it and is exactly like simulation
        [sCoreParams, variantConfig] = initializationScript('REAL-TIME', sCoreParams, handles.freqBandName, handles.feature, handles.stimulationType, handles.detectorType, handles.triggerType, handles.selMontage, [],[],[], [], [], handles.variant.variantConfig);
        
        handles.variant.variantConfig = variantConfig;
        handles.sCoreParams = sCoreParams;
        guidata(hObject, handles);

        initializeParameters(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

        %Stop timer that checks targe computer
        stop(handles.agentTimer)
        
        %Compile (at Button Start) since for sure there is change of config since last time
        % BEfore: Compile (at Button Start) since for sure there is change of config since last time
        handles.needsToReCompile = true; % RIZ: change to false for DEMO? probably NOT enough

        % set(handles.txtStatus,'String',sprintf('Compiling model...please wait'));
       % compileModelToUpdateVariants(handles.modelFileName, pwd, handles.sCoreParams, handles.variant.variantConfig);

        %Initialize Cerestim
        if handles.controlCerestimFromHost == true
            [cerestim, res] = initializeCereStim(sCoreParams.stimulationFrequencyHz, sCoreParams.stimulator.trainDuration, sCoreParams.stimulator.amplitude_mA);
            handles.cerestim = cerestim;
            guidata(hObject, handles);
        end
        
        % Load model to TARGET pc 
        tg.load(handles.modelFileName);
       % updateTargetParams(hObject, handles); % added RIZ 20170515 - it should update parameters on decider that are then read  - a bit circular, probably I should fine a better solution!

        % Get Default values and update GUI objects
        updateGUIObjectsFromCurrent(hObject, handles);
        handles = guidata(hObject); %Get the handles back after they were modified

        %StartAquisitionBlock(hObject, handles);
        %Initialize plots with empty dataStreamHistory
        %global dataStreamHistory;
        %dataStreamHistory = nan( handles.params.streamDepthSamp,  handles.sCoreParams.write.maxSignalsPerStep); % dataStreamHistory is the data coming from UDP - here we only specify the size
        %Initialize Plots
        updateDetVizChannelsList(hObject, handles);
        handles = guidata(hObject);
        initializePlots(hObject, handles);
        handles = guidata(hObject);
        initializeWithControlValues(hObject, handles)
        handles = guidata(hObject);  
    end
    
    function StartAquisitionBlock(hObject, handles)
        global sCoreParams;
        global tg;
        %tg.close; 
        tg.stop; % In case it was still running
        tg.set('CommunicationTimeOut', 50);

        %evalin('base','StopWriter'); 
        %Assign changed variables to workspace
        %Starts the model and the data writer
       % tg.load(handles.modelFileName);
        tg.start;
        %StartWriter;
        assignin('base','guiParamsTempFilename',handles.fileNameTemporalInfo);
        evalin('base','StartWriter');
        % If cerestim was not initialized -> start it NOW
        if handles.controlCerestimFromHost == true % Always connect again (we disconnect on STOP)&& (~isfield(handles,'cerestim') || isempty(handles.cerestim))
            [cerestim, res] = initializeCereStim(sCoreParams.stimulationFrequencyHz, sCoreParams.stimulator.trainDuration, sCoreParams.stimulator.amplitude_mA);
            handles.cerestim = cerestim;
            guidata(hObject, handles); %Get the handles back after they were modified
        end
        
        %Start Experiment
        set(handles.txtStatus,'String','Running Closed-Loop');
        StartVisualizationBlock(hObject, handles);
    end
     
    function StartVisualizationBlock(hObject, handles)
        global sCoreParams;
        %Start Visualization Update Timer
        vizTimer = timer('TimerFcn',{@UpdateViz, hObject, handles},'Period',sCoreParams.write.broadcastSec / 5,'BusyMode','drop','ExecutionMode','fixedRate');
        assignin('base','vizTimer',vizTimer);
        handles.vizTimer = vizTimer;
        %handles.blockRunning = true;
        disp('In StartVisualizationBlock')        
        % Update handles structure
        guidata(hObject, handles);
        vizTimer.TimerFcn = {@UpdateViz, hObject, handles}; %Reassign to have itself in the handles - RIZ:There is probably a cleaner way!
        start(vizTimer);
    end

            
        
    function InitializeNetwork(hObject, handles)
    % Initialize or Reset the receiving UDP socket (the one used by ReceiveWrite.slx model
    if isfield(handles,'network') && isfield(handles.network,'vizContinuousSocket') && handles.network.vizContinuousSocket>0
        pnet(handles.network.vizContinuousSocket, 'close')
        pnet(handles.network.vizTriaByTrialSocket, 'close'); % Assumes both are open or not together
        pnet(handles.network.vizAveragedEEGSocket, 'close'); % Assumes both are open or not together
    else
        %Close all connections and Initialize UDPCommunication for first time
        pnet('closeall')
    end
    % Initilize UDP socket - There are now 2 sockets (ports) one for
    % Continuous data and one for TrialByTrialData
    handles.network.vizContinuousSocket = InitUDPreceiver('127.0.0.1',59124); % Use this port 59124 for CONTINUOUS data % For target PC keep tde correct 4915265535  range!
    handles.network.vizTrialByTrialSocket = InitUDPreceiver('127.0.0.1',59134); % Use this port 59134 for TRIAL by TRIAL data % For target PC keep tde correct 4915265535  range!
    handles.network.vizAveragedEEGSocket = InitUDPreceiver('127.0.0.1',59144); % Use this port 59144 for AVERAGED EEG data % For target PC keep tde correct 4915265535  range!
    if (handles.network.vizContinuousSocket<0) || (handles.network.vizTrialByTrialSocket<0) || (handles.network.vizAveragedEEGSocket<0)
        disp('ERROR:: Initializing UDP receiver')
    end
    
    % Update handles structure
    guidata(hObject, handles);
    end
    
    function initializeVariables(hObject, handles)
        global sCoreParams;
        %Initial Parameters
        sCoreParams = InitCoreParams;
        %Initial Variants
        [variantParams, variantConfig] = InitVariants();

        % If there is a specific patient config 
%         if ~isempty(handles.sCoreParamConfigFileName)
%             % We need to add the folder to the path because MATAB limits function name to 63chars!
%             [configPath sCoreFileNameOnly] = fileparts(handles.sCoreParamConfigFileName);
%             addpath(configPath);
%             [sCoreParams, variantConfig] = feval(sCoreFileNameOnly, sCoreParams, variantConfig);
%         end
        % Assign sCoreParams
        handles.sCoreParams = sCoreParams;
        tunableParams = NameTunableParams;
        FlattenAndTune(sCoreParams, 'sCoreParams',tunableParams);
        assignin('base','sCoreParams',sCoreParams);
        handles.paramChanged = false;

        %Assign Variants
        handles.variant.variantParams = variantParams;
        handles.variant.variantConfig = variantConfig;
        [variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
        FlattenAndTuneVariants(variantParams,'variantParams',variantParamsFlatNames);
        FlattenAndTune(variantConfig,'variantConfig',variantConfigFlatNames);
        assignin('base','variantParamsFlatNames',variantParamsFlatNames);
        %assignin('base','variantConfigFlatNames',variantConfigFlatNames);
        handles.variantChanged = true;
        handles.needsToReCompile = false; %RIZ -> check if false is OK?!?!
        % Update handles structure
        handles = orderfields(handles);
        guidata(hObject, handles);
    end

    function patientSpecificConfiguration(hObject, eventdata, handles)
        %Configure parameters (sCoreParams and Variants) based on patient specific config file
        % This function should only be called if there is a patient specific file
        global sCoreParams;
        
        % Read file
        [configPath, sCoreFileNameOnly] = fileparts(handles.sCoreParamConfigFileName);
        addpath(configPath);
        [sCoreParams, variantConfig] = feval(sCoreFileNameOnly, sCoreParams, handles.variant.variantConfig);
        sCoreParams = InitCoreParams_Dependent(sCoreParams);

        %Assign Variants
        [variantParamsFlatNames, variantConfigFlatNames] = NameTunableVariants();
        FlattenAndTuneVariants(handles.variant.variantParams,'variantParams',variantParamsFlatNames);
        FlattenAndTune(variantConfig,'variantConfig',variantConfigFlatNames);
        assignin('base','variantParamsFlatNames',variantParamsFlatNames);
          
        % pop Menus - Make selection based on variants
        possibleFreqLow = [4,8,15,30,65,140,65200,80,30110,1216,0]; %Poor HACK!!
        possibleFeaturesInPopMenu = [3,4,5,2]; %Poor HACK!! Corresponds to: SmoothBandPower=3, VarianceOfPower=4, Coherence=5, IED=2, LOGBandPower
        possibleDetectorsInPopMenu = [1,3;4,5;6,7;2,2]; %Poor HACK!! Corresponds to: NeuralModel =1 / NeuralModel Multisite =2
        possibleStimTypeInPopMenu = [1,3;2,4]; %Poor HACK!! Corresponds to: CONTINUOUS: WHICH_DETECTOR={1,3} / TRIGGER: WHICH_DETECTOR={4,5} / MULTISITE: WHICH_DETECTOR={6,7}
        set(handles.popFreq,'Value',find(possibleFreqLow==variantConfig.FREQ_LOW));
        set(handles.popFeature,'Value',find(possibleFeaturesInPopMenu==variantConfig.WHICH_FEATURE));
        [row, col] = find(possibleStimTypeInPopMenu==variantConfig.STIMULATION_TYPE);
        set(handles.popStimulationType,'Value', row);
        set(handles.popDetectorType,'Value',find(possibleDetectorsInPopMenu == variantConfig.WHICH_DETECTOR));
        set(handles.popTriggerType,'Value',variantConfig.TRIGGER_TYPE);
        set(handles.popMontage,'Value',variantConfig.IS_BIPOLAR+1); %IS BIPOLAR IS 0 or 1, add one to move it to 1 based
        
        %Call the pop objects callbacks to update the variants
        popFreq_Callback(handles.popFreq, eventdata, handles);
        handles = guidata(handles.popFreq); %Get the handles back after they were modified
        popFeature_Callback(handles.popFeature, eventdata, handles);
        handles = guidata(handles.popFeature); %Get the handles back after they were modified
        popDetectorType_Callback(handles.popDetectorType, eventdata, handles);
        handles = guidata(handles.popDetectorType); %Get the handles back after they were modified
        popStimulationType_Callback(handles.popStimulationType, eventdata, handles);
        handles = guidata(handles.popStimulationType); %Get the handles back after they were modified
        popTriggerType_Callback(handles.popTriggerType, eventdata, handles);
        handles = guidata(handles.popTriggerType); %Get the handles back after they were modified
        popMontage_Callback(handles.popMontage, eventdata, handles);
        handles = guidata(handles.popMontage); %Get the handles back after they were modified

        
        % Mark variant change
        handles.variant.variantConfig = variantConfig;
        handles.variantChanged = true;

        % Assign sCoreParams
        handles.sCoreParams = sCoreParams;
        FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);
        assignin('base','sCoreParams',sCoreParams);

        guidata(hObject, handles);
        
    end
    
    function initializeParameters(hObject, handles)
        global sCoreParams;
        %more config - Expected data sizes
       % handles.params.expectedDataWidth = handles.sCoreParams.write.maxSignalsPerStep;% +1;
        handles.params.streamDepthSamp = sCoreParams.viz.streamDepthSec  / sCoreParams.core.stepPeriod;
        handles.params.packetDepthSamp = sCoreParams.write.broadcastSamp; % / sCoreParams.core.stepPeriod;
       
        %Constants to define inputs from UDP:
        handles.plotInfo.continuous.NSP_TIME = 1; %first column is previous NSP 
        handles.plotInfo.continuous.STIM_HAPPENNING = 2;
        handles.plotInfo.continuous.EVENT_STIMULATION = 3;
        handles.plotInfo.continuous.EVENT_DETECTED = 4; 
        handles.plotInfo.continuous.RANDOM_STIM = 5;  
        handles.plotInfo.continuous.BASELINETRIGGER = 6; %Baseline Trigger 
        handles.plotInfo.continuous.DETSTIMTRIGGER = 7; %Detection/Stim Triggers
        handles.plotInfo.continuous.STIM_CHANNEL = [8 9]; % two contacts create a stim channel
        handles.plotInfo.continuous.FIRST_FEATURE = 10;

        handles.plotInfo.trialbytrial.IS_TRIALBYTRIAL = 1;      % first column is PI      
        handles.plotInfo.trialbytrial.NSP_TIME = 2;             % then column is current NSP         
        handles.plotInfo.trialbytrial.NUMBER_STIM = 3;          % previous EVENT_DETECTED corresponds now to number of STIM
        handles.plotInfo.trialbytrial.NUMBER_DET_STIM = 4;      % Then Stim from detection  
        handles.plotInfo.trialbytrial.NUMBER_RANDOM_STIM = 5;   % Random STIM
        handles.plotInfo.trialbytrial.NUMBER_DETECTIONS = 6;    % Detections (could be or not with stim) 
        handles.plotInfo.trialbytrial.STIM_CHANNEL = [7 8];     % two contacts create a stim channel
        handles.plotInfo.trialbytrial.FIRST_FEATURE = 9; 	
       
        handles.plotInfo.averagedEEG.NSP_TIME = 1;              % then column is current NSP         
        handles.plotInfo.averagedEEG.NUMBER_STIM = 2;          % previous EVENT_DETECTED corresponds now to number of STIM
        handles.plotInfo.averagedEEG.NUMBER_DET_STIM = 3;      % Then Stim from detection  
        handles.plotInfo.averagedEEG.NUMBER_RANDOM_STIM = 4;   % Random STIM
        handles.plotInfo.averagedEEG.STIM_CHANNEL = [5 6];     % two contacts create a stim channel
        handles.plotInfo.averagedEEG.FIRST_AVERAGEDEEG = 7; 	

        %Initialize also controls
        %Contacts lists -> change to channel names for Simulation ONLY!
        if strcmpi(handles.mode,'Simulation') && strcmpi(handles.simulation.typeSimulation, 'REAL')
            strChannelVals = sCoreParams.decoders.txDetector.channelNames;
            strChannelVals{length(strChannelVals)+1} = 'BaselineTrig'; % RIZ: HARDCODED!! Make Generic!!!
            strChannelVals{length(strChannelVals)+1} = 'DetStimTrig';

        else % for closed loop - keep numbers
            strChannelVals = cell(1, sCoreParams.core.maxChannelsAllNSPs);
            for iCh =1:sCoreParams.core.maxChannelsAllNSPs
                strCh = num2str(iCh);
                strChannelVals{iCh} = strCh;
            end
        end
        
        % Keep Names and Numbers on handle variables
        channelNumbers = 1:sCoreParams.core.maxChannelsAllNSPs;
        handles.channelInfo.contact1.Names = strChannelVals;
        handles.channelInfo.contact2.Names = strChannelVals;
        handles.channelInfo.contact1.Numbers = channelNumbers;
        handles.channelInfo.contact2.Numbers = channelNumbers;
        
        nChansPerNSP = sCoreParams.core.maxChannelsAllNSPs/sCoreParams.core.NumberNSPs; 
        for indNSP=1:sCoreParams.core.NumberNSPs
            indChThisNSP = (indNSP-1)*nChansPerNSP+1: indNSP *nChansPerNSP;
            strNSP = num2str(indNSP);
            for iCh =1:nChansPerNSP
                handles.channelInfo.contact1.NSP_Names{indChThisNSP(iCh)} = strcat(strNSP,':',strChannelVals{indChThisNSP(iCh)});
                handles.channelInfo.contact2.NSP_Names{indChThisNSP(iCh)} = strcat(strNSP,':',strChannelVals{indChThisNSP(iCh)});
                handles.channelInfo.contact1.NSP_Numbers{indChThisNSP(iCh)} = [strNSP,':',num2str(iCh)];
                handles.channelInfo.contact2.NSP_Numbers{indChThisNSP(iCh)} = [strNSP,':',num2str(iCh)];
            end
        end
        
        set(handles.lstContact1,'String',handles.channelInfo.contact1.Names);
        set(handles.lstContact2,'String',handles.channelInfo.contact2.Names);
        %before and after stim time txtboxes
        set(handles.txtBeforeStimSec,'String',num2str(sCoreParams.viz.preTriggerSec));
        set(handles.txtAfterStimSec,'String',num2str(sCoreParams.viz.postTriggerSec));

        if (sCoreParams.Features.Baseline.weightPreviousThreshold >= 1) % if 1 it means  FIX Threshold!
            set(handles.chkFixThreshold,'Value', get(handles.chkFixThreshold,'Max')); %Check if =1 -- RIZ: Not sure if here is the best place...
        end
        set(handles.txtInitialThreshold,'String',num2str(sCoreParams.Features.Baseline.initialThresholdValue)); 
        set(handles.txtPrevThWeight,'String', num2str(sCoreParams.Features.Baseline.weightPreviousThreshold)); 
        set(handles.popDetectIfAnyAll,'Value',sCoreParams.decoders.txDetector.anyAll +1); % txDetector.anyAll =0 if ANY / =1 if ALL - in GUI corresponding value is 1/2

        %Others
        handles.average.beforeStimSec = str2double(get(handles.txtBeforeStimSec,'String'));
        handles.average.afterStimSec = str2double(get(handles.txtAfterStimSec,'String'));       
        handles.average.beforeStimSamples = str2double(get(handles.txtBeforeStimSec,'String')) * sCoreParams.write.broadcastAvEEGSamp;% / (sCoreParams.core.stepPeriod * sCoreParams.write.averagedEEGDownSampling);
        handles.average.afterStimSamples = str2double(get(handles.txtAfterStimSec,'String'))  * sCoreParams.write.broadcastAvEEGSamp;%/ (sCoreParams.core.stepPeriod * sCoreParams.write.averagedEEGDownSampling);
       % handles.blockRunning = false;
        handles.stimInfo.nStims = 0;
        handles.stimInfo.nShamStims = 0;
        handles.stimInfo.nEventDetectedStims = 0;
        handles.stimElectrodes = [0 0];
        
        % Update handles structure
        handles = orderfields(handles);
        guidata(hObject, handles);
    end

    function updateGUIObjectsFromCurrent(hObject, handles)
        % Update GUI objects to current Values - These Parameters  can be changed in real time
        %global tg;
        global sCoreParams;
        %sCoreParams =  handles.sCoreParams;
        tunableParams = NameTunableParams;
        for tuneInd = 1:length(tunableParams)
            % if strcmpi(handles.mode,'Simulation') % RIZ: changed to ONLY update from sCoreParams instead of from last values on target PC. This way config files are preoperly considered and not changed based on previous experiments.
            % Get parameter name
            stNameParam = strrep(tunableParams{tuneInd},'_','.');
            startVal = eval(stNameParam);
            %else %it is REAL TIME  CLOSE-LOOP (human or NHP!)
            %    startVal = GetRealTimeValue(tg, tunableParams{tuneInd});
            %end
            % modify GUI object
            hEditObj = findobj('UserData',tunableParams{tuneInd},'-and','Style','edit');
            if ~isempty(hEditObj) % it is a text, just change the string 
                disp([tunableParams{tuneInd}, ' - ', num2str(startVal)]);
                set(hEditObj,'String',num2str(startVal));
                callbackEditObj = get(hEditObj,'Callback');
                callbackEditObj(hEditObj,[]);
            else % Assume that if it is not text it is a list
                hEditObj = findobj('UserData',tunableParams{tuneInd},'-and','Style','list');
                if ~isempty(hEditObj)
                    disp([tunableParams{tuneInd}, ' - ', num2str(startVal)]);
                    nStrInList= length(get(hEditObj,'String'));
                    set(hEditObj,'Value',startVal(1:min(nStrInList,length(startVal))));
                    callbackEditObj = get(hEditObj,'Callback');
                    callbackEditObj(hEditObj,[]);
                end
            end
            assignin('base',tunableParams{tuneInd},startVal);
        end
    end
    
    function updateTargetParams(hObject, handles)
    % Update GUI objects to current Values - These Parameters  can be changed in real time
        global tg;
        global sCoreParams;
        
        sCoreParams = InitCoreParams_Dependent(sCoreParams);
        tunableParams = NameTunableParams;
        FlattenAndTune(sCoreParams, 'sCoreParams',tunableParams);
        assignin('base','sCoreParams',sCoreParams);
        if ~isempty(tg)
            for tuneInd = 1:length(tunableParams)
                stNameParam = strrep(tunableParams{tuneInd},'_','.');
                paramValue = eval(stNameParam);
                %it is ONLY for REAL TIME  CLOSE-LOOP
                tg = SetRealTimeOnlyNewValue(tg, tunableParams{tuneInd}, paramValue);
                disp(['Updated: ',tunableParams{tuneInd}, ' - ', num2str(paramValue(:)')]);
            end
        else
            %assumes simulation
            set_param(handles.modelName,'SimulationCommand','update');
            %Display new values
            for tuneInd = 1:length(tunableParams)
                stNameParam = strrep(tunableParams{tuneInd},'_','.');
                paramValue = eval(stNameParam);
                disp(['Updated: ',tunableParams{tuneInd}, ' - ', num2str(paramValue(:)')]);
            end
        end
    end
    
    function initializePlots(hObject, handles)
        %time applies to all plots
        global sCoreParams;
        global dataStreamHistory;
        dataStreamHistory = zeros( handles.params.streamDepthSamp,  sCoreParams.write.maxSignalsPerStep); % dataStreamHistory is the data coming from UDP - here we only specify the size
        clear handles.featureTraces; clear handles.thresholdTraces; clear handles.rawEEGTraces; clear handles.triggerTrace; clear triggerAveragedTraces; clear triggerAveragedDetSTIMTraces; clear triggerAveragedRandomSTIMTraces;
        
        %number of EEG channels of data sent with UDP is either the number of analized channels or the subset seleted for visualization
        nChannels = sCoreParams.viz.nChannels;
        nFeatures = sCoreParams.viz.nFeatures;
        handles.plotInfo.continuous.featurePositions = handles.plotInfo.continuous.FIRST_FEATURE:handles.plotInfo.continuous.FIRST_FEATURE+nFeatures-1;
        handles.plotInfo.continuous.thresholdPositions = handles.plotInfo.continuous.featurePositions(end)+1:handles.plotInfo.continuous.featurePositions(end)+nFeatures;
       % handles.plotInfo.continuous.thresholdPositions = handles.plotInfo.continuous.featurePositions(end)+1; % only 1 th for state estimate :handles.plotInfo.continuous.featurePositions(end)+nFeatures;
        handles.plotInfo.continuous.EEGDataPositions = handles.plotInfo.continuous.thresholdPositions(end)+1:handles.plotInfo.continuous.thresholdPositions(end)+nChannels;
        handles.plotInfo.continuous.filteredDataPositions = handles.plotInfo.continuous.EEGDataPositions(end)+1:handles.plotInfo.continuous.EEGDataPositions(end)+nChannels;

        handles.plotInfo.trialbytrial.featurePositions =  handles.plotInfo.trialbytrial.FIRST_FEATURE:handles.plotInfo.trialbytrial.FIRST_FEATURE+nFeatures-1;
        handles.plotInfo.trialbytrial.thresholdPositions = handles.plotInfo.trialbytrial.featurePositions(end)+1:handles.plotInfo.trialbytrial.featurePositions(end)+nFeatures;
 
        handles.plotInfo.averagedEEG.AvEEGAllSTIMPositions = handles.plotInfo.averagedEEG.FIRST_AVERAGEDEEG:handles.plotInfo.averagedEEG.FIRST_AVERAGEDEEG+nChannels-1;
        handles.plotInfo.averagedEEG.AvEEGDetSTIMPositions = handles.plotInfo.averagedEEG.AvEEGAllSTIMPositions(end)+1:handles.plotInfo.averagedEEG.AvEEGAllSTIMPositions(end)+nChannels;
        handles.plotInfo.averagedEEG.AvEEGRandomSTIMPositions = handles.plotInfo.averagedEEG.AvEEGDetSTIMPositions(end)+1:handles.plotInfo.averagedEEG.AvEEGDetSTIMPositions(end)+nChannels;

        tAx = linspace(0,sCoreParams.viz.streamDepthSec, handles.params.streamDepthSamp);
        
        %Plot 1: Detections & STIMULATION
        cla(handles.axDetections);
        hold(handles.axDetections, 'on');
        set(handles.axDetections, 'XTick', tAx);
        title(handles.axDetections, '\bf STIMULATION & \rm Event/Random Detections','Color','white');
        handles.eventDetectedTrace = plot(handles.axDetections,tAx,dataStreamHistory(:,handles.plotInfo.continuous.EVENT_DETECTED),'green','LineWidth',1);
        handles.eventStimulationTrace = plot(handles.axDetections,tAx,dataStreamHistory(:,handles.plotInfo.continuous.EVENT_STIMULATION),'blue','LineWidth',1);
        handles.shamDetectedTrace = plot(handles.axDetections,tAx,dataStreamHistory(:,handles.plotInfo.continuous.RANDOM_STIM),'cyan','LineWidth',1);
        handles.realStimTrace = plot(handles.axDetections,tAx,dataStreamHistory(:,handles.plotInfo.continuous.STIM_HAPPENNING),'red','LineWidth',3);
        
        %Plot 2: Features and Thresholds
        cla(handles.axFeaturesThresholds);
        hold(handles.axFeaturesThresholds, 'on');
        set(handles.axFeaturesThresholds, 'XTick', tAx);
        handles.axFeaturesThresholds.ColorOrderIndex =1;
        title(handles.axFeaturesThresholds, 'Features and Thresholds','Color','white', 'FontWeight','normal');
        handles.featureTraces = plot(handles.axFeaturesThresholds,tAx,dataStreamHistory(:,handles.plotInfo.continuous.featurePositions),'LineWidth',1); %Features
        handles.axFeaturesThresholds.ColorOrderIndex =1;
        handles.thresholdTraces = plot(handles.axFeaturesThresholds,tAx,dataStreamHistory(:,handles.plotInfo.continuous.thresholdPositions),'LineWidth',1.5,'LineStyle',':');
        
        %Plot 3: RAW EEG
        cla(handles.axRawEEG);
        hold(handles.axRawEEG, 'on');
        set(handles.axRawEEG, 'XTick', tAx);
        handles.axRawEEG.ColorOrderIndex =1;
        title(handles.axRawEEG, 'Bipolar EEG','Color','white', 'FontWeight','normal');
        handles.rawEEGTraces = plot(handles.axRawEEG,tAx,dataStreamHistory(:,handles.plotInfo.continuous.EEGDataPositions),'LineWidth',1); %Raw EEG data
        handles.baselineTriggerTrace = stem(tAx,dataStreamHistory(:,handles.plotInfo.continuous.BASELINETRIGGER),'LineWidth',1,'Color','cyan','Marker','none','Parent',handles.axRawEEG); %Raw EEG data
        handles.detStimTriggerTrace = stem(tAx,dataStreamHistory(:,handles.plotInfo.continuous.DETSTIMTRIGGER),'LineWidth',1,'Color','white','Marker','none','Parent',handles.axRawEEG); %Raw EEG data

        %Plot 4: Triger Averagged EEG - 3 plots
        tTriggerAvAx = linspace(-handles.average.beforeStimSec, handles.average.afterStimSec, handles.average.beforeStimSamples+handles.average.afterStimSamples); % The whole plot is replaced each time
        % Plot 4.a - ALL STIM
        cla(handles.axTriggerAveraged);
        hold(handles.axTriggerAveraged, 'on');
        %set(handles.axTriggerAveraged, 'XTick', tTriggerAvAx);
        set(handles.axTriggerAveraged, 'xGrid', 'on');
        handles.axTriggerAveraged.ColorOrderIndex =1;
        title(handles.axTriggerAveraged, 'All STIM Averaged EEG','Color','white', 'FontWeight','normal');
        handles.triggerAveragedTraces = plot(handles.axTriggerAveraged, tTriggerAvAx, zeros( length(tTriggerAvAx), length(handles.plotInfo.averagedEEG.AvEEGAllSTIMPositions)),'LineWidth',1, 'Parent', handles.axTriggerAveraged); %Raw EEG data
        handles.triggerAveragedStim = stem(tTriggerAvAx, zeros( length(tTriggerAvAx), 1),'Marker','none','LineWidth',2,'LineStyle','--','Color','red', 'Parent', handles.axTriggerAveraged); %Raw EEG data
        % Plot 4.b - Detected STIM
        cla(handles.axTriggerAveragedDetSTIM);
        hold(handles.axTriggerAveragedDetSTIM, 'on');
       % set(handles.axTriggerAveragedDetSTIM, 'XTick', tTriggerAvAx);
        set(handles.axTriggerAveragedDetSTIM, 'xGrid', 'on');
        handles.axTriggerAveragedDetSTIM.ColorOrderIndex =1;
        title(handles.axTriggerAveragedDetSTIM, 'Det STIM Averaged EEG','Color','white', 'FontWeight','normal');
        handles.triggerAveragedDetSTIMTraces = plot(handles.axTriggerAveragedDetSTIM, tTriggerAvAx, zeros( length(tTriggerAvAx), length(handles.plotInfo.averagedEEG.AvEEGDetSTIMPositions)),'LineWidth',1, 'Parent', handles.axTriggerAveragedDetSTIM); %Raw EEG data
        handles.triggerAveragedDetSTIMStim = stem(tTriggerAvAx, zeros( length(tTriggerAvAx), 1),'Marker','none','LineWidth',2,'LineStyle','--','Color','green', 'Parent', handles.axTriggerAveragedDetSTIM); %Raw EEG data
        % Plot 4.c - Detected STIM
        cla(handles.axTriggerAveragedRandomSTIM);
        hold(handles.axTriggerAveragedRandomSTIM, 'on');
        % set(handles.axTriggerAveragedRandomSTIM, 'XTick', tTriggerAvAx);
        set(handles.axTriggerAveragedRandomSTIM, 'xGrid', 'on');
        handles.axTriggerAveragedRandomSTIM.ColorOrderIndex =1;
        title(handles.axTriggerAveragedRandomSTIM, 'Random STIM Averaged EEG','Color','white', 'FontWeight','normal');
        handles.triggerAveragedRandomSTIMTraces = plot(handles.axTriggerAveragedRandomSTIM, tTriggerAvAx, zeros( length(tTriggerAvAx), length(handles.plotInfo.averagedEEG.AvEEGRandomSTIMPositions)),'LineWidth',1, 'Parent', handles.axTriggerAveragedRandomSTIM); %Raw EEG data
        handles.triggerAveragedRandomSTIMStim = stem(tTriggerAvAx, zeros( length(tTriggerAvAx), 1),'Marker','none','LineWidth',2,'LineStyle','--','Color','cyan', 'Parent', handles.axTriggerAveragedRandomSTIM); %Raw EEG data

        %Link axes to zoom all together on X
        linkaxes([handles.axDetections, handles.axFeaturesThresholds, handles.axRawEEG], 'x');
        linkaxes([handles.axTriggerAveraged, handles.axTriggerAveragedDetSTIM, handles.axTriggerAveragedRandomSTIM], 'x');        

         %NONE is visible at the beginning
        set(handles.axTriggerAveraged,'Visible','off');
        set(handles.axTriggerAveragedDetSTIM,'Visible','off');
        set(handles.axTriggerAveragedRandomSTIM,'Visible','off');
       
        %organize handles
        handles = orderfields(handles);
        guidata(hObject, handles);
    end

    function initializeWithControlValues(hObject, handles)
        % Clear also txt with stim/channel info
        set(handles.txtStimElectrode1,'String','');
        set(handles.txtStimElectrode2,'String','');
        set(handles.txtShamStim,'String',num2str(0));
        set(handles.txtDetectedStim,'String',num2str(0));
        
        txtBeforeStimSec_Callback(handles.txtBeforeStimSec, [], handles);
        txtAfterStimSec_Callback(handles.txtAfterStimSec, [], handles);
        
        % Call Threshold txt and checkboxes to start with selection
        txtDetectionRMSLower_Callback(handles.txtDetectionRMSLower, [], handles);
        txtDetectionRMSUpper_Callback(handles.txtDetectionRMSUpper, [], handles);
        txtDetectionSign_Callback(handles.txtDetectionSign, [], handles);
        txtNDetectionsReq_Callback(handles.txtNDetectionsReq, [], handles);
        chkFixThreshold_Callback(handles.chkFixThreshold, [], handles);
        txtInitialThreshold_Callback(handles.txtInitialThreshold, [], handles);
        txtPrevThWeight_Callback(handles.txtPrevThWeight, [], handles);
        txtRandomStimulation_Callback(handles.txtRandomStimulation, [], handles);
        txtProbaNoStim_Callback(handles.txtProbaNoStim, [], handles);
        txtSmoothDuration_Callback(handles.txtSmoothDuration, [], handles);
        txtStimAfterDelay_Callback(handles.txtStimAfterDelay, [], handles);
        popAveragedEEGPlot_Callback(handles.popAveragedEEGPlot, [], handles);
        % Call lstVisualization callback to only show selected channels/features
        lstVizChannelIndexes_Callback(handles.lstVizChannelIndexes, [], handles);
        
        %organize handles
        handles = orderfields(handles);
        guidata(hObject, handles);   
    
    end
    
    function UpdateViz(~,~, hObject, handles)
    
        % Run for continuous packets
        [newContinousData] = getContinuousStreamData(hObject, handles);
        if ~isempty(newContinousData)
            UpdateContinuousViz(hObject, handles, newContinousData);
            % If we are running simulation and all EEG is zero -> STOP simulation (and save data!)
            eegDATA = newContinousData(:,handles.plotInfo.continuous.EEGDataPositions);
            if strcmpi(handles.mode,'Simulation') && (all(eegDATA(:)==0)) && (any(newContinousData(:,handles.plotInfo.continuous.NSP_TIME)>eps))
                disp(['Simulation finished - EEG is all ZERO'])
                btnStop_Callback(handles.btnStop, [], handles)
                % handles = guidata(handles.btnStop); %Get the handles back after they were modified
            end
        end
        
        % Look for trial by trial packets
        [newTrialByTrialData] = getTrialByTrialStreamData(hObject, handles);
        if ~isempty(newTrialByTrialData)
            UpdateTrialByTrialViz(hObject, handles, newTrialByTrialData);
        end
        
        % Look for Averaged Data packets        
        [newAveragedEEG] =getAveragedEEGStreamData(hObject, handles);
        if ~isempty(newAveragedEEG)
            UpdateAveragedEEGViz(hObject, handles, newAveragedEEG);
        end
        
%         % If we are running simulation and all EEG is zero -> STOP simulation (and save data!)
%         if strcmpi(handles.mode,'Simulation') && ~isempty(newContinousData) && (sum(sum(newContinousData(:,handles.plotInfo.continuous.EEGDataPositions)))==0) && (any(newContinousData(:,handles.plotInfo.continuous.NSP_TIME)>eps))
%             disp(['Simulation finished - EEG is all ZERO'])
%             btnStop_Callback(handles.btnStop, [], handles)
%            % handles = guidata(handles.btnStop); %Get the handles back after they were modified
%         end
    end
    
    function [newContinousData] =getContinuousStreamData(hObject, handles)
           %        disp(['A in GetStreamData']);
           global sCoreParams;
           %Get Data from UDP and Plot
           % if handles.blockRunning
           newContinousData = ReceiveUDP(handles.network.vizContinuousSocket,'latest','double'); %Get new UDP package
           if isempty(newContinousData) || (length(newContinousData)~=(handles.params.packetDepthSamp * sCoreParams.write.maxContinuousSignalsPerStep))
               newContinousData=[];
               return
           end
%            if numel(newContinousData) < handles.params.packetDepthSamp * sCoreParams.write.maxContinuousSignalsPerStep
%                disp(['Data size to large - Reduce Number of Channels! - ',num2str(numel(newContinousData)),' > ',num2str(handles.params.packetDepthSamp * sCoreParams.write.maxContinuousSignalsPerStep)])
%                return
%            end
           newContinousData = reshape(newContinousData(1:(handles.params.packetDepthSamp * sCoreParams.write.maxContinuousSignalsPerStep)),[handles.params.packetDepthSamp, sCoreParams.write.maxContinuousSignalsPerStep]);        
    end

    function [newTrialByTrialData] =getTrialByTrialStreamData(hObject, handles)
        %        disp(['A in GetStreamData']);
        %Get Data from UDP and Plot
        global sCoreParams;
        newTrialByTrialData = ReceiveUDP(handles.network.vizTrialByTrialSocket,'latest','double'); %Get new UDP package
        if isempty(newTrialByTrialData) || (length(newTrialByTrialData)~=( sCoreParams.write.maxTrialByTrialDataPerStep))
           newTrialByTrialData=[];
           return
       end
   end
  
    function [newAveragedEEGData] = getAveragedEEGStreamData(hObject, handles)
       %Get Data from UDP and Plot
       global sCoreParams;
       newAveragedEEGData = ReceiveUDP(handles.network.vizAveragedEEGSocket,'latest','double'); %Get new UDP package
       if isempty(newAveragedEEGData) || (length(newAveragedEEGData)~=(sCoreParams.write.broadcastAvEEGSamp * sCoreParams.write.maxAveragedDataPerStep))
           newAveragedEEGData=[];
           return
       end
       newAveragedEEGData = reshape(newAveragedEEGData(1:(sCoreParams.write.broadcastAvEEGSamp * sCoreParams.write.maxAveragedDataPerStep)),[sCoreParams.write.broadcastAvEEGSamp, sCoreParams.write.maxAveragedDataPerStep]);

    end
    
    function UpdateContinuousViz(hObject, handles, newData)
        persistent timeStampPrev;
        persistent nSame;
     %   persistent triggerAvData;
        global stimInfo;
        global dataStreamHistory;
        %global targetConnected;

        if isempty(timeStampPrev)
            timeStampPrev = -1;
        end
        if isempty(nSame)
            nSame = 0;
        end       
        if isempty(stimInfo)
            stimInfo.nStims=0;
            stimInfo.nShamStims=0;
            stimInfo.nEventDetectedStims=0;
            stimInfo.eachStim = cell(1,0);
        end
%         if isempty(triggerAvData) || size(triggerAvData,2) ~= length(handles.plotInfo.continuous.EEGDataPositions)
%             triggerAvData = zeros( handles.average.afterStimSamples+handles.average.beforeStimSamples, length(handles.plotInfo.continuous.EEGDataPositions));
%         end
        
        % Update continuous data
        dataStreamCandidate = [dataStreamHistory((handles.params.packetDepthSamp+1):end,:); newData];
        % Show NSP time
        timeStamp = dataStreamCandidate(end, handles.plotInfo.continuous.NSP_TIME);
        set(handles.txtNSPtime,'String',num2str(timeStamp));
        
        if timeStamp > timeStampPrev && ~all(isnan(dataStreamCandidate(:)))
            dataStreamHistory = dataStreamCandidate;
            disp(['in UpdateViz - NSP=',num2str(timeStamp)]);
            
            % PLOT 1. Update plots with information about all channels (event detected / STIM)
            set( handles.realStimTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.STIM_HAPPENNING));
            set(handles.eventDetectedTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.EVENT_DETECTED));
            set(handles.eventStimulationTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.EVENT_STIMULATION));
            set(handles.shamDetectedTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.RANDOM_STIM));
            
            %PLOT 2. Update Features and Thresholds
            for iCh=1:length(handles.plotInfo.continuous.featurePositions)
                set( handles.featureTraces(iCh),'YData',dataStreamHistory(:,handles.plotInfo.continuous.featurePositions(iCh)));
            end
            for iCh=1:length(handles.plotInfo.continuous.thresholdPositions)
                set(handles.thresholdTraces(iCh),'YData',dataStreamHistory(:,handles.plotInfo.continuous.thresholdPositions(iCh)));
            end
            
            % PLOT 3. Update RAW EEG plot - including trigger
            for iCh=1:length(handles.plotInfo.continuous.EEGDataPositions)
                set(handles.rawEEGTraces(iCh),'YData',dataStreamHistory(:,handles.plotInfo.continuous.EEGDataPositions(iCh)));
            end
            set(handles.baselineTriggerTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.BASELINETRIGGER) * max(max(dataStreamHistory(:,handles.plotInfo.continuous.EEGDataPositions(:)))));
            set(handles.detStimTriggerTrace,'YData',dataStreamHistory(:,handles.plotInfo.continuous.DETSTIMTRIGGER) * max(max(dataStreamHistory(:,handles.plotInfo.continuous.EEGDataPositions(:)))));
            % set(h_titleCount,'String',(sprintf('Total stims: %i %i ',totalStim,totalRandStim)));
            
%             % PLOT 4. Update Trigger Averaged signal
%             %[triggerAvData, isNewTriggerAv, stimDataForAv] = displayTiggerAverageSignal(triggerAvData, handles);
%             if (isNewTriggerAv == true)
%                 handles.stimInfo = stimInfo;
%                 for iCh=1:length(handles.plotInfo.continuous.EEGDataPositions)
%                     set(handles.triggerAveragedTraces(iCh),'YData', triggerAvData(:,iCh));
%               %      set(handles.txtShamStim,'String',num2str(stimInfo.nShamStims)); %RIZ: WE NOW GET THIS INFO directly from model
%               %      set(handles.txtDetectedStim,'String',num2str(stimInfo.nEventDetectedStims));
%                 end
%                 set(handles.triggerAveragedStim,'YData',stimDataForAv);
%             end
%             
%             %5. Update Stimulation Channels if different than before
%             [isNewStimChannel, stimElectrodes] = updateStimChannel(handles);
%             if (isNewStimChannel == true)
%                 handles.stimElectrodes = stimElectrodes;
%                 set(handles.txtStimElectrode1,'String',num2str(stimElectrodes(1)));
%                 set(handles.txtStimElectrode2,'String',num2str(stimElectrodes(2)));
%             end
            
            %6. Update timeStamp
            timeStampPrev = timeStamp;
            nSame=0;
        elseif timeStampPrev> 0 && timeStamp<timeStampPrev
            % Assume we are on a new block and reset persitent values
            disp(['Assuming new Block - PrevTimesStamp:', num2str(timeStampPrev),' - NewTimeStamp:', num2str(timeStamp)]);
            timeStampPrev = timeStamp;
            stimInfo =[];
            nSame=0;
        %    triggerAvData=[];
        elseif timeStamp==timeStampPrev 
            disp(['Same - PrevTimesStamp:', num2str(timeStampPrev),' - NewTimeStamp:', num2str(timeStamp)]);
            if nSame>5
                btnStop_Callback(handles.btnStop, [], handles); %RIZ:TEST! I DON't KNOW WHY it gets stuck here
            end
            nSame =nSame+1;
        end
        %         elseif ~handles.blockRunning && targetConnected
        %             StartBlock;
        %             handles.blockRunning = true;
        
        handles = orderfields(handles);
        guidata(hObject, handles);
    end

    function UpdateTrialByTrialViz(hObject, handles, newData)
        persistent nStimPrev;
        persistent nDetPrev;
        global dataTrialByTrialHistory;
%        global dataAllTrials;
        
        %Initialize persistent variables if empty or if at the beggining of an experiment
        if isempty(nStimPrev) || all(dataTrialByTrialHistory(:)==0), nStimPrev = 0; end
        if isempty(nDetPrev) || all(dataTrialByTrialHistory(:)==0),  nDetPrev = 0; end

        % Update trial by trial data
        if ~isempty(newData)
            dataTrialByTrialCandidate = newData(end,:);
            nStims = dataTrialByTrialCandidate( handles.plotInfo.trialbytrial.NUMBER_STIM); 
            nDetStims = dataTrialByTrialCandidate( handles.plotInfo.trialbytrial.NUMBER_DET_STIM); 
            nRandomStims = dataTrialByTrialCandidate( handles.plotInfo.trialbytrial.NUMBER_RANDOM_STIM); 
            nDetections = dataTrialByTrialCandidate( handles.plotInfo.trialbytrial.NUMBER_DETECTIONS); 
        else
            nStims = 0;
            nDetStims = 0;
            nRandomStims = 0;
            nDetections = 0;
        end
        %disp([' in UpdateTrialByTrialViz A - Trial number=',num2str(nTrial)]);

        if (nStims > nStimPrev || nDetections > nDetPrev) && ~all(isnan(dataTrialByTrialCandidate(:)))
            dataTrialByTrialHistory = [dataTrialByTrialHistory(2:end,:); dataTrialByTrialCandidate]; % the first one is removed and replaced by new data
            disp([' in UpdateTrialByTrialViz B - nStm=',num2str(nStims),' - nDetStims=',num2str(nDetStims),' - nRandomStims=',num2str(nRandomStims),' - nDetections=',num2str(nDetections)]);
            %set(handles.txtTrialNumber,'String',num2str(nTrial));

                        
            % Update Stimulation Channels if different than before
            [isNewStimChannel, stimElectrodes] = updateStimChannel(handles);
            if (isNewStimChannel == true)
                handles.stimElectrodes = stimElectrodes;
                set(handles.txtStimElectrode1,'String',num2str(stimElectrodes(1)));
                set(handles.txtStimElectrode2,'String',num2str(stimElectrodes(2)));
            end
            set(handles.txtDetectedStim,'String',num2str(nDetStims));
            set(handles.txtShamStim,'String',num2str(nRandomStims));

            
            % Prepare matrix to Save
            createTrialByTrialMatrixToSave(dataTrialByTrialHistory, handles);
            %handles.dataAllTrials = dataAllTrials;
            
            %6. Update timeStamp (trial number)
            nStimPrev = nStims;
            nDetPrev = nDetections;

        else
            if nStimPrev> 0 && nStims<nStimPrev %&& nStims>0
                % Assume we are on a new block and reset persitent values
                nStimPrev = nStims;
            end
            if nDetPrev> 0 && nDetections<nDetPrev % && nDetections>0
                % Assume we are on a new block and reset persitent values
                nDetPrev = nDetections;
            end
        end

        handles = orderfields(handles);
        guidata(hObject, handles);
    end
    
    
    function UpdateAveragedEEGViz(hObject, handles, newData)
        persistent nStimPrev;
        persistent stimDataForAv;
      %  global dataAveragedEEGHistory;
%        global dataAllTrials;
        
        %Initialize persistent variables if empty or if at the beggining of an experiment
        if isempty(nStimPrev), nStimPrev = 0; end
        if isempty(stimDataForAv) 
            stimDataForAv = zeros(1, handles.average.beforeStimSamples+handles.average.afterStimSamples); 
            stimDataForAv(handles.average.beforeStimSamples+1) =1;
        end

        % Update trial by trial data
        if ~isempty(newData)
            dataAveragedEEGCandidate = newData;
            nStims = dataAveragedEEGCandidate(end, handles.plotInfo.averagedEEG.NUMBER_STIM); 
            nDetStims = dataAveragedEEGCandidate(end, handles.plotInfo.averagedEEG.NUMBER_DET_STIM); 
            nRandomStims = dataAveragedEEGCandidate(end, handles.plotInfo.averagedEEG.NUMBER_RANDOM_STIM); 
        end

        if (nStims > nStimPrev) && ~all(isnan(dataAveragedEEGCandidate(:)))
           % dataAveragedEEGHistory = cat(3,dataAveragedEEGHistory,dataAveragedEEGCandidate); % only keep current average - RIZ: does it make sense?
            disp([' in UpdateAveragedEEGViz C - nStm=',num2str(nStims),' - nDetStims=',num2str(nDetStims),' - nRandomStims=',num2str(nRandomStims), '-prev: ',num2str(nStimPrev)]);
            %set(handles.txtTrialNumber,'String',num2str(nTrial));
                             
            %Plot Averaged EEG
            for iCh=1:length(handles.plotInfo.averagedEEG.AvEEGAllSTIMPositions)
                set(handles.triggerAveragedTraces(iCh),'YData', dataAveragedEEGCandidate(:,handles.plotInfo.averagedEEG.AvEEGAllSTIMPositions(iCh)));
                set(handles.triggerAveragedDetSTIMTraces(iCh),'YData', dataAveragedEEGCandidate(:,handles.plotInfo.averagedEEG.AvEEGDetSTIMPositions(iCh)));
                set(handles.triggerAveragedRandomSTIMTraces(iCh),'YData', dataAveragedEEGCandidate(:,handles.plotInfo.averagedEEG.AvEEGRandomSTIMPositions(iCh)));
            end
            stimDataForAvScaled = stimDataForAv * max(max(dataAveragedEEGCandidate(:,handles.plotInfo.averagedEEG.AvEEGAllSTIMPositions(1):handles.plotInfo.averagedEEG.AvEEGRandomSTIMPositions(end))));
            set(handles.triggerAveragedStim,'YData',stimDataForAvScaled);
            set(handles.triggerAveragedDetSTIMStim,'YData',stimDataForAvScaled);
            set(handles.triggerAveragedRandomSTIMStim,'YData',stimDataForAvScaled);           

            % Select what to show
            popAveragedEEGPlot_Callback(handles.popAveragedEEGPlot,[],handles);
            % Prepare matrix to Save
            %createTrialByTrialMatrixToSave(dataTrialByTrialHistory, handles);
            %handles.dataAllTrials = dataAllTrials;
            
            %6. Update timeStamp (trial number)
            nStimPrev = nStims;
            handles = orderfields(handles);
            guidata(hObject, handles);

        else
            if nStimPrev> 0 && nStims<nStimPrev %&& nStims>0
                % Assume we are on a new block and reset persitent values
                nStimPrev = nStims;
            end
        end

        handles = orderfields(handles);
        guidata(hObject, handles);
    end
        
%     function [triggerAvData, isNewTriggerAv, stimDataForAv] = displayTiggerAverageSignal(triggerAvData, handles)
%         global dataStreamHistory;
%         global stimInfo;
%         persistent prevStimDataTime;
%         if isempty(prevStimDataTime), prevStimDataTime=0;end 
% 
%         isNewTriggerAv = false;
%         stimDataForAv = zeros(size(triggerAvData,1),1);
%         stimData = dataStreamHistory(:,handles.plotInfo.continuous.STIM_HAPPENNING);
%         indStim = find(stimData,1); %only keep the fist stimulation in package (there might be 2, but it is easier and faster this way)
%         if ~isempty(indStim)
%             stimDataTime = dataStreamHistory(indStim, handles.plotInfo.continuous.NSP_TIME);
%             lData =size(dataStreamHistory,1);
%             if (stimDataTime ~= prevStimDataTime) && (indStim < max(lData/3,handles.average.beforeStimSamples)) %at least in the first third of the signal
%                 disp(['in displayTiggerAverageSignal - indStim=',num2str(indStim),' - StimTime=',num2str(stimDataTime)]);
%                 newData = dataStreamHistory(max(indStim - handles.average.beforeStimSamples, 1): min(handles.average.afterStimSamples + indStim, lData), handles.plotInfo.continuous.EEGDataPositions);
%                 newStimData = dataStreamHistory(max(indStim - handles.average.beforeStimSamples, 1): min(handles.average.afterStimSamples + indStim, lData), handles.plotInfo.continuous.STIM_HAPPENNING);
%                 indTimeInAv = max(handles.average.beforeStimSamples - indStim -1, 0) +(1: min(length(newData),size(triggerAvData,1)));
%                 triggerAvData(indTimeInAv,:) = triggerAvData(indTimeInAv,:) + newData/2; % add newData/2 to obtain average signal
%                 stimDataForAv(indTimeInAv,:) = max(triggerAvData(:)) * newStimData; %Increase amplitude to max of signal for visualization
%                 prevStimDataTime = stimDataTime;
%                 isNewTriggerAv = true;
%                 %Create a struct with information of each stimulation
%                 stimInfo.eachStim{stimInfo.nStims+1}.stimDataTime = stimDataTime;
%                 stimInfo.eachStim{stimInfo.nStims+1}.stimElectrodes = handles.stimElectrodes;
%                 %Count number of stimulations
%                 stimShamData = dataStreamHistory(indStim, handles.plotInfo.continuous.RANDOM_STIM);
%                 if stimShamData > 0.2
%                     % Stimulation due to sham detection - assumes that sham detection is always real-time (no next trigger sham)
%                     stimInfo.eachStim{stimInfo.nStims+1}.detectionType = 'Random';
%                     stimInfo.nShamStims = stimInfo.nShamStims + 1;
%                 else
%                     %if it is not SHAM stim - it assumes it comes from a detected event
%                     stimInfo.eachStim{stimInfo.nStims+1}.detectionType = 'DetEvent';
%                     stimInfo.nEventDetectedStims = stimInfo.nEventDetectedStims + 1;
%                 end
%                 stimInfo.nStims = stimInfo.nEventDetectedStims + stimInfo.nShamStims;
%             end
%         end
%     end

    function createTrialByTrialMatrixToSave(dataTrialByTrialHistory, handles)
        global dataAllDetStim;
        if isempty(dataAllDetStim)
            dataAllDetStim = struct('features',[],'thresholds',[],'nStims',[],'nDetStims',[],'nRandomStims',[],'nDetections',[],'nStimChannels',[],'nspTime',[]);
        end
        
        nStims = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.NUMBER_STIM); 
        nDetStims = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.NUMBER_DET_STIM); 
        nRandomStims = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.NUMBER_RANDOM_STIM); 
        nDetections = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.NUMBER_DETECTIONS); 
        nStimChannels = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.STIM_CHANNEL); 
        nspTime = dataTrialByTrialHistory(end, handles.plotInfo.trialbytrial.NSP_TIME);     %add also the NSP time 

        dataAllDetStim.nspTime = [dataAllDetStim.nspTime; nspTime];
        dataAllDetStim.nStims = [dataAllDetStim.nStims; nStims];
        dataAllDetStim.nDetStims = [dataAllDetStim.nDetStims; nDetStims];
        dataAllDetStim.nRandomStims = [dataAllDetStim.nRandomStims; nRandomStims];
        dataAllDetStim.nDetections = [dataAllDetStim.nDetections; nDetections];
        dataAllDetStim.nStimChannels = [dataAllDetStim.nStimChannels; nStimChannels];

    end
    
    function [isNewStimChannel, stimElectrodes] = updateStimChannel(handles)
        global dataStreamHistory;
        persistent prevStimChNumbers;
        if isempty(prevStimChNumbers)
            prevStimChNumbers = handles.stimElectrodes; %We are assuming consecutive stimulation channels!
        end
        isNewStimChannel = false;
        stimElectrodes = prevStimChNumbers;
        %disp(['Previous Channels: ',num2str(prevStimChNumbers)]);
        
        chNumbersData = dataStreamHistory(:,handles.plotInfo.trialbytrial.STIM_CHANNEL); % RIZ: different from state estimate! check!!
        indStimChNumber = find(chNumbersData(:,1),1); %only keep the first channel to stimulate stimulation in package (there might be more, but I would assume they will come in following iterations)
        newStimElectrodes = round(chNumbersData(indStimChNumber,:));
        
        if ~isempty(indStimChNumber) && (prevStimChNumbers(1) ~= newStimElectrodes(1) || prevStimChNumbers(2) ~= newStimElectrodes(2))
           % chNumberDataTime = dataStreamHistory(indStimChNumber, handles.plotInfo.NSP_TIME);
            stimElectrodes(1) = newStimElectrodes(1);
            stimElectrodes(2) = newStimElectrodes(2);
            sendNewChannelToStimulator(newStimElectrodes, handles);
            disp([' STIM Channels: ',num2str(newStimElectrodes)]);
            prevStimChNumbers(1) =  newStimElectrodes(1);
            prevStimChNumbers(2) =  newStimElectrodes(2);
            isNewStimChannel = true;
        end
    end

    function sendNewChannelToStimulator(newStimElectrodes, handles)
        if strcmpi(handles.mode,'Closed-Loop')~=0 && handles.controlCerestimFromHost == true && isfield(handles,'cerestim')
            disp(['Modifying Stimulation Electrodes to ' num2str(newStimElectrodes(1)),'-',num2str(newStimElectrodes(2))])
            res = changeChannelStimulationCereStim(handles.cerestim, newStimElectrodes(1), newStimElectrodes(2));
        end
    end

    
function txtDetectionRMSLower_Callback(hObject, eventdata, handles)
% hObject    handle to txtDetectionRMSLower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtDetectionRMSLower as text
%        str2double(get(hObject,'String')) returns contents of txtDetectionRMSLower as a double
        global sCoreParams;
        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
        paramStr = get(hObject,'UserData');
        sCoreParams.decoders.txDetector.txRMSLower = paramValue;
        handles.paramChanged = true;
        guidata(hObject, handles);
end

% ---


function txtDetectionSign_Callback(hObject, eventdata, handles)
% hObject    handle to txtDetectionSign (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtDetectionSign as text
%        str2double(get(hObject,'String')) returns contents of txtDetectionSign as a double
        global sCoreParams;
        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
        paramStr = get(hObject,'UserData');
        sCoreParams.decoders.txDetector.txSign = paramValue;
        handles.paramChanged = true;
        guidata(hObject, handles);

end


function txtNDetectionsReq_Callback(hObject, eventdata, handles)
% hObject    handle to txtNDetectionsReq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtNDetectionsReq as text
%        str2double(get(hObject,'String')) returns contents of txtNDetectionsReq as a double
        global sCoreParams;
        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
        paramStr = get(hObject,'UserData');
        sCoreParams.decoders.txDetector.nDetectionsRequested = paramValue;
        sCoreParams.decoders.txDetector.nDetectionsRequestedmSec = paramValue /sCoreParams.core.samplesPerStep;
        handles.paramChanged = true;
        guidata(hObject, handles);
end


% --- Executes on selection change in popFreq.
function popFreq_Callback(hObject, eventdata, handles)
% hObject    handle to popFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global sCoreParams;
    contents = cellstr(get(hObject,'String')); % returns popFreq contents as cell array
    freqBandName =contents{get(hObject,'Value')}; % returns selected item from popFreq
    variantConfig = handles.variant.variantConfig;
    [variantConfig, sCoreParams] = selectFrequencyBandConfig(freqBandName, variantConfig, sCoreParams);
    disp(['Selected frequency: ', freqBandName,' corresponds to variantConfig_FREQ_LOW = ', num2str(variantConfig.FREQ_LOW)])
    handles.variant.variantConfig = variantConfig;
    handles.sCoreParams = sCoreParams;
    handles.freqBandName = freqBandName;
    handles.nFreqs = sCoreParams.decoders.txDetector.nFreqs;
    handles.variantChanged = true;
    guidata(hObject, handles);
    disp(['Selected frequency: ', freqBandName,' corresponds to variantConfig_FREQ_LOW = ', num2str(variantConfig.FREQ_LOW)])
    if (sCoreParams.decoders.txDetector.nFreqs ~= handles.nFreqs)
        popFeature_Callback(handles.popFeature, eventdata, handles);
    end
end


% --- Executes on selection change in popFeature.
function popFeature_Callback(hObject, eventdata, handles)
% hObject    handle to popFeature (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global sCoreParams;
    contents = cellstr(get(hObject,'String')); % returns popFeature contents as cell array
    featureName =contents{get(hObject,'Value')}; % returns selected item from popFeature
    variantConfig = handles.variant.variantConfig;
    %sCoreParams = handles.sCoreParams;
    %Modify Variants based on selected features
    [variantConfig, sCoreParams] = selectFeatureConfig(featureName,variantConfig, sCoreParams);
    FlattenAndTune(sCoreParams, 'sCoreParams',NameTunableParams);
    handles.sCoreParams = sCoreParams;
    handles.paramChanged = true;
    disp(['Selected Feature: ', featureName,' corresponds to Feat=', num2str(variantConfig.WHICH_FEATURE), ' - BaselineFeat=',num2str(variantConfig.WHICH_FEATURE_BASELINE), ' - Detector=',num2str(variantConfig.WHICH_DETECTOR) ]);
    handles.variant.variantConfig = variantConfig;
    handles.variantChanged = true;
    handles.feature = featureName;
    guidata(hObject, handles);
    disp('Select channels/ pairs to use in detection')
    % Call also the selector for Detector to update it based on the selected feature
    popDetectorType_Callback(handles.popDetectorType, eventdata, handles);
    handles = guidata(handles.popDetectorType); %Get the handles back after they were modified
    updateDetVizChannelsList(hObject, handles);
end

% --- Executes on selection change in lstContact1.
function lstContact1_Callback(hObject, eventdata, handles)
% hObject    handle to lstContact1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        % RZ: I am harcodeing to which variable corresponds!!!
        global sCoreParams;
        contents = cellstr(get(hObject,'String'));  %returns lstContact1 contents as cell array
        selContactsStr = handles.channelInfo.contact1.Names(get(hObject,'Value'));    %returns selected item from NAMES of contact (regardles of what is shown on list)
        %selContactsStr = contents(get(hObject,'Value'));    %returns selected item from lstContact2
        for iCh=1:length(selContactsStr)
            vecContactsNum(iCh) = find(strcmp(selContactsStr{iCh}, sCoreParams.decoders.txDetector.channelNames));
        end
        %vecContactsNum = cellfun(@str2double, selContactsStr)';
        %paramStr = get(hObject,'UserData');
        sCoreParams.decoders.txDetector.channel1 = vecContactsNum;
        handles.paramChanged = true;
        guidata(hObject, handles);
        if (length(sCoreParams.decoders.txDetector.channel1) == length(sCoreParams.decoders.txDetector.channel2))        
            updateDetVizChannelsList(hObject, handles);
            handles.needsToReCompile = true; 
        end
end



% --- Executes on selection change in lstContact2.
function lstContact2_Callback(hObject, eventdata, handles)
% hObject    handle to lstContact2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global sCoreParams;
    contents = cellstr(get(hObject,'String'));  %returns lstContact2 contents as cell array
    selContactsStr = handles.channelInfo.contact2.Names(get(hObject,'Value'));     %returns selected item from NAMES of contact (regardles of what is shown on lstContact2)
%    selContactsStr = contents(get(hObject,'Value'));    %returns selected item from lstContact2
    for iCh=1:length(selContactsStr)
        vecContactsNum(iCh) = find(strcmp(selContactsStr{iCh}, sCoreParams.decoders.txDetector.channelNames));
    end
    % vecContactsNum = cellfun(@str2double, selContactsStr)';
    % paramStr = get(hObject,'UserData');
    sCoreParams.decoders.txDetector.channel2 = vecContactsNum;
    handles.paramChanged = true;
    guidata(hObject, handles);
    if (length(sCoreParams.decoders.txDetector.channel1) == length(sCoreParams.decoders.txDetector.channel2))
        updateDetVizChannelsList(hObject, handles);
        handles.needsToReCompile = true;
    end
end


% --- Executes on selection change in lstDetChannelIndexes.
function lstDetChannelIndexes_Callback(hObject, eventdata, handles)
% hObject    handle to lstDetChannelIndexes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global sCoreParams;
    contents = cellstr(get(hObject,'String'));  %returns lstContact2 contents as cell array
    selContactsStr = contents(get(hObject,'Value'));    %returns selected item from lstContact2
    vecContactsNum = get(hObject,'Value');
    %paramStr = get(hObject,'UserData');
    sCoreParams.decoders.txDetector.detectChannelInds = vecContactsNum;
    handles.paramChanged = true;
    handles.needsToReCompile = true;
    guidata(hObject, handles);
end


function updateDetVizChannelsList(hObject, handles)
%Update Detectable channels list to ALL possible combinations 
% using either channels as contact1- contct2
%or pairs of channels if Feature is coherence
%This function is called when contacts are selected or when Features combo changes
    global sCoreParams;
    %sCoreParams =  handles.sCoreParams;
    
    cont1 = sCoreParams.decoders.txDetector.channel1;
    cont2 = sCoreParams.decoders.txDetector.channel2;
    if (length(cont1) ~= length(cont2))
        disp('WARNING:: Number of selected Contacts must be the same!')
    end
    nSelChannels = length(cont1);
    nAllChannels = length(sCoreParams.decoders.txDetector.channelNames);
    sCoreParams.decoders.txDetector.nChannels = nSelChannels;
    strChannelVals = cell(1,nSelChannels);
    for iCh =1:nSelChannels
        strCont1 = sCoreParams.decoders.txDetector.channelNames{cont1(iCh)};
        strCont2 = sCoreParams.decoders.txDetector.channelNames{cont2(iCh)};
        strChannelVals{iCh} = [strCont1,'-',strCont2];
    end
    
    if strcmpi(handles.feature, 'COHERENCE') || strcmpi(handles.feature, 'CORRELATION')
        pairChannels = getPairsChannels(1:nSelChannels);
        nDetFeatures = size(pairChannels,1);
        vecStrDetChan = cell(1,nDetFeatures);
        if ~isempty(pairChannels)
            for iCh=1:nDetFeatures
                vecStrDetChan{iCh} = [strChannelVals{pairChannels(iCh,1)},'/',strChannelVals{pairChannels(iCh,2)}];
            end
        end
    else % For all other features is directly the bipolar channels
        nDetFeatures = nSelChannels;
        vecStrDetChan = strChannelVals;
    end
    sCoreParams.decoders.txDetector.nFeatures = sCoreParams.decoders.txDetector.nFreqs * nDetFeatures;
    sCoreParams.decoders.txDetector.nFeaturesUsedInDetection = sCoreParams.decoders.txDetector.nFeatures;
    sCoreParams.decoders.txDetector.detectChannelInds = 1:sCoreParams.decoders.txDetector.nFeatures;
    sCoreParams.decoders.txDetector.detectChannelMask = ones(1,sCoreParams.decoders.txDetector.nFeatures);
    vecIndFeatures = 1:sCoreParams.decoders.txDetector.nFeatures; % ALL are selected (out of the selected in sCoreParams.decoders.txDetector.channel1 / 2)

    if sCoreParams.decoders.txDetector.nFreqs>1
        allFreqVecStrDetChan=[];
        for iFreq=1:sCoreParams.decoders.txDetector.nFreqs
            allFreqVecStrDetChan=[allFreqVecStrDetChan;  strcat(vecStrDetChan(:), '_', num2str(iFreq))];
        end
    else
        allFreqVecStrDetChan=vecStrDetChan(:);
    end    
    
    %Update DETECTION List of Channels
    set(handles.lstDetChannelIndexes, 'String', allFreqVecStrDetChan(:));
    set(handles.lstDetChannelIndexes, 'Value', vecIndFeatures);
    sCoreParams.decoders.txDetector.detectChannelInds = vecIndFeatures; %We detect based on features (pairs or channels)

    %Update VISUALIZATION List of Channels
     %nFilteredChannels = sCoreParams.decoders.txDetector.nFilteredChannels;
    nFeatures = sCoreParams.decoders.txDetector.nFeaturesUsedInDetection; %handles.neuralModelParams.nEpochs * sCoreParams.decoders.txDetector.nFeatures; 
    allFreqVecStrVizChan = allFreqVecStrDetChan; %repmat(vecStrDetChan, nVizChannels/nChannels,1)'; %RIZ201711: it was trasposed in RIG version!
    vecIndVizFeatures = 1:nFeatures; % ALL are selected (out of the selected in sCoreParams.decoders.txDetector.channel1 / 2)
    
    set(handles.lstVizChannelIndexes, 'String', allFreqVecStrVizChan(:));
    set(handles.lstVizChannelIndexes, 'Value', vecIndVizFeatures);
    handles.vizualization.channelInds = 1: nSelChannels;
    handles.vizualization.featureInds = vecIndVizFeatures;

    % Update also sCorePArams to send ALL correspondig channels and feature
    sCoreParams.viz.channelInds = 1: nSelChannels; %viz.channelInds is always with respect to channels (selects EEG signal)
    sCoreParams.viz.channelNames = strChannelVals; %repmat(strChannelVals, nVizChannels/nChannels,1)';
    sCoreParams.viz.featureInds = vecIndVizFeatures;        %viz.featureInds could be pairs or channels
    sCoreParams.viz.featureNames = allFreqVecStrVizChan;
    sCoreParams = InitCoreParams_Dependent(sCoreParams);
    guidata(hObject, handles);
end


% --- Executes on selection change in lstVizChannelIndexes.
function lstVizChannelIndexes_Callback(hObject, eventdata, handles)
% hObject    handle to lstVizChannelIndexes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstVizChannelIndexes contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstVizChannelIndexes
    global sCoreParams;
    contents = cellstr(get(hObject,'String'));  %returns lstContact2 contents as cell array
    selFeatStr = contents(get(hObject,'Value'));    %returns selected item from lstContact2
    vecFeatIndexes = get(hObject,'Value');
    %paramStr = get(hObject,'UserData');
    %sCoreParams.viz.featureInds = vecContactsNum;   
    handles.vizualization.featureInds = vecFeatIndexes;

    chanInds=[];
    for iStr=1:length(selFeatStr)
        chInPair = strsplit([selFeatStr{iStr}],{'/'});
        for iCh=1:length(chInPair)
            chanInds = [chanInds, find(strcmpi(sCoreParams.viz.channelNames, chInPair{iCh}))];
        end
    end
    handles.vizualization.channelInds =  unique(chanInds);
    
    % Set to Visible=ON only those features and channels that are  selected    
    for iFeat=1:length(handles.featureTraces)
        if ismember(iFeat, vecFeatIndexes)
            set(handles.featureTraces(iFeat),'Visible','on');
        else
            set(handles.featureTraces(iFeat),'Visible','off');
        end
    end
    for iCh=1:length(handles.rawEEGTraces)% min(length(handles.rawEEGTraces),length(sCoreParams.viz.channelNames))
        if ismember(iCh, handles.vizualization.channelInds)
            set(handles.rawEEGTraces(iCh),'Visible','on');
        else
            set(handles.rawEEGTraces(iCh),'Visible','off');
        end
    end    %sCoreParams.viz.channelInds = unique(chanInds);
    for iCh=1:length(handles.triggerAveragedTraces)% min(length(handles.rawEEGTraces),length(sCoreParams.viz.channelNames))
        if ismember(iCh, handles.vizualization.channelInds)
            set(handles.triggerAveragedTraces(iCh),'Visible','on');
            set(handles.triggerAveragedDetSTIMTraces(iCh),'Visible','on');
            set(handles.triggerAveragedRandomSTIMTraces(iCh),'Visible','on');
        else
            set(handles.triggerAveragedTraces(iCh),'Visible','off');
            set(handles.triggerAveragedDetSTIMTraces(iCh),'Visible','off');
            set(handles.triggerAveragedRandomSTIMTraces(iCh),'Visible','off');
        end
    end 
    hObjectGUI = hObject.Parent;
    guidata(hObjectGUI, handles);
    popAveragedEEGPlot_Callback(handles.popAveragedEEGPlot, [], handles); % change also for averaged data

    %handles.paramChanged = true;
    %SetRealTimeValue(tg, paramStr, paramValue);
end



% --- Executes on mouse press over axes background.
function axFeaturesThresholds_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axFeaturesThresholds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject, 'YLim', [-inf, inf]);
end


% --- Executes on mouse press over axes background.
function axRawEEG_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axRawEEG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject, 'YLim', [-inf, inf]);
end


% --- Executes on mouse press over axes background.
function axTriggerAveraged_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axTriggerAveraged (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject, 'YLim', [-inf, inf]);
end

% --- Executes on mouse press over axes background.
function axTriggerAveragedDetSTIM_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axTriggerAveragedDetSTIM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject, 'YLim', [-inf, inf]);
end

% --- Executes on mouse press over axes background.
function axTriggerAveragedRandomSTIM_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axTriggerAveragedRandomSTIM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(hObject, 'YLim', [-inf, inf]);
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    try
        %On Closing Close ALSO connection to target and stop writer and save
        %data - if this was not done alreeady
        if strcmpi(get(handles.btnStart,'Enable'),'off') % if START button is NOT enabled is because we didn't press STOP
            disp(['Saving data first...'])
            btnStop_Callback(handles.btnStop, [], handles)
        else
            disp(['Data Saved already... '])
        end
        diary off; % close diary - command line data is saved NOW
        % Hint: delete(hObject) closes the figure
        disp(['... Exiting'])
        delete(hObject);
    catch ME
        disp(['Could not Close GUI or model properly! - ', ME.identifier]);
        delete(hObject);
    end
end


function txtBeforeStimSec_Callback(hObject, eventdata, handles)
% hObject    handle to txtBeforeStimSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtBeforeStimSec as text
%        str2double(get(hObject,'String')) returns contents of txtBeforeStimSec as a double
    global sCoreParams;
    %handles.average.beforeStimSamples = str2double(get(hObject,'String')) / sCoreParams.core.stepPeriod;    
    sCoreParams.viz.preTriggerSec = str2double(get(hObject,'String'));
    handles.average.beforeStimSec = sCoreParams.viz.preTriggerSec;
    handles.average.beforeStimSamples = sCoreParams.viz.preTriggerSec * sCoreParams.write.broadcastAvEEGSamp; % / (sCoreParams.core.stepPeriod * sCoreParams.write.averagedEEGDownSampling);
    handles.paramChanged = true;
    guidata(hObject, handles);
    set(handles.txtAfterStimSec,'String',num2str(sCoreParams.viz.DurationTriggerAvSec - str2double(get(handles.txtBeforeStimSec,'String')))); % FIX the after STIm value! -> it is always 1sec-before
    txtAfterStimSec_Callback(handles.txtAfterStimSec, eventdata, handles);

    handles.paramChanged = true;
    guidata(hObject, handles);
end

function txtAfterStimSec_Callback(hObject, eventdata, handles)
% hObject    handle to txtAfterStimSec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtAfterStimSec as text
%        str2double(get(hObject,'String')) returns contents of txtAfterStimSec as a double
%RIZ: changed to only update parameters but it is actually not possibile to edit
    % Check that total duration is <= sCoreParams.viz.DurationTriggerAvSec  (duration of sent averaged EEG) and change this object's value to stay within limits
    global sCoreParams;
    if (str2double(get(hObject,'String')) + str2double(get(handles.txtBeforeStimSec,'String'))) > sCoreParams.viz.DurationTriggerAvSec
        set(hObject,'String',num2str(sCoreParams.viz.DurationTriggerAvSec - str2double(get(handles.txtBeforeStimSec,'String'))));
    end
        
    %handles.average.afterStimSamples = str2double(get(hObject,'String')) / sCoreParams.core.stepPeriod;    
    sCoreParams.viz.postTriggerSec = str2double(get(hObject,'String'));
    handles.average.afterStimSec = sCoreParams.viz.postTriggerSec;
    handles.average.afterStimSamples = sCoreParams.viz.postTriggerSec  * sCoreParams.write.broadcastAvEEGSamp;%/ (sCoreParams.core.stepPeriod * sCoreParams.write.averagedEEGDownSampling);
    handles.paramChanged = true;
    guidata(hObject, handles);
end


% --- Executes on button press in chkFixThreshold.
function chkFixThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to chkFixThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkFixThreshold
    global sCoreParams;
    if (get(hObject,'Value') == get(hObject,'Max'))
        sCoreParams.Features.Baseline.initialThresholdValue = str2double(get(handles.txtInitialThreshold,'String'));
        sCoreParams.Features.Baseline.weightPreviousThreshold = 1;
        set(handles.txtPrevThWeight,'String','1');
        handles.paramChanged = true;
        guidata(hObject, handles);
    else
        sCoreParams.Features.Baseline.weightPreviousThreshold = str2double(get(handles.txtPrevThWeight,'String'));
        handles.paramChanged = true;
        guidata(hObject, handles);
    end
end


function txtInitialThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to txtInitialThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtInitialThreshold as text
%        str2double(get(hObject,'String')) returns contents of txtInitialThreshold as a double
    global sCoreParams;
    sCoreParams.Features.Baseline.initialThresholdValue = str2double(get(hObject,'String'));
    handles.paramChanged = true;
    guidata(hObject, handles);
end



% --- Executes on button press in btnAllDetectedCh.
function btnAllDetectedCh_Callback(hObject, eventdata, handles)
% hObject    handle to btnAllDetectedCh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnAllDetectedCh

% Select in Visualization Channels/Pairs the same Channels/Pairs selected to Detect
    indSelChDetection = get(handles.lstDetChannelIndexes,'Value');
    set(handles.lstVizChannelIndexes,'Value',indSelChDetection);
    lstVizChannelIndexes_Callback(handles.lstVizChannelIndexes, eventdata, handles);
end



function txtPrevThWeight_Callback(hObject, eventdata, handles)
% hObject    handle to txtPrevThWeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtPrevThWeight as text
%        str2double(get(hObject,'String')) returns contents of txtPrevThWeight as a double
    global sCoreParams;
    sCoreParams.Features.Baseline.weightPreviousThreshold = str2double(get(hObject,'String'));
    handles.paramChanged = true;
    guidata(hObject, handles);
end


% --- Executes on selection change in popDetectIfAnyAll.
function popDetectIfAnyAll_Callback(hObject, eventdata, handles)
% hObject    handle to popDetectIfAnyAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global sCoreParams;
    contents = cellstr(get(hObject,'String'));
    selDetAnyAll = contents{get(hObject,'Value')};
    switch upper(selDetAnyAll)
        case 'ANY'
            sCoreParams.decoders.txDetector.anyAll = 0; % 0 means ANY
        case 'ALL'
            sCoreParams.decoders.txDetector.anyAll = 1; % 1 means ALL
        otherwise
            disp(['No Valid DETECTION TYPE specified (Options: ANY/ALL). Using default: ', num2str(sCoreParams.decoders.txDetector.anyAll)]);
    end
    handles.paramChanged = true;
    guidata(hObject, handles);
end

% --- Executes on selection change in popStimulationType.
function popStimulationType_Callback(hObject, eventdata, handles)
% hObject    handle to popStimulationType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popStimulationType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popStimulationType
    global sCoreParams;
    contents = cellstr(get(hObject,'String')); % returns popFeature contents as cell array
    stimulationType =contents{get(hObject,'Value')}; % returns selected item from popFeature
    variantConfig = handles.variant.variantConfig;
    contents = cellstr(get(handles.popDetectorType,'String')); % returns popFeature contents as cell array
    detectorType =contents{get(handles.popDetectorType,'Value')}; % returns selected item from popFeature
   
    [variantConfig] = selectWhenToStimulate(stimulationType, variantConfig, detectorType);
    disp(['Selected STIMULATION TYPE: ', stimulationType,' corresponds to variantConfig_STIMULATION_TYPE = ', num2str(variantConfig.STIMULATION_TYPE)])
    handles.variant.variantConfig = variantConfig;
    handles.stimulationType = stimulationType;
    handles.variantChanged = true;
    guidata(hObject, handles);
end


function txtStimulationTriggerChannel_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimulationTriggerChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        global sCoreParams;
    paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
    paramStr = get(hObject,'UserData');
    sCoreParams.decoders.txDetector.stimTriggerChannel = paramValue;
    handles.paramChanged = true;
    guidata(hObject, handles);

end


% --- Executes on selection change in popDetectorType.
function popDetectorType_Callback(hObject, eventdata, handles)
% hObject    handle to popDetectorType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popDetectorType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popDetectorType
    contents = cellstr(get(hObject,'String')); % returns popFeature contents as cell array
    detectorName =contents{get(hObject,'Value')}; % returns selected item from popFeature
    variantConfig = handles.variant.variantConfig;
    contents = cellstr(get(handles.popFeature,'String')); % returns popFeature contents as cell array
    featureName =contents{get(handles.popFeature,'Value')}; % returns selected item from popFeature
    
    %Modify Variants based on selected Detector type and features
    [variantConfig, controlCerestimFromHost] = selectDetectorConfig(detectorName, variantConfig, featureName);
    disp(['Selected Detector Type: ', detectorName,' corresponds to configDet=',num2str(variantConfig.WHICH_DETECTOR), ' - Feature=',featureName,' - ', num2str(variantConfig.WHICH_FEATURE), ' - BaselineFeat=',num2str(variantConfig.WHICH_FEATURE_BASELINE) ]);
    handles.variant.variantConfig = variantConfig;
    handles.variantChanged = true;
    handles.feature = featureName;
    handles.detectorType = detectorName;
    handles.controlCerestimFromHost = controlCerestimFromHost;
    guidata(hObject, handles);
    % Call also stimulator type select to modify stimulator output type for the different detectors
    popStimulationType_Callback(handles.popStimulationType, eventdata, handles);
    handles = guidata(handles.popStimulationType); %Get the handles back after they were modified
end


function txtDetectionRMSUpper_Callback(hObject, eventdata, handles)
% hObject    handle to txtDetectionRMSUpper (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtDetectionRMSUpper as text
%        str2double(get(hObject,'String')) returns contents of txtDetectionRMSUpper as a double
    global sCoreParams;
        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
        paramStr = get(hObject,'UserData');
        sCoreParams.decoders.txDetector.txRMS = paramValue;
        handles.paramChanged = true;
        guidata(hObject, handles);
end


% --- Executes on selection change in popTriggerType.
function popTriggerType_Callback(hObject, eventdata, handles)
% hObject    handle to popTriggerType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popTriggerType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popTriggerType
    contents = cellstr(get(hObject,'String')); % returns popFreq contents as cell array
    triggerType =contents{get(hObject,'Value')}; % returns selected item from popFreq
    variantConfig = handles.variant.variantConfig;
    [variantConfig] = selectTriggerTypeConfig(triggerType, variantConfig);
    disp(['Selected frequency: ', triggerType,' corresponds to variantConfig_TRIGGER_TYPE = ', num2str(variantConfig.TRIGGER_TYPE)])
    handles.variant.variantConfig = variantConfig;
    handles.triggerType = triggerType;
    handles.variantChanged = true;
    guidata(hObject, handles);

end



function txtStimElectrode1_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimElectrode1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimElectrode1 as text
%        str2double(get(hObject,'String')) returns contents of txtStimElectrode1 as a double
end



function txtStimElectrode2_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimElectrode2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimElectrode2 as text
%        str2double(get(hObject,'String')) returns contents of txtStimElectrode2 as a double
end



function txtRandomStimulation_Callback(hObject, eventdata, handles)
% hObject    handle to txtRandomStimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtRandomStimulation as text
%        str2double(get(hObject,'String')) returns contents of txtRandomStimulation as a double
    global sCoreParams;
    paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
    paramStr = get(hObject,'UserData');
    sCoreParams.decoders.chanceDetector.randStimEventsPerSec = paramValue;
    if paramValue>0 && sCoreParams.decoders.chanceDetector.useChanceDetector == 0
        sCoreParams.decoders.chanceDetector.useChanceDetector = 1;
    end
    handles.paramChanged = true;
    guidata(hObject, handles);
end


function txtProbaNoStim_Callback(hObject, eventdata, handles)
% hObject    handle to txtProbaNoStim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtProbaNoStim as text
%        str2double(get(hObject,'String')) returns contents of txtProbaNoStim as a double
    global sCoreParams;
    paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
    paramStr = get(hObject,'UserData');
    sCoreParams.decoders.txDetector.ProbabilityOfStim = paramValue;
    handles.paramChanged = true;
    guidata(hObject, handles);
end


% --- Executes on button press in btnSendParams.
function btnSendParams_Callback(hObject, eventdata, handles)
% hObject    handle to btnSendParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    updateTargetParams(hObject, handles);
end


% --- Executes on button press in btnCompile.
function btnCompile_Callback(hObject, eventdata, handles)
% hObject    handle to btnCompile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
       %Assign changed variables to workspace
        hObjectGUI = hObject.Parent;
        handles.needsToReCompile = true; % force it to compile
        handles = guidata(hObjectGUI);
        configureModelParams(hObjectGUI, handles);

end


% --- Executes on selection change in popMontage.
function popMontage_Callback(hObject, eventdata, handles)
% hObject    handle to popMontage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popMontage contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popMontage

    contents = cellstr(get(hObject,'String')); % returns popFeature contents as cell array
    selMontage =contents{get(hObject,'Value')}; % returns selected item from popFeature
    variantConfig = handles.variant.variantConfig;
    [variantConfig] = selectMontage(selMontage, variantConfig);
    disp(['Selected MONTAGE: ', selMontage,' corresponds to variantConfig_IS_BIPOLAR = ', num2str(variantConfig.IS_BIPOLAR)])
    handles.variant.variantConfig = variantConfig;
    handles.selMontage = selMontage;
    handles.variantChanged = true;
    guidata(hObject, handles);
    
end



function txtSmoothDuration_Callback(hObject, eventdata, handles)
% hObject    handle to txtSmoothDuration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSmoothDuration as text
%        str2double(get(hObject,'String')) returns contents of txtSmoothDuration as a double
    global sCoreParams;
        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
    %    paramStr = get(hObject,'UserData');
        sCoreParams.Features.Data.SmoothWindowsDurationSamples = paramValue;
        handles.paramChanged = true;
        handles.needsToReCompile = true; % added force need to recompile -RIZ: it should not be necessary, but somehow it does not work otherwise. Need to see why!
        guidata(hObject, handles);
end


function txtStimAfterDelay_Callback(hObject, eventdata, handles)
% hObject    handle to txtStimAfterDelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtStimAfterDelay as text
%        str2double(get(hObject,'String')) returns contents of txtStimAfterDelay as a double
    global sCoreParams;
        paramValue = str2double(get(hObject,'String')); % returns contents of txtContact1 as a double
       % paramStr = get(hObject,'UserData');
        sCoreParams.stimulator.stimAfterDelaySec = paramValue*sCoreParams.core.stepPeriod;
        sCoreParams.stimulator.stimAfterDelaySteps = paramValue;
        handles.paramChanged = true;
        handles.needsToReCompile = true; % added force need to recompile -RIZ: it should not be necessary, but somehow it does not work otherwise. Need to see why!
        guidata(hObject, handles);

end


% --- Executes on selection change in popChannelDisplay.
function popChannelDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to popChannelDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popChannelDisplay contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popChannelDisplay
% How to show the list of channels
    contents = cellstr(get(hObject,'String'));
    selStrValue = contents{get(hObject,'Value')};
    switch upper(selStrValue)
        case 'NAMES'
            set(handles.lstContact1,'String',handles.channelInfo.contact1.Names);
            set(handles.lstContact2,'String',handles.channelInfo.contact2.Names);
            
        case 'NUMBERS'
            set(handles.lstContact1,'String',handles.channelInfo.contact1.Numbers);
            set(handles.lstContact2,'String',handles.channelInfo.contact2.Numbers);
            
        case 'NSP:NUMBERS'
            set(handles.lstContact1,'String',handles.channelInfo.contact1.NSP_Numbers);
            set(handles.lstContact2,'String',handles.channelInfo.contact2.NSP_Numbers);
            
        case 'NSP:NAMES'
            set(handles.lstContact1,'String',handles.channelInfo.contact1.NSP_Names);
            set(handles.lstContact2,'String',handles.channelInfo.contact2.NSP_Names);
            
        otherwise % Default is Names
            set(handles.lstContact1,'String',handles.channelInfo.contact1.Names);
            set(handles.lstContact2,'String',handles.channelInfo.contact2.Names);
    end
    guidata(hObject, handles);
end


% --- Executes on selection change in popAveragedEEGPlot.
function popAveragedEEGPlot_Callback(hObject, eventdata, handles)
% hObject    handle to popAveragedEEGPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popAveragedEEGPlot contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popAveragedEEGPlot
        global sCoreParams;
    contents = cellstr(get(hObject,'String'));
    selStrValue = contents{get(hObject,'Value')};
    % Turn everything OFF - Then Turn ON only the one we want
    set(handles.axTriggerAveraged,'Visible','off');
    set(handles.axTriggerAveragedDetSTIM,'Visible','off');
    set(handles.axTriggerAveragedRandomSTIM,'Visible','off');
    for iCh=1:length(handles.triggerAveragedDetSTIMTraces)% Also check which channels should be visible
        set(handles.triggerAveragedTraces(iCh),'Visible','off');
        set(handles.triggerAveragedDetSTIMTraces(iCh),'Visible','off');
        set(handles.triggerAveragedRandomSTIMTraces(iCh),'Visible','off');
    end
    set(handles.triggerAveragedStim,'Visible','off');
    set(handles.triggerAveragedDetSTIMStim,'Visible','off');
    set(handles.triggerAveragedRandomSTIMStim,'Visible','off');
    % Select WHICH Averaged plot to show
    contents = cellstr(get(handles.lstVizChannelIndexes,'String'));  %returns handles.lstVizChannelIndexes contents as cell array
    selFeatStr = contents(get(handles.lstVizChannelIndexes,'Value'));    %returns selected item from handles.lstVizChannelIndexes
    chanInds=[];
    for iStr=1:length(selFeatStr)
        chInPair = strsplit([selFeatStr{iStr}],{'/'});
        for iCh=1:length(chInPair)
            chanInds = [chanInds, find(strcmpi(sCoreParams.viz.channelNames, chInPair{iCh}))];
        end
    end
    handles.vizualization.channelInds =  unique(chanInds);
    
    switch upper(selStrValue)
        case 'ALLSTIM'
            set(handles.axTriggerAveraged,'Visible','on');
            for iCh=1:length(handles.triggerAveragedTraces)% Also check which channels should be visible
                if ismember(iCh, handles.vizualization.channelInds)
                    set(handles.triggerAveragedTraces(iCh),'Visible','on');
                end
            end
            set(handles.triggerAveragedStim,'Visible','on');
        case 'DETECTED'
            set(handles.axTriggerAveragedDetSTIM,'Visible','on');
            for iCh=1:length(handles.triggerAveragedDetSTIMTraces)% Also check which channels should be visible
                if ismember(iCh, handles.vizualization.channelInds)
                    set(handles.triggerAveragedDetSTIMTraces(iCh),'Visible','on');
                end
            end
            set(handles.triggerAveragedDetSTIMStim,'Visible','on');
        case 'RANDOM'
            set(handles.axTriggerAveragedRandomSTIM,'Visible','on');
            for iCh=1:length(handles.triggerAveragedRandomSTIMTraces)% Also check which channels should be visible
                if ismember(iCh, handles.vizualization.channelInds)
                    set(handles.triggerAveragedRandomSTIMTraces(iCh),'Visible','on');
                end
            end
            set(handles.triggerAveragedRandomSTIMStim,'Visible','on');
        otherwise % Default is All STIM visible
            set(handles.axTriggerAveraged,'Visible','on');
    end
    hObjectGUI = hObject.Parent;
    guidata(hObjectGUI, handles);
end
