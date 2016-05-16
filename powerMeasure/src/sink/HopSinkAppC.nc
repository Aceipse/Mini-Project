#include "../shared/Shared.h"
configuration HopSinkAppC {
}
implementation {
	components MainC;
	components ActiveMessageC;
	components HopSinkC as App;
	components new AMSenderC(AM_BLINKTORADIO);
	components new AMReceiverC(AM_BLINKTORADIO);
	components CC2420ActiveMessageC;
	components new TimerMilliC() as Timer0;
	
	App -> CC2420ActiveMessageC.CC2420Packet;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Boot -> MainC;
	App.Receive -> AMReceiverC;
	App.Timer0 -> Timer0;
}