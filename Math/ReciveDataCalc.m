U_battery = 2.7;
t_0_recive_data = 10 * 10^-3;
U_shunt_recive_data = 216 * 10^-3;
U_mote_recive_data = U_battery - U_shunt_recive_data;
I_mote_recive_data = U_shunt_recive_data/R_shunt;
P_mote_recive_data = U_mote_recive_data*I_mote_recive_data
E_mote_recive_data = P_mote_recive_data * t_0_recive_data