function [cerestim, res] = initializeCereStim(freq, dur, amplitude,electrode1,electrode2)

if ~exist('electrode1','var') ||isempty(electrode1)
    electrode1=1;
end
if ~exist('electrode2','var') ||isempty(electrode2)
    electrode2=2;
end

res=[];
try
    cerestim = BStimulator();
    res = connect(cerestim);    
    
    npulse = floor(freq.*dur/1000);
    res = configureStimulusPattern(cerestim, electrode1, 'AF', npulse, amplitude, amplitude, 90, 90, freq, 53);
    res = configureStimulusPattern(cerestim, electrode2, 'CF', npulse, amplitude, amplitude, 90, 90, freq, 53);
    res = cerestim.triggerStimulus('rising');
    res = cerestim.readSequenceStatus();
    disp(['Cerestim status: ',num2str(res)])
    
    
catch
    disp('Can''t connect to cerestim - Status:',num2str(res),'!!')
    res =-1;
    cerestim=[];
end