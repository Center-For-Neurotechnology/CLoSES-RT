function StartWriter()
if (bdIsLoaded('ReceiveWrite') == 0) % Load if it was not loaded
    load_system('ReceiveWrite');
end
set_param('ReceiveWrite','simulationcommand','stop'); %First stop - just in case it was running
set_param('ReceiveWrite','simulationcommand','start');
