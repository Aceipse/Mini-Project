send = 49*10^-3;
idle = 51*10^-3;
recive = 54*10^-3;
overhear = 51*10^-3;

t_send = 10*10^-3;
t_recive = 10*10^-3;
t_overhear = 3*10^-3;

time = 4*t_send+6*t_recive+2*t_overhear
consumption = send*t_send*4+recive*t_recive*6+overhear*t_overhear*2

extra_consumption = consumption - (idle*t_send*4+idle*t_recive*6+idle*t_overhear*2)

b_on_consumption = idle*3