function out = r_sum(y, w)
% R_SUM - WFG toolkit reduction function (weighted sum)
% y: [N x k] matrix, w: weight vector of length k
w = w(:).';
if numel(w) == 1
    w = ones(1, size(y,2));
end
out = sum(y .* repmat(w, size(y,1), 1), 2) / sum(w);
end
