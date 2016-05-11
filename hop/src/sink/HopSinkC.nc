#define LISTSIZE 100

#include "../shared/HopMessages.h"
#include "TransmissionObj.h"
#include "printf.h"
#include <stdio.h>

module HopSinkC {
  uses interface Boot;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  uses interface Receive;
  uses interface CC2420Packet;
}
implementation {

  message_t pkt;
  bool busy = FALSE;
  int lastDataId = -1;

  // LIST LOGIC
  int c = 0;
  RetransmissionObj *list[LISTSIZE];

  void insert(RetransmissionObj * item) {
    int i;
    for (i = 0; i < LISTSIZE; i++) {
      if (list[i] == NULL) {
        list[i] = item;
        /*list[i]->message_id = item->message_id;
        list[i]->retries = item->retries;*/
        return;
      }
    }
    list[0] = item; // override first value
  }

  void remove(nx_uint16_t id) {
    int i;
    for (i = 0; i < LISTSIZE; i++) {
      if (list[i]->message_id == id) {
        list[i] = NULL;
        return;
      }
    }
    printf("Could not remove");
    printfflush();
  }
  //

  event void Boot.booted() {

    call AMControl.start();
    printf("Inside Boot.Booted\n");
    printfflush();
  }

  event void AMSend.sendDone(message_t * msg, error_t error) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

  event void AMControl.stopDone(error_t error) {
    // TODO Auto-generated method stub
  }

  event void AMControl.startDone(error_t error) {
    // TODO Auto-generated method stub
  }

  event message_t *Receive.receive(message_t * msg, void *payload,
                                   uint8_t len) {
    if (len == sizeof(LinkRequest)) {
      LinkRequest *hss = (LinkRequest *)payload;

      printf("Got handshake message from: %i \n", call AMPacket.source(msg));
      printf("message_id: %i \n", hss->message_id);
      printf("Rssi: %i \n", call CC2420Packet.getRssi(msg));
      printf("LQI: %i \n", call CC2420Packet.getLqi(msg));
      printfflush();

      if (!busy) {
        LinkResponse *qu = (LinkResponse *)(call Packet.getPayload(
            &pkt, sizeof(LinkResponse)));
        qu->message_id = hss->message_id;
        qu->lqi = call CC2420Packet.getLqi(msg);
        qu->rssi = call CC2420Packet.getRssi(msg);
        qu->tx = 0;

        printf("Sending receive to: %i \n", call AMPacket.source(msg));
        printfflush();
        if (call AMSend.send(call AMPacket.source(msg), &pkt,
                             sizeof(LinkResponse)) == SUCCESS) {
          printf("Sent \n");
          busy = TRUE;
        }
      }

    } else if (len == sizeof(DataSend)) {
      DataSend *data = (DataSend *)payload;
      int receivedId = data->message_id;

      // todo Check if this is a retransmission

      if ((1 + lastDataId) != receivedId) {
        // Missed packages, use NAK
        int missing = (receivedId - lastDataId);
        int i;
        for (i = 1; i <= missing; i++) {
          // Write down the missing packages
          int id = (lastDataId + i);
          RetransmissionObj *ro;
          ro->message_id = id;
          ro->retries = 0;
          insert(ro);
        }
        // Continue & forget the missing packages (we wrote them down)
        lastDataId = receivedId;
      } else {
        lastDataId = receivedId;
        printf("Got data, temperature is: %i", data->data_part);
      }
    }
    return msg;
  }
}