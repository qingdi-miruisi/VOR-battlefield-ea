function out = mixed(x)
% MIXED - WFG toolkit front shape (mixed convex/disconnected)
out = 1 - x(:,1) - cos(10 * pi * x(:,1) + pi/2) / (10 * pi);
end