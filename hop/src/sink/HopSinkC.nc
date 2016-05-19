#define LISTSIZE 100

#include "../shared/HopMessages.h"
#include "TransmissionObj.h"
#include "printf.h"
#include <stdio.h>
#include <Timer.h>

module HopSinkC {
  uses interface Boot;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  uses interface Receive;
  uses interface CC2420Packet;
  uses interface Timer<TMilli> as RetryTimer;
}
implementation {

  message_t pkt;
  bool busy = FALSE;
  bool firstDataReceive=TRUE;
  bool resendBool=TRUE;
  int lastDataId = 0;
  
  //Retry timer data
  int sourceToSendTo;
  message_t msgToResend;
  
  

  // LIST LOGIC
  int c = 0;
  struct RetransmissionObj list[LISTSIZE];
  
  //set initial values of the RetransmissionObjs
  void initList(){
	  int i;
  for(i=0;i<LISTSIZE;i++){
	  list[i].message_id=0;
	  list[i].retries=0;
  }
  }
  
  
  
  struct RetransmissionObj* ro;

  void incrementRetransmissionCounter(int id){
    int i;
    for (i = 0; i < LISTSIZE; i++) {
      if (list[i].message_id == id) {
		list[i].retries=list[i].retries+1;
        return;
      }
    }
    printf("Could not increment, id was: %id\n",id);
    printfflush();
  }
  void remove(nx_uint16_t id) {
    int i;
    bool found=FALSE;
    for (i = 0; i < LISTSIZE; i++) {
      if(!found){
        if (list[i].message_id == id) {
        found=TRUE;
      }
      }else{
        //Move this item to previous spot
        list[i-1]=list[i];
      }
      
    }
    //Set last item to empty item to make sure that if it is full we removed an obj
    list[LISTSIZE].message_id=0;
		list[LISTSIZE].retries=0;
    printf("Removed message with id: %i\n",id);
    
    return;
  }
  
  bool find(nx_uint16_t id){
	  int i;
    for (i = 0; i < LISTSIZE; i++) {
      if (list[i].message_id == id) {
        return TRUE;
      }
    }
    return FALSE;
  }
    void insert(int id) {
    //Check if the id is already added in the list
    if(!find(id)){
    
    int i;
    for (i = 0; i < LISTSIZE; i++) {
      if (list[i].message_id == 0) {
		  printf("Inserting into missing packages id %i\n", id);
        printfflush();
		list[i].message_id=id;
        return;
      }
    }
    
      
    }
  }
  
  void sendRetransmissions(){
	 int i;
   int firstElemRetries=list[0].retries;
   int elementToRetry=0;
    for (i = 0; i < LISTSIZE; i++) {
      if (list[i].message_id!=0 && list[i].retries<firstElemRetries) {		         
        elementToRetry=i;
        break;
      }
    }
    if(list[elementToRetry].message_id!=0){
      
      printf("Sending retransmission on id %i \n", list[elementToRetry].message_id);
        printfflush();
      if(!busy){
		Retransmission *rtpkt= (Retransmission *)call Packet.getPayload(&pkt,sizeof(Retransmission));
		rtpkt->message_id=list[elementToRetry].message_id;
    rtpkt->message_type=RetransmissionId;
		
		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt,
                             sizeof(Retransmission)) == SUCCESS) {
          busy = TRUE;
        }
		}
    }
    
    
  }
  //

  event void Boot.booted() {

initList();
    call AMControl.start();
    call CC2420Packet.setPower(&pkt,3);
    printf("Inside Boot.Booted\n");
    printfflush();
  }

