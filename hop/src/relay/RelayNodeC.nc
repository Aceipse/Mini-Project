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

 }
 implementation {
   bool busy = FALSE;
   message_t pkt;
   uint16_t lqi = 0;
   uint16_t rssi = 0;
   uint16_t counter = 0;
 
   event void Boot.booted() {
    call AMControl.start();
    call CC2420Packet.setPower(&pkt,3);
    call LowPowerListening.setLocalWakeupInterval(250);
  }

   event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    }
    else {
      call AMControl.start();
    }
    
    call MilliTimer.startPeriodic(5000);
  }

  event void AMControl.stopDone(error_t err) {
  }


 event void AMSend.sendDone(message_t* msg, error_t error) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }
 
 event void MilliTimer.fired()
  {
  	counter++;
//  	if(counter % 2 == 1)
//  	{
//  		call AMControl.stop();
//  	}
//  	else
//  	{
//  		call AMControl.start();	
//  	}
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
		
	if (!busy) 
	{
		LinkRequest* sendpkt = (LinkRequest*)(call Packet.getPayload(&pkt, sizeof (LinkRequest)));
		sendpkt->message_id= btrpkt->message_id;
		sendpkt->message_type= LinkRequestId;
		if (call AMSend.send(AM_NODEC, &pkt, sizeof(LinkRequest)) == SUCCESS) 
		{busy = TRUE;}
	}
  }
  
  void HandshakeFromSink(message_t* msg, void* payload)
  {
  	LinkResponse* btrpkt = (LinkResponse*)payload;
  	int lrssi = (btrpkt->rssi + rssi) / 2;
  	int llqi = (btrpkt->lqi + lqi) / 2;
  	
  	printf("%i Linkresponse from sink \n", btrpkt->message_id);
    printf("rssi: %i \n", lrssi);
    printf("lqi: %i \n", llqi);
	printfflush();
		
	if (!busy) 
	{
		LinkResponse* sendpkt = (LinkResponse*)(call Packet.getPayload(&pkt, sizeof (LinkResponse)));
		sendpkt->message_id= btrpkt->message_id;
		sendpkt->message_type= LinkResponseId;
		sendpkt->lqi = llqi;
		sendpkt->rssi = lrssi;
		if (call AMSend.send(AM_NODEA, &pkt, sizeof(LinkResponse)) == SUCCESS) 
		{busy = TRUE;}
	}
  }
  
  void SendData(message_t* msg, void* payload)
  {
  	DataSend* btrpkt = (DataSend*)payload;
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
  	int lrssi = call CC2420Packet.getRssi(msg);
	int llqi = call CC2420Packet.getLqi(msg);
	
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