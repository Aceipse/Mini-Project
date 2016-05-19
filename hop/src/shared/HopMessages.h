#ifndef HOP_MESSAGES_H
#define HOP_MESSAGES_H

// Messages for protocol

//Request link quality
typedef nx_struct LinkRequest {
  nx_uint16_t message_type; 
  nx_uint16_t message_id; 
}
LinkRequest;

//Respond the link quality
typedef nx_struct LinkResponse {
  nx_uint16_t message_type;
  nx_uint16_t message_id;
  nx_uint16_t lqi;
  nx_int16_t rssi;
}
LinkResponse;

//Data being sent
typedef nx_struct DataSend {
  nx_uint16_t message_type;
  nx_uint16_t message_id;
  nx_uint16_t data_counter;
  nx_uint16_t data_part;
}
DataSend;

//Retransmission is used as NAK but also to passively detect link quality
typedef nx_struct Retransmission {
  nx_uint16_t message_type;
  nx_uint16_t message_id;
  nx_uint16_t lqi;
  nx_int16_t rssi;
}
Retransmission;

//This is basemessage for all messages
typedef nx_struct BaseMessage{
  nx_uint16_t message_type;
} BaseMessage;
enum {
  LinkRequestId=1,
  LinkResponseId=2,
  DataSendId=3,
  RetransmissionId=4,
  DataRetransmissionId=5  
};

#endif /* HOP_MESSAGES_H */