event void RetryTimer.fired(){
  printf("Inside timer\n");
  printfflush();
   if(call AMSend.send(sourceToSendTo, &pkt,
                             sizeof(LinkResponse))==SUCCESS){
//Dont reschedule
printf("Success inside timer\n");
  printfflush();

                             }else{
                               printf("Error inside timer\n");
  printfflush();
                               call RetryTimer.startOneShot(10);
                             }        
  
}


  event void AMSend.sendDone(message_t * msg, error_t error) {
    if (&pkt == msg) {
      BaseMessage *bmpkt= (BaseMessage *)call Packet.getPayload(&pkt,sizeof(BaseMessage));
      busy = FALSE;     	
      
      //Check if this was a retransmission and add 1 to retries if it was, and if the call was succesful
      if(error==SUCCESS){
        if(bmpkt->message_type==RetransmissionId){
          
          //Cast to retransmission message so we can get message id
          Retransmission *rtpkt= (Retransmission *)call Packet.getPayload(&pkt,sizeof(Retransmission));
        incrementRetransmissionCounter(rtpkt->message_id);
      }
      }else{
        printf("---------------------ERROR------------------");
        printfflush();
      }
      
      
    }
    //sendRetransmissions();
  }

  event void AMControl.stopDone(error_t error) {
    // TODO Auto-generated method stub
  }

  event void AMControl.startDone(error_t error) {
    // TODO Auto-generated method stub
  }

  event message_t *Receive.receive(message_t * msg, void *payload,
                                   uint8_t len) {                        
                   BaseMessage *bm=(BaseMessage *) payload;                  
            //printf("Message_type is: %i \n",bm->message_type);    
            
                                                                                                           
    if (bm->message_type==LinkRequestId) {
      LinkRequest *hss = (LinkRequest *)payload;
       
      // printf("Got handshake message from: %i \n", call AMPacket.source(msg));
      // printf("message_id: %i \n", hss->message_id);
      // printf("Rssi: %i \n", call CC2420Packet.getRssi(msg));
      // printf("LQI: %i \n", call CC2420Packet.getLqi(msg));
      // printfflush();

      //if (!busy) {
        LinkResponse *qu = (LinkResponse *)(call Packet.getPayload(
            &pkt, sizeof(LinkResponse)));
        qu->message_type=LinkResponseId;
        qu->message_id = hss->message_id;
        qu->lqi = call CC2420Packet.getLqi(msg);
        qu->rssi = call CC2420Packet.getRssi(msg);

        printf("Sending linkresponse to: %i \n", call AMPacket.source(msg));
        printfflush();
        
        resendBool=TRUE;
        
        if (call AMSend.send(call AMPacket.source(msg), &pkt,
                             sizeof(LinkResponse)) == SUCCESS) {
          busy = TRUE;
          printf("Sent \n");
        }else{
          //Keep sending untill success
          sourceToSendTo=call AMPacket.source(msg);
          call RetryTimer.startOneShot(10);
        }
      //}

    } else if (bm->message_type == DataSendId||bm->message_type==DataRetransmissionId) {
      DataSend *data = (DataSend *)payload;
      int receivedId = data->message_id;

      // todo Check if this is a retransmission, these should not trigger other retransmissions
	  bool isRetransmission=bm->message_type==DataRetransmissionId;
	  if(find(receivedId)){
		  isRetransmission=TRUE;
		  remove(receivedId);
	  }
	 

      if ((1 + lastDataId) != receivedId && receivedId>lastDataId&& !firstDataReceive) {
        // Missed packages, use NAK
        int missing = (receivedId - lastDataId);
        int i;
        for (i = 1; i <= missing; i++) {
          // Write down the missing packages
          int id = lastDataId + i;
          insert(id);
		  //printf("id to add %i \n",id);
        }
        // Continue & forget the missing packages (we wrote them down)
        // printf("MISSED PACKAGES lastDataId was %i and receivedId was %i missing %i packages\n",
        //        lastDataId, receivedId, missing);
        // printfflush();
        if(!isRetransmission){			
        lastDataId = receivedId;
		}
      } else {
		  if(!isRetransmission){
        firstDataReceive=FALSE;			
        lastDataId = receivedId;
		}
        printf("Got data, temperature is: %i Message_ID is: %i message from: %i\n", data->data_part,data->message_id,call AMPacket.source(msg));
      }
	  
	  
	  //If this was not a retransmission, send retransmissions
	  if(!isRetransmission){		  
	  sendRetransmissions();
	  }
	  
    }
    return msg;
  }
}