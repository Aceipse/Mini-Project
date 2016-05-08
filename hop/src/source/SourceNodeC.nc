#include <stdio.h>
#include <Timer.h>
#include "printf.h"
#include "../shared/Shared.h"
#include "../shared/HopMessages.h"
#include "SourceNode.h"
 
module SourceNodeC {
   uses interface Boot;
   uses interface Leds;
   uses interface Timer<TMilli> as Timer0;
   uses interface Packet;
   uses interface AMPacket;
   uses interface AMSend;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface CC2420Packet;
}
implementation {   	   	
	bool busy = FALSE;
	message_t pkt;
	uint16_t counter = 0;
	int history_size = 10;
	//History* history[ history_size ];
 
	event void Boot.booted() {
		call AMControl.start();
  	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
	    	call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
	    }
	    else {
	      call AMControl.start();
	    }
    }

	event void AMControl.stopDone(error_t err) {
  	}

   	event void Timer0.fired() {
   		counter++;
   		if (!busy) {
   			HandshakeSend* qu = (HandshakeSend*)(call Packet.getPayload(&pkt, sizeof (HandshakeSend)));
		    qu->message_id = counter;
		    
   			printf("Send packet %i, %i \n", counter, sizeof(HandshakeSend));
   			printfflush();
		    if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(HandshakeSend)) == SUCCESS) {
		      busy = TRUE;
		    }
	    }
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg) {
			busy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
	  if (len == sizeof(HandshakeReceive)) {
	    HandshakeReceive* btrpkt = (HandshakeReceive*)payload;

	    printf("Sender id: %i \n", btrpkt->receiver_id);
		printfflush();
	    
//		if(btrpkt->receiver_id == TOS_NODE_ID)
//		{
//			printf("Recived");
//			//call Leds.set(btrpkt->message_id);
//			//printf("Rssi: %i \n",call CC2420Packet.getRssi(msg));
//			//printf("LQI: %i \n", call CC2420Packet.getLqi(msg));
//			printfflush();
//		}
	  }
	  return msg;
	}
}