U_battery = 2.8;
t_0_send = 10 * 10^-3;
U_shunt_send = 187 * 10^-3;
R_shunt = 10;
U_mote_send = U_battery - U_shunt_send;
I_mote_send = U_shunt_send/R_shunt;
P_mote_send = U_mote_send*I_mote_send
E_mote_send = P_mote_send * t_0_send

