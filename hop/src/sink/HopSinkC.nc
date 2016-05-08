#include <printf.h>
#include "../Shared/HopMessages.h"
 
module HopSinkC {
	uses interface Boot;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
	uses interface CC2420Packet;
}
implementation {
	
message_t pkt;

	event void Boot.booted(){
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
		
		
    if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(HandshakeSend)) == SUCCESS) {
    }
		
	}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		if (len == sizeof(HandshakeSend)) {
			HandshakeSend* hss = (HandshakeSend*)payload;
			printf("Got message from: %i \n",call AMPacket.source(msg));
			printf("message_id: %i \n",hss->message_id);
			printf("Rssi: %i \n",call CC2420Packet.getRssi(msg));
			printf("LQI: %i \n", call CC2420Packet.getLqi(msg));
			printfflush();
		}
		return msg;
	}
}