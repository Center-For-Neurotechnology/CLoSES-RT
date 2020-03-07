try 
tg = xpctarget.xpc('xCoreTarget');
catch
setxpcenv('USBSupport','off')
setxpcenv('ShowHardware','off')
setxpcenv('MulticoreSupport','on')
xpcexplr
uiwait(msgbox('Boot The Target'))
tg = xpctarget.xpc('xCoreTarget');
end