#ifndef HOP_MESSAGES_H
#define HOP_MESSAGES_H

//Messages for protocol
typedef nx_struct handshake_send {
nx_uint8_t message_id;
nx_uint8_t sender_id;
nx_uint8_t receiver_id;
} handshake_send;

typedef nx_struct handshake_receive {
	/*message\_id
sender\_id
receiver\_id
lqi
rssi
tx*/
} handshake_receive;

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
