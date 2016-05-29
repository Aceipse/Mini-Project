format shortEng

%watt
p_send = 0.049;
p_receive = 0.054;
p_receive_idle = 0.051;
p_overhear = 0.051;
p_radio_off = 0.0004;

%second
t_send = 0.01;
t_receive = 0.01;
t_overhear = 0.003;

%retransmission time seconds and energy in joules for system summation of all nodes usages
t_retrans_relay_sys = 4*t_send+6*t_receive+2*t_overhear;
t_retrans_sys = 2*t_send+2*t_receive;

e_retrans_relay_sys = 4*t_send*p_send+6*t_receive*p_receive+2*t_overhear*p_overhear;
e_retrans_sys =2*t_send*p_send+2*t_receive*p_receive;

%send time in seconds and energy in joules for single packet summation of all nodes usage
t_send_relay_sys = 2*t_send + 3*t_receive + 1*t_overhear;
t_send_sys = 1*t_send + 1*t_receive;

e_send_relay_sys = 2*t_send*p_send + 3*t_receive*p_receive + 1*t_overhear*p_overhear;
e_send_sys = 1*t_send*p_send + 1*t_receive*p_receive;

%considering a specific interval in seconds with 5 packages pr. second send 
%START configure 
interval = 3600;
rate = 5/1;
re_relay = 1; %(re-1) is % requested retransmissions from c
re = 1;
%STOP configure

%consider the total node time (num_motes*interval), remove node time used
%on sending and retransmissions and find the energy used for being
%idle_receive in interval. Then add the energy used for the sending 
%operation for the system.

num_packages = rate * interval;   %all packages in interval
num_relay_retrans = num_packages*re_relay-num_packages %number of retransmissions with relay
num_retrans = num_packages*re-num_packages %number of retransmissions wihtout relay

num_motes_relay = 3;
num_motes = 2;

%RELAY
t_relay_sys_idle = num_motes_relay*interval - t_send_relay_sys*num_packages - t_retrans_relay_sys*num_relay_retrans;
%assert(t_relay_sys_idle>0)
e_relay_sys = t_relay_sys_idle*p_receive_idle + e_send_relay_sys*num_packages + e_retrans_relay_sys*num_relay_retrans

%NO RELAY
t_sys_idle = num_motes*interval - t_send_sys*num_packages - t_retrans_sys*num_retrans;
%assert(t_sys_idle>0)
e_sys = t_sys_idle*p_receive_idle + e_send_sys*num_packages + e_retrans_sys*num_retrans

%plot

