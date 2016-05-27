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
	message_t pkt;
	uint32_t celsius = 0;
	uint16_t counterHand = 0;
	uint16_t counterData = 0;
	uint16_t fightId = 0;
	uint16_t sendToId = 0;
	
	bool requestFromB = FALSE;
	bool requestFromC = FALSE;
	struct EwmaObj ewmaB;
  	struct EwmaObj ewmaC;
	struct EwmaObj ewmaRetrans;
 
	event void Boot.booted() {
		call AMControl.start();
		call CC2420Packet.setPower(&pkt,POWERSETTING);
		
		// Initiate with sensible, or average over some values
    	ewmaB.his = -10;
    	ewmaB.cur = 0;
    	ewmaB.lambda = 0.3;
    	    
    	ewmaC.his = -10;
    	ewmaC.cur = 0;
    	ewmaC.lambda = 0.3;
    	
    	// Initiate with sensible, or average over some values
    	ewmaRetrans.his = 100;
    	ewmaRetrans.cur = 100;
    	ewmaRetrans.lambda = 0.005;
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
		requestFromB = FALSE;
		requestFromC = FALSE;
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
		if(requestFromC && ewmaRetrans.cur > 94.0){
			fightId = AM_NODEC;	
		}
		else if(requestFromB && requestFromC)
		{	
			if(ewmaB.cur > ewmaC.cur) {
				fightId = AM_NODEB;
			} else {
				fightId = AM_NODEC;
			}
		} 
		else if(requestFromB) {
			fightId = AM_NODEB;
		}  
		else if(requestFromC) {
			fightId = AM_NODEC;
		} 
		
		if(fightId != 0){
			sendToId = fightId;
			
			printf("LINK.RESULT..... B: %i C: %i, Retra: %i \n", (int)(100*ewmaB.cur), (int)(100*ewmaC.cur), (int)(100*ewmaRetrans.cur));
			printf("LINK............ Mote %i is new endpoint ! \n", sendToId);
			printfflush();
			
			//TO START DATA
			if(!(call TimerDataSend.isRunning())){
				call TimerDataSend.startPeriodic(TIMER_PERIOD_MILLI);
			    printf("DATA............ STARTED DATA \n!");
				printfflush();	
			}
		}
		//NO FOUND, STOP DATA 
		else if(call TimerDataSend.isRunning()) {
			call TimerDataSend.stop();
			printf("DATA............ STOPPED DATA \n!");
			printfflush();	
		}
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
		      ewmaVal(&ewmaRetrans, 100);
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
			requestFromB = FALSE;
			requestFromC = FALSE;
			call TimerLinkChoosen.startOneShot(FIGHT_PERIOD_MILLI);
	  	 }
 	 	 
 	 	 //SAVE THE BEST LINK
		 if((call AMPacket.source(msg)) == AM_NODEB) {
		 	//The worst rssi
		 	btrpkt->rssi = (call CC2420Packet.getRssi(msg)) > btrpkt->rssi ? btrpkt->rssi : (call CC2420Packet.getRssi(msg));
		 	
		 	//Update ewma values
		 	requestFromB = TRUE;
			ewmaVal(&ewmaB, (btrpkt->rssi));
		 } else if((call AMPacket.source(msg)) == AM_NODEC) {
  	 	 	//The worst rssi
  	 	 	btrpkt->rssi = call CC2420Packet.getRssi(msg);
		 	
		 	//Update ewma values
		 	ewmaVal(&ewmaRetrans, 0);
		 	requestFromC = TRUE;
			ewmaVal(&ewmaC, (btrpkt->rssi));
		 }
		 
		 printf("DATA............ Retransmission from mote %i, RSSI: %i\n", call AMPacket.source(msg), btrpkt->rssi);
 	 	 	  	 
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
	    
	  	printf("LINK.RESPONSE... from mote %i, RSSI: %i\n", call AMPacket.source(msg),lrPayload->rssi);
		printfflush();
		
		if((call AMPacket.source(msg)) == AM_NODEB) {
			requestFromB = TRUE;
			ewmaVal(&ewmaB, (lrPayload->rssi));
		} else if((call AMPacket.source(msg)) == AM_NODEC) {
			requestFromC = TRUE;
			ewmaVal(&ewmaC, (lrPayload->rssi));
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