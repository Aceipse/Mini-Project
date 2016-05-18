#include <stdio.h>
#include <Timer.h>
#include "printf.h"
#include "../shared/Shared.h"
#include "../shared/HopMessages.h"
#include "SourceNode.h"
#include "ewma.h"
 
module SourceNodeC {
   uses interface Boot;
   uses interface Leds;
   uses interface Timer<TMilli> as TimerBetweenLinkReqs;
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
//	bool firstLinkResponse = TRUE;
	message_t pkt;
	uint32_t celsius = 0;
	uint16_t counterHand = 0;
	uint16_t counterData = 0;
	uint16_t fightId = 0;
	int16_t fightRssi = -250;
	uint16_t sendToId = 0;
	
	struct EwmaObj ewmaB;
  	struct EwmaObj ewmaC;
 
	event void Boot.booted() {
		call AMControl.start();
		call CC2420Packet.setPower(&pkt,POWERSETTING);
		
		// Initiate with sensible, or average over some values
    	ewmaB.his = 50;
    	ewmaB.cur = 0;
    
    	ewmaC.his = 50;
    	ewmaC.cur = 0;
  	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
	    	call TimerBetweenLinkReqs.startPeriodic(BETWEEN_REQUEST_PERIOD_MILLI);
	    	call Timer2.startPeriodic(TEMP_PERIOD_MILLI);
	    }
	    else {
	      call AMControl.start();
	    }
    }

	event void AMControl.stopDone(error_t err) {
  	}

   	event void TimerBetweenLinkReqs.fired() {
		fightId = 0;
		fightRssi = -250;
		printf("START ----------- fight \n");
		printfflush();
		call TimerLinkChoosen.startOneShot(FIGHT_PERIOD_MILLI);
   		call TimerLinkReq.startPeriodic(REQUEST_PERIOD_MILLI);
	}

   	event void TimerLinkReq.fired() {	  	   		
   		if (!busy) {
   			LinkRequest* qu = (LinkRequest*)(call Packet.getPayload(&pkt, sizeof (LinkRequest)));
		    qu->message_type = LinkRequestId;
		    qu->message_id = ++counterHand;
		    
		    if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LinkRequest)) == SUCCESS) {
		      busy = TRUE;
		    }
	    }
	}
	
	event void TimerLinkChoosen.fired(){
		call TimerLinkReq.stop();
		
		//Which link is best?
		if(ewmaB.cur > ewmaC.cur) {
			fightId = AM_NODEB;
		} else {
			fightId = AM_NODEC;
		}
		
		if(fightId != 0){
			sendToId = fightId;
			
			printf("EWMA B: %i C: %i\n", (int)(100*ewmaB.cur), (int)(100*ewmaC.cur));
			printf("END ----------- Mote %i is new endpoint ! \n", sendToId);
			printfflush();
			
			//TO START DATA
			if(!(call TimerDataSend.isRunning())){
				call TimerDataSend.startPeriodic(TIMER_PERIOD_MILLI);
			    printf("STARTED DATA !");
				printfflush();	
			}
		}
		//NO FOUND, STOP DATA 
		/* else if(call TimerDataSend.isRunning()) {
		    printf("STOPPED DATA !");
			printfflush();
			call TimerDataSend.stop();
		}*/
	}
	
	event void TimerDataSend.fired() {
   		if (!busy && !tempWrite && sendToId != 0) {
   			DataSend* qu = (DataSend*)(call Packet.getPayload(&pkt, sizeof (DataSend)));
   			counterData++;
   			qu->message_type = DataSendId;
		    qu->message_id = counterData;
		    qu->data_part = celsius;
   			//printf("DataSend %i, to mote %i, data: %i \n", counterData, sendToId, celsius);
   			//printfflush();
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
	  	 
	  	 if(!(call TimerLinkChoosen.isRunning())){
			fightId = 0;
			fightRssi = -250;
			printf("START ----------- fight \n");
			printfflush();
			call TimerLinkChoosen.startOneShot(FIGHT_PERIOD_MILLI);
	  	 }
	  	 
	  	 //Adjust LQI
	  	 if((btrpkt->rssi) == 0){
  	 	 	//FROM MOTEC
  	 	 	btrpkt->rssi = call CC2420Packet.getRssi(msg);
  	 	 }
  	 	 else {
 	 	 	//FROM MOTEB
 	 	 	btrpkt->rssi = ((call CC2420Packet.getRssi(msg)) + (btrpkt->rssi)) / 2;
 	 	 }
 	 	 
 	 	 printf("RetraResponse from: %i, LQI: %i RSSI: %i\n", call AMPacket.source(msg), btrpkt->lqi,btrpkt->rssi);
 	 	 //SAVE THE BEST RSSI
		 if(AMPacket.source(msg) == AM_NODEB) {
			ewmaVal(&ewmaB, (btrpkt->rssi));
		 } else if(AMPacket.source(msg) == AM_NODEC) {
			ewmaVal(&ewmaC, (btrpkt->rssi));
		 }
			
 	 	 /*if(fightRssi < (btrpkt->rssi)){
			fightRssi = btrpkt->rssi;
			fightId = call AMPacket.source(msg);
		 }*/
	  	 
	  	 if (!busy) {
   			DataSend* qu = (DataSend*)(call Packet.getPayload(&pkt, sizeof (DataSend)));
   			qu->message_type = DataRetransmissionId;
		    qu->message_id = btrpkt->message_id;
		    
   			//printf("RETRANSMITTED %i to mote: %i \n", btrpkt->message_id, call AMPacket.source(msg));
   			//printfflush();
		    if (call AMSend.send(call AMPacket.source(msg), &pkt, sizeof(DataSend)) == SUCCESS) {
		      busy = TRUE;
		    }
	    }
	  }

	  if (bm->message_type == LinkResponseId) {
	    LinkResponse* lrPayload = (LinkResponse*)payload;
	    
	  	printf("LinkResponse from: %i, LQI: %i RSSI: %i\n", call AMPacket.source(msg), lrPayload->lqi,lrPayload->rssi);
		printfflush();
		
		if(AMPacket.source(msg) == AM_NODEB) {
			ewmaVal(&ewmaB, (lrPayload->rssi));
		} else if(AMPacket.source(msg) == AM_NODEC) {
			ewmaVal(&ewmaC, (lrPayload->rssi));
		}
		
		/*if(fightRssi < (lrPayload->rssi)){
			fightRssi = lrPayload->rssi;
			fightId = call AMPacket.source(msg);
		}*/
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