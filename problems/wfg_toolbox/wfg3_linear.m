function out = wfg3_linear(x)
% WFG3_LINEAR - WFG3 front shape (linear)
out = fliplr(cumprod([ones(size(x,1),1), x(:, 1:end-1)], 2)) .* ...
      [ones(size(x,1),1), 1 - x(:, end-1:-1:1)];
end