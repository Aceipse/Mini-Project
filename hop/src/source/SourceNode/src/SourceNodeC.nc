#include <stdio.h>
#include <Timer.h>
#include "printf.h"
#include "Shared.h"
#include "SourceNode.h"
#include "HopMessages.h"
 
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
   		printf("Send init %i \n", counter);
   		printfflush();
   		if (!busy) {
   			HandshakeSend* qu = (HandshakeSend*)(call Packet.getPayload(&pkt, sizeof (HandshakeSend)));
	   		qu->sender_id = TOS_NODE_ID;
		    qu->message_id = counter;
		    qu->sender_id = 1;
		    
   			printf("Send packet %i \n", counter);
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
	//  if (len == sizeof(HandshakeSend)) {
	//    HandshakeSend* btrpkt = (HandshakeSend*)payload;
	//
	//    printf("Nodeid: %i \n", TOS_NODE_ID);
	//    
	//	if(btrpkt->receiver_id == TOS_NODE_ID)
	//	{
	//		call Leds.set(btrpkt->message_id);
	//		//printf("Rssi: %i \n",call CC2420Packet.getRssi(msg));
	//		//printf("LQI: %i \n", call CC2420Packet.getLqi(msg));
	//		printfflush();
	//	}
	//  }
	  return msg;
	}
}