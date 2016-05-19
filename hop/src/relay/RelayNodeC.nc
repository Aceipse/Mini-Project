#include <printf.h>
#include <stdio.h>
#include "Timer.h"
#include "../shared/Shared.h"
#include "../shared/HopMessages.h"
 
 module RelayNodeC {
   uses interface Boot;
   uses interface Leds;
   uses interface Packet;
   uses interface AMPacket;
   uses interface AMSend;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface CC2420Packet;
   uses interface LowPowerListening;
   uses interface Timer<TMilli> as MilliTimer;
   uses interface Timer<TMilli> as Timer2;

 }
 implementation {
   bool busy = FALSE;
   message_t pkt;
   uint16_t lqi = 0;
   int16_t rssi = 0;
   uint16_t counter = 0;
   uint16_t messageCounter = 0;
   uint16_t currentCounter = 0;
 
   event void Boot.booted() {
    call AMControl.start();
    call CC2420Packet.setPower(&pkt,POWERSETTING);
  }

   event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    }
    else {
      //call AMControl.start();
    }
    
    call MilliTimer.startPeriodic(REQUEST_PERIOD_MILLI * 3);
  }

  event void AMControl.stopDone(error_t err) {
  }


 event void AMSend.sendDone(message_t* msg, error_t error) {
    if (&pkt == msg) {
      busy = FALSE;
    }
    if(error != SUCCESS)
    {
    	printf("ERROR HAPPENED \n");
    	printfflush();
    }
  }
 
 event void MilliTimer.fired()
  {
  	printf("Listen for handshake \n");
  	printfflush();
  	call MilliTimer.stop();
  	call AMControl.start();
  	call Timer2.startPeriodic((REQUEST_PERIOD_MILLI + FIGHT_PERIOD_MILLI + TIMER_PERIOD_MILLI) * 1.2);
  }
 
 event void Timer2.fired()
  {
  	printf("Sleep \n");
  	printfflush();
  	call Timer2.stop();
  	call AMControl.stop();
  	call MilliTimer.startPeriodic(REQUEST_PERIOD_MILLI * 3);
  }
  
  void HandshakeFromSource(message_t* msg, void* payload)
  {
  	LinkRequest* btrpkt = (LinkRequest*)payload;
  	call Leds.set(btrpkt->message_id);
	rssi = call CC2420Packet.getRssi(msg);
	lqi = call CC2420Packet.getLqi(msg);
	
  	printf("%i Linkrequest from source \n", btrpkt->message_id);
    printf("Senderid: %i \n", call AMPacket.source(msg));
    printfflush();
		
	if (TRUE) 
	{
		LinkRequest* sendpkt = (LinkRequest*)(call Packet.getPayload(&pkt, sizeof (LinkRequest)));
		sendpkt->message_id= btrpkt->message_id;
		sendpkt->message_type= LinkRequestId;
		if (call AMSend.send(AM_NODEC, &pkt, sizeof(LinkRequest)) == SUCCESS) 
		{busy = TRUE; printf("Nu er vi her \n"); printfflush();}
	}
  }
  
  void HandshakeFromSink(message_t* msg, void* payload)
  {
  	LinkResponse* btrpkt = (LinkResponse*)payload;
  	int16_t lrssi;
  	
  	// Finding the worst rssi
  	if(btrpkt->rssi > rssi)
  	{lrssi = rssi;}
  	else {lrssi = btrpkt->rssi;}
  	
  	//uint16_t llqi = (btrpkt->lqi + lqi) / 2;
  	
  	printf("%i Linkresponse from sink \n", btrpkt->message_id);
    printf("rssi1: %i rssi2: %i \n", btrpkt->rssi, rssi);
    printf("lqi: %i \n", lqi);
	printfflush();
		
	if (TRUE) 
	{
		LinkResponse* sendpkt = (LinkResponse*)(call Packet.getPayload(&pkt, sizeof (LinkResponse)));
		sendpkt->message_id= btrpkt->message_id;
		sendpkt->message_type= LinkResponseId;
		sendpkt->lqi = lqi;
		sendpkt->rssi = lrssi;
		if (call AMSend.send(AM_NODEA, &pkt, sizeof(LinkResponse)) == SUCCESS) 
		{busy = TRUE;}
	}
  }
  
  void SendData(message_t* msg, void* payload)
  {
  	DataSend* btrpkt = (DataSend*)payload;
  	call Timer2.stop();
  	//Message * 1.5
  	call Timer2.startOneShot(TIMER_PERIOD_MILLI * 10);
  	printf("%i Send data to sink \n", btrpkt->message_id);
	printfflush();
		
	if (!busy) 
	{
		DataSend* sendpkt = (DataSend*)(call Packet.getPayload(&pkt, sizeof (DataSend)));
		sendpkt->message_id = btrpkt->message_id;
		sendpkt->message_type= btrpkt->message_type;
		sendpkt->data_counter = btrpkt->data_counter;
		sendpkt->data_part = btrpkt->data_part;
		if (call AMSend.send(AM_NODEC, &pkt, sizeof(DataSend)) == SUCCESS) 
		{busy = TRUE;}
	}
  }
  
  void Retransmit(message_t* msg, void* payload)
  {
  	Retransmission* btrpkt = (Retransmission*)payload;
  	uint16_t lrssi = call CC2420Packet.getRssi(msg);
	uint16_t llqi = call CC2420Packet.getLqi(msg);
	
  	printf("Retransmit package: %i \n", btrpkt->message_id);
	printfflush();
		
	if (!busy) 
	{
		Retransmission* sendpkt = (Retransmission*)(call Packet.getPayload(&pkt, sizeof (Retransmission)));
		sendpkt->message_type= RetransmissionId;
		sendpkt->message_id= btrpkt->message_id;
		sendpkt->lqi= llqi;
		sendpkt->rssi= lrssi;
		if (call AMSend.send(AM_NODEA, &pkt, sizeof(Retransmission)) == SUCCESS) 
		{busy = TRUE;}
	}
  }
  
  

event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
  
  BaseMessage* btrpkt = (BaseMessage*)payload;
  int msgType = btrpkt->message_type;
  
  //LinkRequest
  if (msgType == LinkRequestId) {HandshakeFromSource(msg, payload);}
  //LinkRespone
  else if (msgType == LinkResponseId) {HandshakeFromSink(msg, payload);}
  //DataSend & DataRetransmission
  else if (msgType == DataSendId || msgType == DataRetransmissionId) {SendData(msg, payload);}
  //Retransmission
  else if (msgType == RetransmissionId) {Retransmit(msg, payload);}
  return msg;
}
}