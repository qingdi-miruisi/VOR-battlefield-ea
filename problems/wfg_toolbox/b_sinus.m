function out = b_sinus(y, a)
% B_SINUS - WFG shaping function b (sinusoidal)
out = (1 - 4 * sin(pi * y) .^ (1/a)) / (1 - 4 * sin(pi * a) .^ (1/a));
end