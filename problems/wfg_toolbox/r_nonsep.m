function out = r_nonsep(y, w)
% R_NONSEP - WFG toolkit reduction function (non-separable, with b_poly)
[~, n] = size(y);
if n > 1
    for j = 1 : n
        w(j) = max(0, (w(j) + sum(y(:, 1:j-1), 2)) / (j + 1));
    end
end
out = y(:, n) * w(n);
end