U_battery = 3.09;
t_0_send = 10 * 10^-3;
U_shunt_send = 227 * 10^-3;
R_shunt = 10;
U_mote_send = U_battery - U_shunt_send;
I_mote_send = U_shunt_send/R_shunt;
P_mote_send = U_mote_send*I_mote_send
E_mote_send = P_mote_send * t_0_send

t_0_recive_Idle = 1;
U_shunt_recive_Idle = 192 * 10^-3;
U_mote_recive_Idle = U_battery - U_shunt_recive_Idle;
I_mote_recive_Idle = U_shunt_recive_Idle/R_shunt;
P_mote_recive_Idle = U_mote_recive_Idle*I_mote_recive_Idle
E_mote_recive_Idle = P_mote_recive_Idle * t_0_recive_Idle

t_0_recive_data = 3.5 * 10^-3;
U_shunt_recive_data = 227 * 10^-3;
U_mote_recive_data = U_battery - U_shunt_recive_data;
I_mote_recive_data = U_shunt_recive_data/R_shunt;
P_mote_recive_data = U_mote_recive_data*I_mote_recive_data
E_mote_recive_data = P_mote_recive_data * t_0_recive_data

