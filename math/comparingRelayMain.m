addpath('../math/');
format compact
format shortEng

syms re

inte = 3600;
rate = 5; %pr. second
energyRelay = comparingRelay(inte, rate, 0, true)
energyNoRelay = comparingRelay(inte, rate, 20, false)