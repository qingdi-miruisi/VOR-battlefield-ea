function nd = NDSortAll(F)
% NDSORTALL - indices of all non-dominated points in F (level-1 set)
% Vectorized dominance test (no per-point loop):
%   dom(i,j) = true iff point j dominates point i
%             iff F(j,k) <= F(i,k) for every objective k, and
%                F(j,k) <  F(i,k) for at least one objective k.
% Memory: O(n^2 * M) booleans — fine for n <= ~20000 with M <= 30.
n = size(F, 1); m = size(F, 2);
leq = true(n, n);
strict = false(n, n);
for k = 1:m
    col = F(:, k);                 % n x 1
    Fi = repmat(col,  1, n);       % Fi(i,j) = F(i,k)
    Fj = repmat(col', n, 1);       % Fj(i,j) = F(j,k)
    leq    = leq    & (Fj <= Fi);  % all-objs F(j,k) <= F(i,k)
    strict = strict | (Fj <  Fi);  % any-obj  F(j,k) <  F(i,k)
end
dom = leq & strict;
dom(logical(eye(n))) = false;
nd = find(~any(dom, 2));
end
