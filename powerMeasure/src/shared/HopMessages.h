#ifndef HOP_MESSAGES_H
#define HOP_MESSAGES_H

// Messages for protocol

//Request link quality
typedef nx_struct LinkRequest { nx_uint16_t message_id; }
LinkRequest;

//Respond the link quality
typedef nx_struct LinkResponse {
  nx_uint16_t message_id;
  nx_uint16_t sender_id;
  nx_uint16_t receiver_id;
  nx_uint16_t lqi;
  nx_uint16_t rssi;
  nx_uint16_t tx;
}
LinkResponse;

//Data being sent
typedef nx_struct DataSend {
  nx_uint16_t message_id;
  nx_uint16_t data_counter;
  nx_uint16_t data_part;
}
DataSend;

//Retransmission is used as NAK but also to passively detect link quality
typedef nx_struct Retransmission {
  nx_uint16_t message_id;
  nx_uint16_t lqi;
  nx_uint16_t rssi;
}
Retransmission;



/*typedef  nx_struct DataReceive {
nx_uint16_t message\_id
nx_uint16_t sender\_id
nx_uint16_t receiver\_id
(lqi
rssi
tx)?
data\_hash?
} DataReceive; */

#endif /* HOP_MESSAGES_H */