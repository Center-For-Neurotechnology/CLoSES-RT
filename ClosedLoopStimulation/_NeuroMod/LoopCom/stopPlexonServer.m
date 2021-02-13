function stopPlexonServer(plexonInfo)
%Stop Plexon and Stimulator 

% For plexon, we had to close out the interface. Otherwise, it'll do weird things with the systems.
% findobj();
% my3800.closeInterface(); % RIZ: HOW DO I FIND IT?!?!?

% call PL_Close(s) to close the connection with the Plexon server
PL_Close(plexonInfo.plexonID);

