function out = b_flat(y, A, B, C)
% B_FLAT - WFG toolkit shaping function b (flat)
% Element-wise: y may be a matrix, A/B/C are scalars.
out = A + min(0, floor(y - B)) .* A .* (B - y) / B ...
      - min(0, floor(C - y)) .* (1 - A) .* (y - C) / (1 - C);
out = round(out * 1e4) / 1e4;
end
