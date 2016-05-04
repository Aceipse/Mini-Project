 #ifndef SOURCENODE_H
 #define SOURCENODE_H
 
enum {
  AM_BLINKTORADIO = 6,
  TIMER_PERIOD_MILLI = 250
};
 
typedef nx_struct HandshakeSend {
  nx_uint16_t message_id;
  nx_uint16_t sender_id;
  nx_uint16_t receiver_id;
} HandshakeSend;

typedef nx_struct HandshakeReceive {
  nx_uint16_t message_id;
  nx_uint16_t sender_id;
  nx_uint16_t receiver_id;
  nx_uint16_t lqi;
  nx_uint16_t rssi;
  nx_uint16_t tx;
} HandshakeReceive;

 #endif
