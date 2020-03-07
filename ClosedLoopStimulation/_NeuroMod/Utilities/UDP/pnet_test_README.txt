== Notes on testing pnet ==

This describes a simple test of pnet, making use of the InitUDPsender/receiver
and Send/ReceiveUDP functions, which use pnet, to send/receive a small amount
of data locally (not between machines).

You will need two instances of matlab to run this test, open both and goto
the Utilities directory, which has our functions and also pnet, and type
this to setup the paths:

>> addpath(genpath(pwd))

Note that Windows uses pnet.mexw64 while on Linux uses pnet.mexa64.

First make sure that a basic pnet call works:

>> pnet('closeall')

After you press Enter, it should do nothing, which indicates success. It means
the pnet function 'closeall' executed and closed any open sockets and such.
Be sure to run this on the second instance as well.

Now in the first instance, run this:

>> clear
>> ip = getMyIP
>> osock = InitUDPsender(ip{1},4444,ip{1},5555)

ip should be the local IP address, and osock should be 0, indicating success.

On the second instance, run:

>> ip = getMyIP
>> isock = InitUDPreceiver(ip{1},5555)

Here also the ip and isock=0 should be returned.

Now back in the first instance, run this:

>> pkt = rand(2)
>> SendUDP(osock,pkt)

pkt is the packet data consisting of four random numbers.  the SendUDP
call should return without any message, indicating success.

Back in the second instance, type this:

>> ReceiveUDP(isock,'latest')

the ans should be the four random numbers from the first instance.  If you
type ReceiveUPD(isock,'latest') again, it should return [], because nothing
was sent.

On linux, getMyIP currently does not return the IP (code is Windows specific),
so to test it, you'll need to get the ip address from the unix command line:

ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'

then in the matlab set ip manually, on 'madhat', its this:

ip = {'128.148.107.37'}


This concludes the test.  Its super simple but intended to make sure the
bare minimum pnet functionality is present.

You can also test across machines.  Here's what you would run on a Windows
matlab machine to send a pkt to madhat:

>> ip = getMyIP
>> ip2 = {'128.148.107.37'}
>> osock = InitUDPsender(ip{1},4444,ip2{1},5555)
>> pkt = rand(2)
>> SendUDP(osock,pkt)

In this example, running 'ReceiveUDP(isock,'latest')' on madhat should
return the random numbers from the rand(2) sent on the Windows machine.

NJS Dec 2013


