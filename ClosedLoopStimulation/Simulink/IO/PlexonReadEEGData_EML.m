function [EEGData, NSPTime, plexonID]  = PlexonReadEEGData_EML(plexonID)
%Reads data from plexon usind provided identifier 
% (Plexon system must be initiliazed before using plexonID = PL_InitClient(0);

%if server was not initilized
EEGData =[];
NSPTime = 0;
if plexonID <=0
    %disp('Error: PLEXON server not initilized! Run: sCoreParams = InitCoreParamsNHP(sCoreParams); ')
    disp('PLEXON server not initilized! Initilizing - plexonID = PL_InitClient(0); ')
    plexonID =initializePlexon();
end
if plexonID >0 % Check again to make sure it is connected
    [EEGData, NSPTime] = readPlexon(plexonID);
end
%remember to close plexon server when we are done: PL_Close(plexonID);

