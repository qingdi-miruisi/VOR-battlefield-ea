function [F, G] = EMOObjectives(id, x, M, D)
% EMOOBJECTIVES - EMO family (Fleming & Purshouse) objective + constraint
%   id: 1..11
%   x:  1xD row vector in [0,1]^D
%   M:  number of objectives
%   D:  number of decision variables
%   F:  1xM row vector of objectives (minimization, can be negative)
%   G:  constraint violation (0 = feasible)
%
% Source: P. Purshouse and R. Fleming, "Evolutionary many-objective
% optimisation: A comparative study," EMO 2007 (companion paper
% "Many-objective test problems" with 11 EMO variants).
%
%   EMO1-4 : f_i(x) = 1 - exp(-x_i + b_i),  i = 1..M
%   EMO5   : f_i(x) = 1 - exp(-g(x) + i/M),  g(x) = sum_j x_j^2
%   EMO6-11: f_i(x) = 1 - exp(-g(x) + i/M),  g(x) = sum_j x_j^2
%            constraint: sum(x) = M (EMO6-11)

    M = max(M, 2);
    switch id
        case 1
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-x(i) + 0);
            end
            G = 0;
        case 2
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-x(i) + 1);
            end
            G = 0;
        case 3
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-x(i) + 2);
            end
            G = 0;
        case 4
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-2*x(i) + 0.5);
            end
            G = 0;
        case 5
            g = sum(x(1:D).^2);
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-g + i/M);
            end
            G = 0;
        case 6
            g = sum(x(1:D).^2);
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-g + i/M);
            end
            G = M - sum(x(1:M));
        case 7
            g = sum(x(1:D).^2);
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-g + i/M);
            end
            G = M - sum(x(1:M).^2);
        case 8
            g = sum(x(1:D).^2);
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-g + i/M);
            end
            G = M - prod(x(1:M));
        case 9
            g = sum(x(1:D).^2);
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-g + i/M);
            end
            G = M - sum(x(1:M).^2) - M;
        case 10
            g = sum(x(1:D).^2);
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-g + i/M);
            end
            G = M - prod(x(1:M)) - M;
        case 11
            g = sum(x(1:D).^3);
            F = zeros(1, M);
            for i = 1:M
                F(i) = 1 - exp(-g + i/M);
            end
            G = M - sum(x(1:M).^3) - M;
        otherwise
            error('Unknown EMO id %d', id);
    end
end
