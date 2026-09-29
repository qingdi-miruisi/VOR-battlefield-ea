function p = wilcoxon_test(x, y)
% WILCOXON_TEST - Wilcoxon rank-sum (Mann-Whitney U) two-sided p-value
% x, y: two independent sample column vectors; returns two-sided p (normal approx).

    n1 = numel(x); n2 = numel(y);
    allv = [x; y];
    [sorted, rankOrd] = sort(allv);
    % tie handling: average ranks
    ranks = zeros(1, numel(allv));
    i = 1;
    while i <= numel(allv)
        j = i;
        while j < numel(allv) && sorted(j+1) == sorted(j)
            j = j + 1;
        end
        avgRank = (i + j) / 2;
        ranks(rankOrd(i:j)) = avgRank;
        i = j + 1;
    end
    R1 = sum(ranks(1:n1));
    mu = n1 * (n1 + n2 + 1) / 2;
    % tie correction：对【排序后】的唯一值求频次
    [ty, ~, icnt] = unique(sorted);
    cnt = accumarray(icnt, 1);            % 每个唯一值在 sorted 中出现的次数
    sigma2 = n1*n2/12 * (n1 + n2 + 1) - n1*n2/12 * sum(cnt.^2 .* (cnt - 1));
    sigma2 = max(sigma2, eps);
    z = (R1 - mu) / sqrt(sigma2);
    p = 2 * normcdf(-abs(z));
    p = min(max(p, 0), 1);
end
