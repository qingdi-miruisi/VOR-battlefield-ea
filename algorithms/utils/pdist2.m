function D = pdist2(X, Y, metric, opts)
% PDIST2 - pairwise distances between rows of X and rows of Y
% Supports 'euclidean' (default) and 'cosine'.
if nargin < 3
    metric = 'euclidean';
end
N = size(X,1); P = size(Y,1); M = size(X,2);
switch lower(metric)
    case {'euclidean',''}
        AX2 = sum(X.^2,2);
        AY2 = sum(Y.^2,2);
        D2 = max(AX2 + AY2' - 2*X*Y', 0);
        D = sqrt(D2);
    case 'cosine'
        NX = X ./ max(sqrt(sum(X.^2,2)), 1e-14);
        NY = Y ./ max(sqrt(sum(Y.^2,2)), 1e-14);
        cosSim = NX * NY';
        D = acos(min(1, max(-1, cosSim)));
    case 'minkowski'
        % AGEMOEA always calls with p=2 (L2), which equals Euclidean
        AX2 = sum(X.^2,2);
        AY2 = sum(Y.^2,2);
        D2 = max(AX2 + AY2' - 2*X*Y', 0);
        D = sqrt(D2);
    otherwise
        error('pdist2:unknownMetric', ['metric=' metric ' not supported']);
end

function n = norms(A, k)
    n = sqrt(sum(A.^2, k));
