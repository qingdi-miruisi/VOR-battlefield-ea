function out = s_multi(y, A, B, C)
% S_MULTI - WFG shaping function s (multi-modal)
out = (1 + cos((4*A + 2) * pi * (0.5 - abs(y - C)/2./(floor(C - y) + C))) ...
       + 4*B*(abs(y - C)/2./(floor(C - y) + C)).^2) / (B + 2);
end