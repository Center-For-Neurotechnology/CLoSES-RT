function socket = InitUDPsender(localIP,localPort,remoteIP,remotePort)

socket = pnet('udpsocket',localPort,localIP);
pnet(socket,'udpconnect',remoteIP,remotePort);