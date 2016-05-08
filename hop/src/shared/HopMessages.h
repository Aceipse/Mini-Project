#ifndef HOP_MESSAGES_H
#define HOP_MESSAGES_H

//Messages for protocol
typedef nx_struct handshake_Send {
  nx_uint16_t message_id;
  nx_uint16_t sender_id;
  nx_uint16_t receiver_id;
} HandshakeSend;

typedef nx_struct handshake_Receive {
  nx_uint16_t message_id;
  nx_uint16_t sender_id;
  nx_uint16_t receiver_id;
  nx_uint16_t lqi;
  nx_uint16_t rssi;
  nx_uint16_t tx;
} HandshakeReceive;

typedef  nx_struct data_send {/*
 * message\_id
sender\_id
via\_id
receiver\_id
data\_counter
data\_part*/
} data_send;

typedef  nx_struct data_receive {
/*message\_id
sender\_id
receiver\_id
(lqi
rssi
tx)?
data\_hash?*/
} data_receive;

#endif /* HOP_MESSAGES_H */
