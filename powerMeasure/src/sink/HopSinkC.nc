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
  uses interface Timer<TMilli> as Timer0;
}
implementation {

  message_t pkt;
  bool busy = FALSE;
  int timerMs = 1000;

  // test scenarios
  bool SEND = TRUE;
  bool RECEIVE = FALSE;
  bool TURN_OFF_RADIO = FALSE;
  bool TURN_ON_RADIO = FALSE;

  event void Boot.booted() {
    call CC2420Packet.setPower(&pkt, 3);

    if (!TURN_ON_RADIO) {
      call AMControl.start();
    } else {
      call Timer0.startPeriodic(timerMs);
    }
    // printf("Inside Boot.Booted\n");

    // printfflush();
  }

  event void AMSend.sendDone(message_t * msg, error_t error) {
    if (&pkt == msg) {
      busy = FALSE;
      // printf("Power level %i\n", call CC2420Packet.getPower(msg));
    }
  }

  event void AMControl.stopDone(error_t error) {
    // TODO Auto-generated method stub
  }

  event void AMControl.startDone(error_t error) {
    if (!TURN_ON_RADIO) {
      call Timer0.startPeriodic(timerMs);
    }
  }

  event void Timer0.fired() {
    /*printf("Size of message_t %i\n", sizeof(pkt));
    printf("Size of bool %i\n", sizeof(busy));*/

    if (SEND) {
      // Also listening
      if (!busy) {
        LinkRequest *qu =
            (LinkRequest *)(call Packet.getPayload(&pkt, sizeof(LinkRequest)));
        qu->message_id = 1;
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(LinkRequest)) ==
            SUCCESS) {
          busy = TRUE;
        }
      }
    } else if (RECEIVE) {
      // Already listening
    } else if (TURN_OFF_RADIO) {
      call AMControl.stop();
      // Power usage after stop?
    } else if (TURN_ON_RADIO) {
      call AMControl.start();
      // Power usage after start?
    }
  }

  event message_t *Receive.receive(message_t * msg, void *payload,
                                   uint8_t len) {
    // printf("Receive Martin data\n");
    return msg;
  }
}