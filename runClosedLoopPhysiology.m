function runClosedLoopPhysiology(patientNAME, deciderDIR)

if ~exist('deciderDIR','var'), deciderDIR = 'D:\DeciderData'; end
if ~exist('patientNAME','var'), patientNAME = 'testCLoSES-RT'; end

%% Add to Path
addpath(genpath('ClosedLoopStimulation'))


%% RUN Closed-Loop GUI

deciderPatientDir = [deciderDIR, filesep, patientNAME];
GUIClosedLoopConsole('PatientName', patientNAME, 'DirResults', deciderPatientDir)

