#include <Timer.h>
#include "SourceNode.h"
#include "../shared/Shared.h"
#include "../shared/HopMessages.h"
 
configuration SourceNodeAppC {
}
implementation {
   components MainC;
   components LedsC;
   components SourceNodeC as App;
   components new TimerMilliC() as Timer0;
   components new TimerMilliC() as Timer1;
   components ActiveMessageC;
   components new AMSenderC(AM_BLINKTORADIO);
   components new AMReceiverC(AM_BLINKTORADIO);
   components CC2420ActiveMessageC;

   App -> CC2420ActiveMessageC.CC2420Packet;
   App.Packet -> AMSenderC;
   App.AMPacket -> AMSenderC;
   App.AMSend -> AMSenderC;
   App.AMControl -> ActiveMessageC;
   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.Timer0 -> Timer0;
   App.Timer1 -> Timer1;
   App.Receive -> AMReceiverC;
}