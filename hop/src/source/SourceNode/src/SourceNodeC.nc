 #include <Timer.h>
 #include "SourceNode.h"
 #include <printf.h>
 
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
     /* counter++;
     call Leds.set(counter);if (!busy) {
    BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
    btrpkt->senderid = TOS_NODE_ID;
    btrpkt->msgid = counter;
    btrpkt->receiverid = 3;
    if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
      busy = TRUE;
    }
  } */
}


 event void AMSend.sendDone(message_t* msg, error_t error) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
  if (len == sizeof(HandshakeSend)) {
    HandshakeSend* btrpkt = (HandshakeSend*)payload;
    
    printf("Receiverid: %i \n", btrpkt->receiver_id);
    printf("Nodeid: %i \n", TOS_NODE_ID);
    
	if(btrpkt->receiver_id == TOS_NODE_ID)
	{
		call Leds.set(btrpkt->message_id);
		printf("Rssi: %i \n",call CC2420Packet.getRssi(msg));
		printf("LQI: %i \n", call CC2420Packet.getLqi(msg));
		printfflush();
		
		if (!busy) 
		{
		    HandshakeReceive* sendpkt = (HandshakeReceive*)(call Packet.getPayload(&pkt, sizeof (HandshakeReceive)));
		    sendpkt->sender_id = TOS_NODE_ID;
		    sendpkt->message_id= counter;
		    sendpkt->receiver_id = btrpkt->sender_id;
		    sendpkt->lqi = call CC2420Packet.getLqi(msg);
		    sendpkt->rssi = call CC2420Packet.getRssi(msg);
		    sendpkt->tx = 0; 
		    if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(HandshakeReceive)) == SUCCESS) {
		      busy = TRUE;
		    }
		}
	}
  }
  return msg;
}
}