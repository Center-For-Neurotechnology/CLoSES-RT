function varargout = InitDialogfig(varargin)
% INITDIALOGFIG MATLAB code for InitDialogfig.fig
%      INITDIALOGFIG by itself, creates a new INITDIALOGFIG or raises the
%      existing singleton*.
%
%      H = INITDIALOGFIG returns the handle to a new INITDIALOGFIG or the handle to
%      the existing singleton*.
%
%      INITDIALOGFIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INITDIALOGFIG.M with the given input arguments.
%
%      INITDIALOGFIG('Property','Value',...) creates a new INITDIALOGFIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before InitDialogfig_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to InitDialogfig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help InitDialogfig

% Last Modified by GUIDE v2.5 02-May-2017 15:27:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @InitDialogfig_OpeningFcn, ...
                   'gui_OutputFcn',  @InitDialogfig_OutputFcn, ...
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
end

% --- Executes just before InitDialogfig is made visible.
function InitDialogfig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to InitDialogfig (see VARARGIN)

    % Choose default command line output for InitDialogfig
    handles.output = 'No';
    %handles.txtModelFileName = '';
    handles.experimentType = 'CONTINUOUS';
    %handles.txtConfigFileName = '';
    % Update handles structure
    guidata(hObject, handles);

    % Insert custom Title and Text if specified by the user
    % Hint: when choosing keywords, be sure they are not easily confused 
    % with existing figure properties.  See the output of set(figure) for
    % a list of figure properties.
    if(nargin > 3)
        for index = 1:2:(nargin-3),
            if nargin-3==index, break, end
            switch lower(varargin{index})
             case 'title'
              set(hObject, 'Name', varargin{index+1});
             case 'string'
              set(handles.text1, 'String', varargin{index+1});
            end
        end
    end

    % Determine the position of the dialog - centered on the callback figure
    % if available, else, centered on the screen
    FigPos=get(0,'DefaultFigurePosition');
    OldUnits = get(hObject, 'Units');
    set(hObject, 'Units', 'pixels');
    OldPos = get(hObject,'Position');
    FigWidth = OldPos(3);
    FigHeight = OldPos(4);
    if isempty(gcbf)
        ScreenUnits=get(0,'Units');
        set(0,'Units','pixels');
        ScreenSize=get(0,'ScreenSize');
        set(0,'Units',ScreenUnits);

        FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
        FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
    else
        GCBFOldUnits = get(gcbf,'Units');
        set(gcbf,'Units','pixels');
        GCBFPos = get(gcbf,'Position');
        set(gcbf,'Units',GCBFOldUnits);
        FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
                       (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
    end
    FigPos(3:4)=[FigWidth FigHeight];
    set(hObject, 'Position', FigPos);
    set(hObject, 'Units', OldUnits);

    % Show a question icon from dialogicons.mat - variables questIconData
    % and questIconMap
%     load dialogicons.mat
% 
%     IconData=questIconData;
%     questIconMap(256,:) = get(handles.figure1, 'Color');
%     IconCMap=questIconMap;
% 
%     Img=image(IconData, 'Parent', handles.axes1);
%     set(handles.figure1, 'Colormap', IconCMap);
% 
%      set(handles.axes1, ...
%          'Visible', 'off', ...
%          'YDir'   , 'reverse'       , ...
%          'XLim'   , get(Img,'XData'), ...
%          'YLim'   , get(Img,'YData')  ...
%          );

    % Make the GUI modal
    set(handles.figure1,'WindowStyle','modal')

    % UIWAIT makes InitDialogfig wait for user response (see UIRESUME)
    uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = InitDialogfig_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    if ~isempty(handles)
        varargout{1} = handles.output;
        varargout{2} = get(handles.txtModelFileName,'String');
        varargout{3} = handles.experimentType; %MSIT or ECR or continuous
        varargout{4} = get(handles.txtConfigFileName,'String');
        varargout{5} = get(handles.txtSimulationFileName,'String');
        % The figure can be deleted now
        delete(handles.figure1);
    else
        for iVar=1:nargout
            varargout{iVar} = [];
        end
    end
end

% --- Executes on button press in btnSimulation.
function btnSimulation_Callback(hObject, eventdata, handles)
    handles.output = 'Simulation'; %get(hObject,'String');
    disp('Starting in Simulation Mode')
    % Update handles structure
    guidata(hObject, handles);

    % Use UIRESUME instead of delete because the OutputFcn needs
    % to get the updated handles structure.
    uiresume(handles.figure1);
end

% --- Executes on button press in btnClosedLoop.
function btnClosedLoop_Callback(hObject, eventdata, handles)
    handles.output = 'Closed-Loop'; %get(hObject,'String');
    disp('Starting Closed Loop Stimulation')
    
    % Update handles structure
    guidata(hObject, handles);
    
    % Use UIRESUME instead of delete because the OutputFcn needs
    % to get the updated handles structure.
    uiresume(handles.figure1);
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
    handles.output = 'No';
    delete(hObject);

%     if isequal(get(hObject, 'waitstatus'), 'waiting')
%         % The GUI is still in UIWAIT, us UIRESUME
%         uiresume(hObject);
%     else
%         % The GUI is no longer waiting, just close it
%         delete(hObject);
%     end
end

% --- Executes on key press over figure1 with no controls selected.
function figure1_KeyPressFcn(hObject, eventdata, handles)
    % Check for "enter" or "escape"
    if isequal(get(hObject,'CurrentKey'),'escape')
        % User said no by hitting escape
        handles.output = 'No';
        
        % Update handles structure
        guidata(hObject, handles);
        
        uiresume(handles.figure1);
    end
    
    if isequal(get(hObject,'CurrentKey'),'s') || isequal(get(hObject,'CurrentKey'),'S')
        % User said SIMULATION by hitting s or S
        handles.output = 'Simulation';
        % Update handles structure
        guidata(hObject, handles);
        %Go back to main figure
        uiresume(handles.figure1);
    end
    
    if isequal(get(hObject,'CurrentKey'),'c') || isequal(get(hObject,'CurrentKey'),'C') || isequal(get(hObject,'CurrentKey'),'l') || isequal(get(hObject,'CurrentKey'),'L')
        % User said CLOSED-LOOP by hitting c or C or l or L
        handles.output = 'Closed-Loop';
        % Update handles structure
        guidata(hObject, handles);
        %Go back to main figure
        uiresume(handles.figure1);
    end
    
    if isequal(get(hObject,'CurrentKey'),'return')
        uiresume(handles.figure1);
    end
end


% --- Executes on button press in btnLoadModel.
function btnLoadModel_Callback(hObject, eventdata, handles)
% hObject    handle to btnLoadModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [filename, pathname] = uigetfile({'*.dlm';'*.slx'},'Select Compiled or Simulink Model to Load');
    if (length(filename)>1)
        modelFileName = [pathname filename(1:end-4)]; %to remove extension!
        set(handles.txtModelFileName, 'String', modelFileName);
        guidata(hObject, handles);
    end
end

% --- Executes on selection change in popExperType.
function popExperType_Callback(hObject, eventdata, handles)
% hObject    handle to popExperType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    contents = cellstr(get(hObject,'String')); %returns popExperType contents as cell array
    handles.experimentType = contents{get(hObject,'Value')}; % returns selected item from popExperType
    guidata(hObject, handles);
end
   

% --- Executes during object creation, after setting all properties.
function popExperType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popExperType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function txtConfigFileName_Callback(hObject, eventdata, handles)
% hObject    handle to txtConfigFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtConfigFileName as text
%        str2double(get(hObject,'String')) returns contents of txtConfigFileName as a double
    handles.txtConfigFileName = get(hObject,'String');
end

% --- Executes during object creation, after setting all properties.
function txtConfigFileName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtConfigFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in btnConfigFile.
function btnConfigFile_Callback(hObject, eventdata, handles)
% hObject    handle to btnConfigFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [filename, pathname] = uigetfile({'*.m';'*.txt'},'Select Configuration File (configFilePATIENTNAME.m)');
    if (length(filename)>1)
        configFileName = [pathname, filename];
        %set(handles.txtConfigFileName, 'String', configFileName);
        %cFileName = strsplit(filename,'.');
        set(handles.txtConfigFileName, 'String', configFileName);
        guidata(hObject, handles);
    end

end



function txtModelFileName_Callback(hObject, eventdata, handles)
% hObject    handle to txtModelFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtModelFileName as text
%        str2double(get(hObject,'String')) returns contents of txtModelFileName as a double
%    handles.txtModelFileName = get(hObject,'String');

end


% --- Executes on button press in btnNHP.
function btnNHP_Callback(hObject, eventdata, handles)
% hObject    handle to btnNHP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.output = get(hObject,'String');
    handles.experimentType = get(hObject,'String');

    disp('Starting in NHPs Mode - using Plexon')
    % Update handles structure
    guidata(hObject, handles);

    % Use UIRESUME instead of delete because the OutputFcn needs
    % to get the updated handles structure.
    uiresume(handles.figure1);

end



function txtSimulationFileName_Callback(hObject, eventdata, handles)
% hObject    handle to txtSimulationFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSimulationFileName as text
%        str2double(get(hObject,'String')) returns contents of txtSimulationFileName as a double
    handles.txtSimulationFileName = get(hObject,'String');
end

% --- Executes during object creation, after setting all properties.
function txtSimulationFileName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSimulationFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in btnSimulationFile.
function btnSimulationFile_Callback(hObject, eventdata, handles)
% hObject    handle to btnSimulationFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    [filename, pathname] = uigetfile({'*.mat'},'Select Simulation File (simDataExample1.mat)');
    if (length(filename)>1)
        simulationFileName = [pathname, filename];
        set(handles.txtSimulationFileName, 'String', simulationFileName);
        guidata(hObject, handles);
    end
end
