addpath('../math/');
format compact
format shortEng

inte = 3600;
rate = 5; %pr. second

n = 20;
inc = 0.1;
y1 = [];
y2 = [];
for x = 0:inc:n
    y1(end+1) = comparingRelay(inte, rate, x, false);
    %change 0 to e.g. x/5 to model relay removes need for retransmission by
    %factor 5 compared to no relay
    y2(end+1) = comparingRelay(inte, rate, 0, true);
end

y1 = y1'
y2 = y2'

xaxis = 0:inc:n;

figure
plot(xaxis, y1, xaxis, y2)
title('Energy consumption in chosen time interval with or without relay changing retransmissions rate')
xlabel('Retransmission rate 0 = no retransmissions. 1 = retransmit all once.') % x-axis label
ylabel('Energy consumption for time interval (J)') % y-axis label