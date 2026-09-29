function out = disc(x)
% DISC - WFG toolkit front shape (disconnected)
out = 1 - x(:,1) .* (cos(5*pi*x(:,1))).^2;
end