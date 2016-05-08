#include "HopSink.h"
#include "../Shared/Shared.h"

configuration HopSinkAppC {
}
implementation {
	components MainC;
	components ActiveMessageC;
	components HopSinkC as App;
	components new AMSenderC(AM_BLINKTORADIO);
	components new AMReceiverC(AM_BLINKTORADIO);
	
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Boot -> MainC;
	App.Receive -> AMReceiverC;
}