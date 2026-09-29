function out = convex(x)
% CONVEX - WFG toolkit front shape (convex), x in [0,1]^M
out = fliplr(cumprod([ones(size(x,1),1), 1 - cos(x(:, 1:end-1) * pi/2)], 2)) .* ...
      [ones(size(x,1),1), 1 - sin(x(:, end-1:-1:1) * pi/2)];
end
