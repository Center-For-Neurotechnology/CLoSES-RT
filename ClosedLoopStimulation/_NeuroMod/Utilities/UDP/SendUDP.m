function SendUDP(socket,data)

pnet(socket,'write',data,'intel');
pnet(socket,'writepacket');