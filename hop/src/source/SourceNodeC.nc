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
   uses interface Timer<TMilli> as Timer1;
   uses interface Read<uint16_t>;
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
	uint16_t counterHand = 0;
	uint16_t counterData = 0;
	uint16_t idOfSink = 3;
	bool sendToA = FALSE;
 
	event void Boot.booted() {
		call AMControl.start();
		call CC2420Packet.setPower(&pkt,1);
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
   		sendToA = FALSE;
   		counterHand++;
   		if (!busy) {
   			LinkRequest* qu = (LinkRequest*)(call Packet.getPayload(&pkt, sizeof (LinkRequest)));
		    qu->message_id = counterHand;
		    
   			//printf("Send packet %i, %i \n", counter, sizeof(LinkRequest));
   			printfflush();
		    if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LinkRequest)) == SUCCESS) {
		      busy = TRUE;
		    }
	    }
	}
	
		event void Timer1.fired() {
   		call Timer0.stop();
   		if (!busy) {
   			DataSend* qu = (DataSend*)(call Packet.getPayload(&pkt, sizeof (DataSend)));
   			counterData++;
		    qu->message_id = counterData;
		    qu->data_part = "Nikolaj";
   			printf("Send packet %i, %i \n", counterData, idOfSink);
   			printfflush();
		    if (call AMSend.send(idOfSink, &pkt, sizeof(DataSend)) == SUCCESS) {
		      busy = TRUE;
		    }
	    } 
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg) {
			//printf("Power on send: %i \n",call CC2420Packet.getPower(msg));
			busy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
	  printf("Size of recived %i",len);
	  if (len == sizeof(Retransmission))
	  {
	  	
	  	 Retransmission* btrpkt = (Retransmission*)payload;
	  	 printf("RETRANSMITTED Request reviced");
	  	 if (!busy) {
   			DataSend* qu = (DataSend*)(call Packet.getPayload(&pkt, sizeof (DataSend)));
		    qu->message_id = btrpkt->message_id;
		    
   			printf("RETRANSMITTED %i \n", qu->message_id);
   			printfflush();
		    if (call AMSend.send(call AMPacket.source(msg), &pkt, sizeof(DataSend)) == SUCCESS) {
		      busy = TRUE;
		    }
	    }
	  	 
	  }
	  if (len == sizeof(LinkResponse)) {
	    LinkResponse* btrpkt = (LinkResponse*)payload;

		//printf("Senderid: %i \n", call AMPacket.source(msg));
	    //printf("Sender id: %i \n", btrpkt->receiver_id);
	    printf("Recived from: %i \n",call AMPacket.source(msg));
		//printfflush();
		
		call Timer1.startPeriodic(TIMER_PERIOD_MILLI);
		
		if(call AMPacket.source(msg)==3)
		{
			sendToA = TRUE;
		}
		if(call AMPacket.source(msg)==2)
		{
			if(sendToA == TRUE)
			{
				idOfSink = 3;
			}
			else
			{
				idOfSink = 2;
			}
			//call Timer1.startPeriodic(TIMER_PERIOD_MILLI);
		}
			    
	    
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
	
	event void Read.readDone(error_t result, uint16_t fahrenheit) 
   	{
		uint32_t celsius = (fahrenheit-3200)*0.55555;
  	
  		printf("C: %i \n", celsius);
		printfflush();
   	}

	event void Timer1.fired(){
		call Read.read();
	}
}