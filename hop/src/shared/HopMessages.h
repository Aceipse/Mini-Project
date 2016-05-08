#ifndef HOP_MESSAGES_H
#define HOP_MESSAGES_H

//Messages for protocol
typedef nx_struct HandshakeSend {
  nx_uint16_t message_id;
} HandshakeSend;

typedef nx_struct HandshakeReceive {
  nx_uint16_t message_id;
  nx_uint16_t receiver_id;
  nx_uint16_t lqi;
  nx_uint16_t rssi;
  nx_uint16_t tx;
} HandshakeReceive;

/*typedef  nx_struct DataSend {
message\_id
sender\_id
via\_id
receiver\_id
data\_counter
data\_part
} DataSend;*/

/* typedef  nx_struct DataReceive {
message\_id
sender\_id
receiver\_id
(lqi
rssi
tx)?
data\_hash?
} DataReceive; */

#endif /* HOP_MESSAGES_H */