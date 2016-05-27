U_battery = 2.7;
t_0_recive_Idle = 1;
U_shunt_recive_Idle = 202 * 10^-3;
U_mote_recive_Idle = U_battery - U_shunt_recive_Idle;
I_mote_recive_Idle = U_shunt_recive_Idle/R_shunt;
P_mote_recive_Idle = U_mote_recive_Idle*I_mote_recive_Idle
E_mote_recive_Idle = P_mote_recive_Idle * t_0_recive_Idle

