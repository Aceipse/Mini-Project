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
   components new TimerMilliC() as TimerLinkReq;
   components new TimerMilliC() as TimerLinkChoosen;
   components new TimerMilliC() as TimerDataSend;
   components new TimerMilliC() as Timer2;
   components ActiveMessageC;
   components new AMSenderC(AM_BLINKTORADIO);
   components new AMReceiverC(AM_BLINKTORADIO);
   components CC2420ActiveMessageC;
   components new SensirionSht11C() as Sensor;

   App -> CC2420ActiveMessageC.CC2420Packet;
   App.Packet -> AMSenderC;
   App.AMPacket -> AMSenderC;
   App.AMSend -> AMSenderC;
   App.AMControl -> ActiveMessageC;
   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.TimerLinkReq -> TimerLinkReq;
   App.TimerLinkChoosen -> TimerLinkChoosen;
   App.TimerDataSend -> TimerDataSend;
   App.Timer2 -> Timer2;
   App.Receive -> AMReceiverC;
   App.Read -> Sensor.Temperature;
}