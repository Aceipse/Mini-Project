 #include <Timer.h>
#include "../shared/Shared.h"
 
 configuration RelayNodeAppC {
 }
 implementation {
   components MainC;
   components LedsC;
   components RelayNodeC as App;
   components ActiveMessageC;
   components new AMSenderC(AM_BLINKTORADIO);
   components new AMReceiverC(AM_BLINKTORADIO);
   components CC2420ActiveMessageC;
   components new TimerMilliC() as MilliTimer;
   components new TimerMilliC() as Timer2;

   App -> CC2420ActiveMessageC.CC2420Packet;
   App.LowPowerListening -> CC2420ActiveMessageC;
   App.Packet -> AMSenderC;
   App.AMPacket -> AMSenderC;
   App.AMSend -> AMSenderC;
   App.AMControl -> ActiveMessageC;
   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.Receive -> AMReceiverC;
   App.MilliTimer -> MilliTimer;
   App.Timer2 -> Timer2;
 }
 
