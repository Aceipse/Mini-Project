addpath('../math/');
%format compact
%format shortEng

interval = 3600;
n = 20;
inc = 0.01;

relayIdle = [];
relayPoweroff = [];

noRelayIdle5 = [];
noRelayIdle10 = [];
noRelaySleep5 = [];
for x = 0:inc:n
    relayIdle(end+1)        = comparingRelay(interval, 5, 0, true, false);
    relayPoweroff(end+1)    = comparingRelay(interval, 5, 0, true, true);
    
    noRelayIdle5(end+1)     = comparingRelay(interval, 5, x, false, false);
    noRelayIdle10(end+1)    = comparingRelay(interval, 10, x, false, false);
    noRelaySleep5(end+1)    = comparingRelay(interval, 5, x, false, true);
end

xaxis = 0:inc:n;

linewidth = 4;
figure; hold on
y1 = plot(xaxis, relayIdle, 'LineWidth', linewidth);        m1 = 'SC1: Relay receive idle 5ps'
y2 = plot(xaxis, relayPoweroff, 'LineWidth', linewidth);    m2 = 'SC2: Relay radio off 5ps'
y3 = plot(xaxis, noRelayIdle5, 'LineWidth', linewidth);     m3 = 'SC3: No relay receive idle 5ps'
y4 = plot(xaxis, noRelayIdle10, 'LineWidth', linewidth);    m4 = 'SC4: No relay receive idle 10ps'
y5 = plot(xaxis, noRelaySleep5, 'LineWidth', linewidth);    m5 = 'SC5: No relay radio off 5ps'
legend([y1; y2; y3; y4; y5], m1, m2, m3, m4, m5);


title('Energy consumption for time interval w/wo relay & different rates')
xlabel('Retransmission factor (only applied no relay)') % x-axis label
ylabel('Energy consumption for time interval (J)') % y-axis label