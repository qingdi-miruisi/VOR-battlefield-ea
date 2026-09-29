function friedman_v12()
    % 11 算法 × 80 扩展集 Friedman（EDD 用 v12 数据 results/new_algo_v12，其余用 new_algo/baselines_ext）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    [problems, names] = extProbs();
    algs = {'NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD','HCEA','HCEAV4','EDD'};
    nA = numel(algs); nP = numel(names);
    igdTbl = nan(nA, nP); hvTbl = nan(nA, nP);
    for a = 1:nA
        an = algs{a};
        for p = 1:nP
            if strcmp(an,'EDD')
                f = dir(fullfile('results\new_algo_v12', ['EDD_' names{p} '_s*.mat']));
            elseif a <= 8
                f = dir(fullfile('results\baselines_ext', [an '_' names{p} '_s*.mat']));
            else
                f = dir(fullfile('results\new_algo', [an '_' names{p} '_s*.mat']));
            end
            if numel(f) < 30, continue; end
            igdS = zeros(1, numel(f)); hvS = zeros(1, numel(f)); ok = true;
            for k = 1:numel(f)
                try
                    L = load(fullfile(f(k).folder, f(k).name));
                    igdS(k) = L.out.IGD; hvS(k) = L.out.HV;
                catch
                    ok = false; break;
                end
            end
            if ~ok, continue; end
            igdTbl(a, p) = median(igdS); hvTbl(a, p) = median(hvS);
        end
        fprintf('%-8s IGD齐=%d/80 HV齐=%d/80\n', an, sum(~isnan(igdTbl(a,:))), sum(~isnan(hvTbl(a,:))));
    end
    validCols = ~any(isnan(igdTbl), 1);
    nAvail = sum(validCols);
    fprintf('\n全部 11 算法都有 30 种子齐的题: %d/80\n', nAvail);
    if nAvail < 5, fprintf('可用题数不足 5，无法跑 Friedman（等补齐）\n'); return; end
    igdTbl2 = igdTbl(:, validCols); hvTbl2 = hvTbl(:, validCols);
    igdRank = friedmanRank(igdTbl2, nA, nAvail);
    hvRank = friedmanRank(-hvTbl2, nA, nAvail);
    stat = (12*nAvail/(nA*(nA+1))) * (sum((igdRank-mean(igdRank)).^2)/(nA*(nA+1)))*nA*(nA+1);
    pval = 1 - cdf('chi2', stat, nA-1);
    [~, iOrd] = sort(igdRank);
    [~, hOrd] = sort(hvRank);
    fprintf('\n=== IGD Friedman（%d 题，11 算法，小=好）===\n', nAvail);
    for k = 1:nA
        fprintf('  %-8s 秩=%.3f\n', algs{iOrd(k)}, igdRank(iOrd(k)));
    end
    fprintf('\n=== HV Friedman（%d 题，11 算法，大=好）===\n', nAvail);
    for k = 1:nA
        fprintf('  %-8s 秩=%.3f\n', algs{hOrd(k)}, hvRank(hOrd(k)));
    end
    fprintf('\nIGD Friedman stat=%.2f pval=%.4g\n', stat, pval);
    %% 问题级 Wilcoxon + Holm（EDD v12 vs 各）
    eIdx = find(strcmp(algs, 'EDD'));
    pAll = zeros(1, nA-1); vsIdx = setdiff(1:nA, eIdx);
    fprintf('\n=== 问题级 Wilcoxon（EDD-v12 vs 各，30 种子每题中位不池化）===\n');
    for kk = 1:numel(vsIdx)
        a = vsIdx(kk);
        d = igdTbl2(eIdx,:) - igdTbl2(a,:);
        d = d(~isnan(d));
        pAll(kk) = wsrPval(d);
        win = sum(d < 0); lose = sum(d > 0);
        fprintf('  EDD-v12 vs %-8s: IGD win=%d lose=%d p=%.4g\n', algs{a}, win, lose, pAll(kk));
    end
    nPair = numel(pAll);
    [~, ord] = sort(pAll);
    thresh = (nPair - (1:nPair) + 1) / nPair * 0.05;
    pSort = pAll(ord);
    rejSort = pSort <= thresh;
    for kk = 2:nPair
        if ~rejSort(kk-1), rejSort(kk:nPair) = false; end
    end
    fprintf('\n=== Holm-Bonferroni 校正（alpha=0.05）===\n');
    for kk = 1:nPair
        a = vsIdx(ord(kk));
        verdict = '显著(EDD优)';
        if ~rejSort(kk)
            verdict = '不显著';
        end
        fprintf('  EDD-v12 vs %-8s: p=%.4g %s\n', algs{a}, pAll(ord(kk)), verdict);
    end
    save('results\friedman_v12.mat', 'algs','names','igdTbl','hvTbl','igdRank','hvRank');
end

function rank = friedmanRank(tbl, nA, nP)
    rankTab = zeros(nA, nP);
    for p = 1:nP
        v = tbl(:, p);
        [v, ord] = sort(v);
        r = zeros(numel(v),1);
        i = 1;
        while i <= numel(v)
            j = i;
            while j < numel(v) && v(j) == v(i), j = j+1; end
            r(ord(i:j)) = mean(i:j);
            i = j+1;
        end
        rankTab(:,p) = r;
    end
    rank = mean(rankTab, 2);
end

function p = wsrPval(d)
    d = d(~(d == 0 | isnan(d)));
    n = numel(d);
    if n == 0, p = 1; return; end
    absd = abs(d);
    [absd, ord] = sort(absd);
    r = (1:n)';
    i = 1;
    while i <= n
        j = i;
        while j < n && absd(j) == absd(i), j = j+1; end
        if j > i, r(ord(i:j)) = mean(i:j); end
        i = j + 1;
    end
    W = min(sum(r(ord(d > 0))), sum(r(ord(d < 0))));
    mu = n*(n+1)/4;
    sig = sqrt(n*(n+1)*(2*n+1)/24);
    z = (W - mu + 0.5) / sig;
    p = 2 * (1 - normcdf(z, 0, 1));
    p = min(max(p, 0), 1);
end
