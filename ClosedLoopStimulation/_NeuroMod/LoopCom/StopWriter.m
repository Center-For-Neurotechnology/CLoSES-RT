function StopWriter()
try
    if (bdIsLoaded('ReceiveWrite') == 1) % Only close it if it is loaded
        set_param('ReceiveWrite','simulationcommand','stop');
        close_system('ReceiveWrite');
    end
catch ME
    disp(['Could NOT STOP Writter - Data might be lost! - ', ME.identifier])
end
