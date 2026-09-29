function out = s_linear(y, A)
% S_LINEAR - WFG shaping function s (linear)
out = abs(y - A) ./ abs(floor(A - y) + A);
end