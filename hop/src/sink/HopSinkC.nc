#include "../shared/HopMessages.h"
#include "printf.h"
#include <stdio.h>

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
	bool busy = FALSE;


	event void Boot.booted(){

		call AMControl.start();
		printf("Inside Boot.Booted\n");
		printfflush();
	}

	event void AMSend.sendDone(message_t *msg, error_t error){
		if (&pkt == msg) {
			busy = FALSE;
		}
	}

	event void AMControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event void AMControl.startDone(error_t error){
		// TODO Auto-generated method stub
	
	}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		if (len == sizeof(LinkRequest)) {
			LinkRequest* hss = (LinkRequest*)payload;

			printf("Got handshake message from: %i \n",call AMPacket.source(msg));
			printf("message_id: %i \n",hss->message_id);
			printf("Rssi: %i \n",call CC2420Packet.getRssi(msg));
			printf("LQI: %i \n", call CC2420Packet.getLqi(msg));
			printfflush();
	
			if (!busy) {
				LinkResponse* qu = (LinkResponse*)(call Packet.getPayload(&pkt, sizeof (LinkResponse)));
				qu->message_id = hss->message_id;
				qu->lqi = call CC2420Packet.getLqi(msg);
				qu->rssi= call CC2420Packet.getRssi(msg);
				qu->tx=0;		    
 
				printf("Sending receive to: %i \n",call AMPacket.source(msg));
				printfflush();
				if (call AMSend.send(call AMPacket.source(msg), &pkt, sizeof(LinkResponse)) == SUCCESS) {
					printf("Sent \n");
					busy = TRUE;
				}
			}

		}
		return msg;
	}
}