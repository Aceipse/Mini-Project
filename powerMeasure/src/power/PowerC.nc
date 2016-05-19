#include "../shared/HopMessages.h"
#include "ewma.h"
#include "TransmissionObj.h"
#include "printf.h"
#include <stdio.h>

// Power debug
#define POWER 3
#define TIMER_MS 1000

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
  bool EWMA_DEBUG = TRUE;

  struct EwmaObj ewma1;
  struct EwmaObj ewma2;
  
  int testData = 1;
  int integerPrint = -1;  //because we cant print double

  /*
  // EWMA begin
  // see example http://www.itl.nist.gov/div898/handbook/pmc/section3/pmc324.htm
  int ewmaIdx = 0;
  double ewma = 0;
  double ewmaHis = 0;
  double ewmaVal(double cur) {
    ewma = LAMBDA * cur + (1 - LAMBDA) * ewmaHis;
    ewmaHis = ewma;

    ewmaIdx = (ewmaIdx + 1) % WIDTH;
    return ewma;
  }
  // EWMA end
  */

  event void Boot.booted() {
    call CC2420Packet.setPower(&pkt, POWER);

    // Initiate with sensible, or average over some values
    ewma1.his = 50;
    ewma1.cur = 0;
    
    ewma2.his = 50;
    ewma2.cur = 0;
    
    if (!TURN_ON_RADIO && (SEND || RECEIVE)) {
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
        LinkRequest* qu =
            (LinkRequest*)(call Packet.getPayload(&pkt, sizeof(LinkRequest)));
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
    if (EWMA_DEBUG) {
      
      testData = testData == 1 ? 2 : 1;
      printf("testData %i\n", testData);
      ewmaVal(&ewma1, testData);      
      integerPrint = ewma1.cur * 100;
      printf("ewma1 cur %i\n\n", integerPrint);

      printfflush();

      /*double dCur = ewmaIdx % 2 == 0 ? -4 : 5;
      int iCur = dCur * 1;

      double dEmwa = ewmaVal(dCur);
      int iEmwa = dEmwa * 1;  // retain two decimals

      printf("ewmaIdx %i\n", ewmaIdx);
      printf("Current value is %i and EMWA value is %i. Diff %i\n", iCur, iEmwa,
             (iCur - iEmwa));

      printfflush();*/
    }
  }

  event message_t* Receive.receive(message_t * msg, void* payload,
                                   uint8_t len) {
    printf("Receive data\n");
    printfflush();

    return msg;
  }
}