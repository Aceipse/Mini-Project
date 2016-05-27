U_battery = 3.09;
t_0_radio_off = 10 * 10^-3;
U_shunt_radio_off = 1.37 * 10^-3;
U_mote_radio_off = U_battery - U_shunt_radio_off;
I_mote_radio_off = U_shunt_radio_off/R_shunt;
P_mote_radio_off = U_mote_radio_off*I_mote_radio_off
E_mote_radio_off = P_mote_radio_off * t_0_radio_off