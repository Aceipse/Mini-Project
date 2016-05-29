addpath('../math/');
format compact
format shortEng

inte = 3600;
rate = 5; %pr. second

n = 20;
inc = 0.1;
y1 = [];
for x = 0:inc:n
    y1(end+1) = comparingRelay(inte, rate, x, false);
end

y2 = comparingRelay(inte, rate, 0, true);
y2line = (ones(length(y1),1)*y2)';

xaxis = 0:inc:n;

figure
plot(xaxis, y1, xaxis, y2line)
title('Energy consumption in chosen time interval with or without relay changing retransmissions rate')
xlabel('Retransmission rate 0 = no retransmissions. 1 = retransmit all once.') % x-axis label
ylabel('Energy consumption for time interval (J)') % y-axis label