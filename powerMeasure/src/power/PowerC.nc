#include "../shared/HopMessages.h"
#include "TransmissionObj.h"
#include "printf.h"
#include <stdio.h>

// Power debug
#define POWER 3
#define TIMER_MS 1000

// EWMA
// how much the current value should count (1-LAMBDA is history)
#define LAMBDA 0.3
// how much history to consider
#define WIDTH 5

module PowerC {
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
  int i = 0;

  // Test scenarios
  bool SEND = FALSE;
  bool RECEIVE = FALSE;
  bool TURN_OFF_RADIO = FALSE;
  bool TURN_ON_RADIO = FALSE;
  bool EWMA = TRUE;

  // EWMA begin
  // see example http://www.itl.nist.gov/div898/handbook/pmc/section3/pmc324.htm
  double test_data[21] = {52.0, 47.0, 53.0, 49.3, 50.1, 47.0, 51.0,
                          50.1, 51.2, 50.5, 49.6, 47.6, 49.9, 51.3,
                          47.8, 51.2, 52.6, 52.4, 53.6, 52.1};
  double test_cmp[21] = {50.00, 50.60, 49.52, 50.56, 50.18, 50.16, 49.21,
                         49.75, 49.85, 50.26, 50.33, 50.11, 49.36, 49.52,
                         50.05, 49.38, 49.92, 50.73, 51.23, 51.94, 51.99};
  int testIdx = 0;

  int ewma[WIDTH]; // todo initate with something sensible
  int ewma_i = 0;

  double ewmaVal(double cur) {
    // Historical average
    double avg = 0;
    for (i = 0; i < WIDTH; i++) {
      avg += ewma[i];
    }
    avg /= WIDTH;

    // Cur is now historical
    ewma[ewma_i] = cur;
    ewma_i = (ewma_i + 1) % WIDTH;

    // Return EWMA value
    return LAMBDA * cur + (1 - LAMBDA) * avg;
  }
  // EWMA end

  event void Boot.booted() {
    call CC2420Packet.setPower(&pkt, POWER);

    for (i = 0; i < WIDTH; i++) {
      ewma[i] = 50; // init with something sensible
    }

    if (!TURN_ON_RADIO) {
      call AMControl.start();
    } else {
      call Timer0.startPeriodic(TIMER_MS);
    }
    printf("Inside Boot.Booted\n");

    printfflush();
  }

  event void AMSend.sendDone(message_t * msg, error_t error) {
    if (&pkt == msg) {
      busy = FALSE;
      printf("Power level %i\n", call CC2420Packet.getPower(msg));
    }
  }

  event void AMControl.stopDone(error_t error) {
    // TODO Auto-generated method stub
  }

  event void AMControl.startDone(error_t error) {
    if (!TURN_ON_RADIO) {
      call Timer0.startPeriodic(TIMER_MS);
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
    }
    if (RECEIVE) {
      // Already listening
    }
    if (TURN_OFF_RADIO) {
      call AMControl.stop();
      // Power usage after stop?
    }
    if (TURN_ON_RADIO) {
      call AMControl.start();
      // Power usage after start?
    }
    if (EWMA) {
      double dCur = test_data[testIdx];
      int iCur = dCur * 100;

      double dEmwa = ewmaVal(dCur);
      int iEmwa = dEmwa * 100; // retain two decimals

      int iCmp = test_cmp[testIdx] * 100;
      testIdx = (testIdx + 1) % 21;

      printf("TestIdx %i\n", testIdx);
      printf("Current value is %i and EMWA value is %i. Diff %i\n", iCur, iEmwa,
             (iCur - iEmwa));
      printf("Diff my EMWA and book %i\n\n",
             (iEmwa - iCmp)); // only makes sense up till testIdx = 20

      printfflush();
    }
  }

  event message_t *Receive.receive(message_t * msg, void *payload,
                                   uint8_t len) {
    printf("Receive data\n");
    printfflush();

    return msg;
  }
}