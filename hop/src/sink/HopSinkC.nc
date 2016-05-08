#include "../Shared/HopMessages.h"
#include "/opt/tinyos-2.1.1/tos/lib/printf/printf.h"

module HopSinkC {
	uses interface Boot;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
}
implementation {
	event void Boot.booted() {
		call AMControl.start();
	}

	event void AMSend.sendDone(message_t *msg, error_t error){
		// TODO Auto-generated method stub
	}

	event void AMControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void AMControl.startDone(error_t error){
		// TODO Auto-generated method stub
	}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		if (len == sizeof(HandshakeSend)) {
			HandshakeSend* hss = (HandshakeSend*)payload;
			printf("RECEIVED MESSAGE");
		}
		return msg;
	}
}