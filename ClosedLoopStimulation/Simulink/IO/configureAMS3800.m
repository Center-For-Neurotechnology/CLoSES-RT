function [my3800, IdxStatus, onValue, offValue] = configureAMS3800()
% code is taken from Angelique's Closed Loop script for NHPs
% Import AMS3800 interfacedata 

%% Create an instrument object
%AM = NET.addAssembly(['C:\Users\Scraps\Documents\MATLAB\AMS3800\libraries\AMS3800Interface_NET.dll']); - do we need this??
import AMS3800Interface_NET.*
my3800 = AMS3800Interface_NET.Ams_3800;

connected=my3800.isConnected()
if ~connected reply=my3800.getInterface(); end
%check if connected
connected=my3800.isConnected()

if connected
    %% Set the stimulation to the right settings (from Angelique's closedLoopcodeNHPs)
    my3800.SetListValue( 0, AMS3800Interface_NET.IndexListControls.IdxGlobalEnable, AMS3800Interface_NET.GlobalEnable.Enabled.int32);
    % %     'channel turned on'
    PulsePeriod=1000*(1/160);
    PulseAmp=0.04;
    TrainWid=1;
    my3800.SetTimeValue(0, IndexTimeControls.IdxTrainDelay, 0);
    my3800.SetTimeValue(0, IndexTimeControls.IdxTrainWidth, TrainWid*1000);
    my3800.SetTimeValue(0, IndexTimeControls.IdxTrainPeriod, 10000);
    my3800.SetTimeValue(0, IndexTimeControls.IdxPulsePeriod, PulsePeriod); %In milliseconds
    my3800.SetTimeValue(0, IndexTimeControls.IdxPulseWidth, 0.09);
    my3800.SetTimeValue(0, IndexTimeControls.IdxPulseInterphase, 0.050);
    my3800.SetAmpValue(0, IndexAmpControls.IdxPulse1, -PulseAmp*1000); %The idea is that the conversion is 1mA/V, leading to 1000 mV is 1 V is 1 mA
    my3800.SetAmpValue(0, IndexAmpControls.IdxPulse2, PulseAmp*1000);
    %         my3800.SetAmpValue(0, IndexAmpControls.IdxPulse1, -0.5*10000);
    %         my3800.SetAmpValue(0, IndexAmpControls.IdxPulse2, 0.5*10000);
else
    disp('ERROR: AMS3800 not connected')
end
    

%% output also the on/of idx values needed to turn stim on/off
IdxStatus = AMS3800Interface_NET.IndexListControls.IdxStatus;
onValue = AMS3800Interface_NET.Status.ChOn.int32;
offValue = AMS3800Interface_NET.Status.ChOff.int32;
