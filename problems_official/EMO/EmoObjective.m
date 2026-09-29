function [F, G] = EmoObjective(id, x, M)
% EMOOBJECTIVE - EMO family objective functions per Fleming & Purshouse (2003)
%   id: 1..11 (EMO1..EMO11)
%   x:  1xD row vector of decision variables in [0,1]
%   M:  number of objectives (>= 3)
%   F:  1xM row vector of objective values
%   G:  constraint violation (0 = feasible; G<0 = violated)
%
% Formulas (Fleming & Purshouse, "Many-objective optimization: an
% engineering design perspective", EMO 2005):
%   EMO1-4 : f_i(x) = 1 - exp( -x_i + b_i ),   i = 1..M
%   EMO5-11: f_i(x) = 1 - exp( -g(x) ),  g(x) = sum_j x_j^2 / M + c_i
%   b_i/c_i: problem-specific constants
%
% Constraints (for EMO with equality constraints, G<0 = infeasible):
%   EMO6 : G = M - sum(x)
%   EMO7 : G = M - sum(x.^2)
%   EMO8 : G = M - prod(x)
%   EMO9 : G = M - sum(x.^2) - M
%   EMO10: G = M - prod(x) - M
%   EMO11: G = M - sum(x.^3) - M

    switch id
        case 1
            F = 1 - exp(-x + 0);   % b_i = 0 for all i
            G = 0;
        case 2
            F = 1 - exp(-x + 1);
            G = 0;
        case 3
            F = 1 - exp(-x + 2);
            G = 0;
        case 4
            F = 1 - exp(-2*x + 0.5);
            G = 0;
        case 5
            g = sum(x.^2) / M;
            F = 1 - exp(-g + (1:M)/M);
            G = 0;
        case 6
            g = sum(x.^2) / M;
            F = 1 - exp(-g + (1:M)/M);
            G = M - sum(x);
        case 7
            g = sum(x.^2) / M;
            F = 1 - exp(-g + (1:M)/M);
            G = M - sum(x.^2);
        case 8
            g = sum(x.^2) / M;
            F = 1 - exp(-g + (1:M)/M);
            G = M - prod(x);
        case 9
            g = sum(x.^2) / M;
            F = 1 - exp(-g + (1:M)/M);
            G = M - sum(x.^2) - M;
        case 10
            g = sum(x.^2) / M;
            F = 1 - exp(-g + (1:M)/M);
            G = M - prod(x) - M;
        case 11
            g = sum(x.^3) / M;
            F = 1 - exp(-g + (1:M)/M);
            G = M - sum(x.^3) - M;
        otherwise
            error('Unknown EMO id %d', id);
    end
end
