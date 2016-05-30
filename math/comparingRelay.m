function [ energy ] = comparingRelay(inter, prate, retransmissions, relay)

%Power usages (W)
p_send = 0.049;
p_receive = 0.054;
p_receive_idle = 0.051;
p_overhear = 0.0525;
p_radio_off = 0.0004;

%Time usages (s)
t_send = 0.01;
t_receive = 0.01;
t_overhear = 0.003;

%Retransmission time (s) & and energy (J) for system summation of all nodes usages
t_retrans_relay_sys = 4*t_send+6*t_receive+2*t_overhear;
t_retrans_sys = 2*t_send+2*t_receive;

e_retrans_relay_sys = 4*t_send*p_send+6*t_receive*p_receive+2*t_overhear*p_overhear;
e_retrans_sys =2*t_send*p_send+2*t_receive*p_receive;

%Send time (s) & energy (J) for single packet (128 bytes), summation of all nodes usage
t_send_relay_sys = 2*t_send + 3*t_receive + 1*t_overhear;
t_send_sys = 1*t_send + 1*t_receive;

e_send_relay_sys = 2*t_send*p_send + 3*t_receive*p_receive + 1*t_overhear*p_overhear;
e_send_sys = 1*t_send*p_send + 1*t_receive*p_receive;

%Considering a specific interval in seconds with rate packages pr. second
%START configure
interval = inter;
rate = prate;

% percentage retransmissions e.g. 0.2 = 20 % retransmissions of total amount of packages
re_relay = retransmissions; 
re = retransmissions;
%STOP configure

%consider the total node time (num_motes*interval), remove node time used
%on sending and retransmissions and find the energy used for being
%idle_receive in interval. Then add the energy used for the sending
%operation and for retransmission.

num_packages = rate * interval;             %all packages in interval
num_relay_retrans = num_packages*re_relay;  %number of retransmissions with relay
num_retrans = num_packages*re;              %number of retransmissions wihtout relay

num_motes_relay = 3;
num_motes = 2;

%RELAY
t_relay_sys_idle = num_motes_relay*interval - t_send_relay_sys*num_packages - t_retrans_relay_sys*num_relay_retrans;
if(t_relay_sys_idle < 0)
    %doing the operations will take longer than interval, but we only
    %consider energy spent.
    t_relay_sys_idle = 0;
    msg = ['Too many retransmissions for interval. retransmissions value is', num2str(re_relay)];
    disp(msg)
end
e_relay_sys = t_relay_sys_idle*p_receive_idle + e_send_relay_sys*num_packages + e_retrans_relay_sys*num_relay_retrans;

%NO RELAY (relay is asleep)
t_sys_idle = num_motes*interval - t_send_sys*num_packages - t_retrans_sys*num_retrans;
if(t_sys_idle < 0)
    t_sys_idle = 0;
    msg = ['Too many retransmissions for interval. retransmissions value is', num2str(re)];
    disp(msg)
end
e_sys = t_sys_idle*p_receive_idle + e_send_sys*num_packages + e_retrans_sys*num_retrans + interval*p_radio_off;

if(relay)
    energy=e_relay_sys;
else
    energy=e_sys;
end

end


