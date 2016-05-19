#include "../shared/Shared.h"
#include <Timer.h>

configuration HopSinkAppC {
}
implementation {
	components MainC;
	components ActiveMessageC;
	components HopSinkC as App;
	components new AMSenderC(AM_BLINKTORADIO);
	components new AMReceiverC(AM_BLINKTORADIO);
	components CC2420ActiveMessageC;
	components new TimerMilliC() as retryTimer;
	
	App -> CC2420ActiveMessageC.CC2420Packet;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Boot -> MainC;
	App.Receive -> AMReceiverC;
	App.RetryTimer->retryTimer;
}