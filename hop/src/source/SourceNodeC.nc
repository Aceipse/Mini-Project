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
	uint16_t fightId = 0;
	uint16_t fightLqi = 0;
	uint16_t sendToId = 0;
 
	event void Boot.booted() {
		call AMControl.start();
		call CC2420Packet.setPower(&pkt,POWERSETTING);
  	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
	    	call TimerLinkReq.startPeriodic(REQUEST_PERIOD_MILLI);
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
		    
		    if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LinkRequest)) == SUCCESS) {
		      busy = TRUE;
		    }
	    }
	}
	
	event void TimerLinkChoosen.fired(){
		if(fightId != 0){
			sendToId = fightId;
			
			printf("End the fight. Mote %i won ! \n", sendToId);
			printfflush();
			
			call TimerDataSend.stop();
			call TimerDataSend.startPeriodic(TIMER_PERIOD_MILLI);
		}
	    
		firstLinkResponse = TRUE;
	}
	
	event void TimerDataSend.fired() {
   		if (!busy && !tempWrite && sendToId != 0) {
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
			busy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
   	  BaseMessage* bm = (BaseMessage*)payload;
	  
	  if (bm->message_type == RetransmissionId)
	  {
	  	 Retransmission* btrpkt = (Retransmission*)payload;
	  	 
	  	 if(firstLinkResponse){
			fightId = 0;
			fightLqi = 0;  
			firstLinkResponse = FALSE;
			printf("Let the fight start \n");
			printfflush();
			call TimerLinkChoosen.startOneShot(FIGHT_PERIOD_MILLI);
	  	 }
	  	 
	  	 //Adjust LQI
	  	 if((btrpkt->lqi) == 0){
  	 	 	//FROM MOTEC
  	 	 	btrpkt->lqi = call CC2420Packet.getLqi(msg);
  	 	 }
  	 	 else {
 	 	 	//FROM MOTEB
 	 	 	btrpkt->lqi = ((call CC2420Packet.getLqi(msg)) + (btrpkt->lqi)) / 2;
 	 	 }
 	 	 
 	 	 //SAVE THE BEST LQI
 	 	 if(fightLqi < (btrpkt->lqi)){
			fightLqi = btrpkt->lqi;
			fightId = call AMPacket.source(msg);
		    //printf("Retra best lqi: %i, %i \n", btrpkt->lqi, call AMPacket.source(msg));
			//printfflush();
		 }
	  	 
	  	 if (!busy) {
   			DataSend* qu = (DataSend*)(call Packet.getPayload(&pkt, sizeof (DataSend)));
   			qu->message_type = DataRetransmissionId;
		    qu->message_id = btrpkt->message_id;
		    
   			printf("RETRANSMITTED %i to mote: %i \n", btrpkt->message_id, call AMPacket.source(msg));
   			printfflush();
		    if (call AMSend.send(call AMPacket.source(msg), &pkt, sizeof(DataSend)) == SUCCESS) {
		      busy = TRUE;
		    }
	    }
	  }

	  if (bm->message_type == LinkResponseId) {
	    LinkResponse* lrPayload = (LinkResponse*)payload;
	    
	  	if(firstLinkResponse){
			fightId = 0;
			fightLqi = 0;
			firstLinkResponse = FALSE;
			printf("Let the fight start \n");
			printfflush();
			call TimerLinkChoosen.startOneShot(FIGHT_PERIOD_MILLI);
	  	}
	  	
	    //printf("LinkResponse from: %i, %i \n", call AMPacket.source(msg), lrPayload->lqi);
		//printfflush();
		if(fightLqi < (lrPayload->lqi)){
			fightLqi = lrPayload->lqi;
			fightId = call AMPacket.source(msg);
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