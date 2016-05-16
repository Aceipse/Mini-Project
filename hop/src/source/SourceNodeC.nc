#include <stdio.h>
#include <Timer.h>
#include "printf.h"
#include "../shared/Shared.h"
#include "../shared/HopMessages.h"
#include "SourceNode.h"
 
module SourceNodeC {
   uses interface Boot;
   uses interface Leds;
   uses interface Timer<TMilli> as TimerLinkReq;
   uses interface Timer<TMilli> as TimerLinkChoosen;
   uses interface Timer<TMilli> as TimerDataSend;
   uses interface Timer<TMilli> as Timer2;
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
	bool tempWrite = FALSE;
	bool firstLinkResponse = TRUE;
	message_t pkt;
	uint32_t celsius = 0;
	uint16_t counterHand = 0;
	uint16_t counterData = 0;
	uint16_t sendToId = 0;
	uint16_t sendToLqi = 0;
 
	event void Boot.booted() {
		call AMControl.start();
		call CC2420Packet.setPower(&pkt,POWERSETTING);
  	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
	    	call TimerLinkReq.startPeriodic(TIMER_PERIOD_MILLI);
	    	call Timer2.startPeriodic(TEMP_PERIOD_MILLI);
	    }
	    else {
	      call AMControl.start();
	    }
    }

	event void AMControl.stopDone(error_t err) {
  	}

   	event void TimerLinkReq.fired() {
   		counterHand++;
   		if (!busy) {
   			LinkRequest* qu = (LinkRequest*)(call Packet.getPayload(&pkt, sizeof (LinkRequest)));
		    qu->message_type = LinkRequestId;
		    qu->message_id = counterHand;
		    
   			printf("LinkRequest %i \n", counterHand);
   			printfflush();
		    if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LinkRequest)) == SUCCESS) {
		      busy = TRUE;
		    }
	    }
	}
	
	event void TimerLinkChoosen.fired(){
   		call TimerLinkReq.stop();
		call TimerLinkChoosen.stop();
		
		if(sendToId != 0){
			call TimerDataSend.startPeriodic(TIMER_PERIOD_MILLI);
		} 
		else {
			sendToId = 0;
			sendToLqi = 0;    	
	    	call TimerLinkReq.startPeriodic(TIMER_PERIOD_MILLI);
	    }
	    
		firstLinkResponse = FALSE;
	}
	
	event void TimerDataSend.fired() {
   		if (!busy && !tempWrite) {
   			DataSend* qu = (DataSend*)(call Packet.getPayload(&pkt, sizeof (DataSend)));
   			counterData++;
   			qu->message_type = DataSendId;
		    qu->message_id = counterData;
		    qu->data_part = celsius;
   			printf("DataSend %i, to mote %i, data: %i \n", counterData, sendToId, celsius);
   			printfflush();
		    if (call AMSend.send(sendToId, &pkt, sizeof(DataSend)) == SUCCESS) {
		      busy = TRUE;
		    }
	    }
	}

	event void Timer2.fired(){
		call Read.read();
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg) {
			//printf("Power on send: %i \n",call CC2420Packet.getPower(msg));
			busy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
   	  BaseMessage* bm = (BaseMessage*)payload;
	  
	  if (bm->message_type == RetransmissionId)
	  {
	  	 Retransmission* btrpkt = (Retransmission*)payload;
	  	 
	  	 if(firstLinkResponse){
			firstLinkResponse = FALSE;
			call TimerDataSend.stop();
			call TimerLinkChoosen.startPeriodic(5000);
	  	 }
	  	 
	  	 //Adjust LQI
	  	 if(btrpkt->lqi == 0){
  	 	 	//FROM MOTEC
  	 	 	btrpkt->lqi = call CC2420Packet.getLqi(msg);
  	 	 }
  	 	 else {
 	 	 	//FROM MOTEB
 	 	 	nx_uint16_t tmp = btrpkt->lqi;
 	 	 	btrpkt->lqi = ((call CC2420Packet.getLqi(msg)) + tmp) / 2;
 	 	 }
 	 	 
 	 	 //SAVE THE BEST LQI
 	 	 if(sendToLqi < (btrpkt->lqi)){
			sendToLqi = btrpkt->lqi;
			sendToId = call AMPacket.source(msg);
		    printf("Retra best lqi: %i, %i \n", btrpkt->lqi, call AMPacket.source(msg));
			printfflush();
		 }
	  	 
	  	 if (!busy) {
   			DataSend* qu = (DataSend*)(call Packet.getPayload(&pkt, sizeof (DataSend)));
   			qu->message_type = DataSendId;
		    qu->message_id = btrpkt->message_id;
		    
   			printf("RETRANSMITTED %i \n to id: %i", qu->message_id, call AMPacket.source(msg));
   			printfflush();
		    if (call AMSend.send(call AMPacket.source(msg), &pkt, sizeof(DataSend)) == SUCCESS) {
		      busy = TRUE;
		    }
	    }
	  }

	  if (bm->message_type == LinkResponseId) {
	    LinkResponse* lrPayload = (LinkResponse*)payload;
	    
	  	if(firstLinkResponse){
			firstLinkResponse = FALSE;
			call TimerLinkChoosen.startPeriodic(5000);
	  	}
	  	
	    printf("LinkResponse from: %i, %i \n", call AMPacket.source(msg), lrPayload->lqi);
		printfflush();
		if(sendToLqi < (lrPayload->lqi)){
			sendToLqi = lrPayload->lqi;
			sendToId = call AMPacket.source(msg);
		    printf("New best lqi: %i, %i \n", lrPayload->lqi, call AMPacket.source(msg));
			printfflush();
		}
	  }
	  return msg;
	}
	
	event void Read.readDone(error_t result, uint16_t fahrenheit) 
   	{
   		tempWrite = TRUE;
		celsius = (fahrenheit-3200)*0.55555;
   		tempWrite = FALSE;
   	}
}