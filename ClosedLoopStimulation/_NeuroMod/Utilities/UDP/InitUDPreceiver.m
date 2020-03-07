function socket = InitUDPreceiver(localIP,localPort,rbufSizeMB)

if (exist('rbufSizeMB','var'))
   % specify size of receive buffer in MB, ie 64  for 64MB buf
  socket = pnet('udplargesocket',localPort,localIP,rbufSizeMB);
else
  socket = pnet('udpsocket',localPort,localIP);
end