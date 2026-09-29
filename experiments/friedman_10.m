function friedman_10()
    % 10 题（LSMOP9 + DTLZ2_300D_M3）× 11 算法 Friedman
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
    addpath('problems_official\EMO'); addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    probNames = {'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9','DTLZ2_300D_M3'};
    algs = {'EDD','HCEA','HCEAV4','NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD'};
    nA = numel(algs); nP = numel(probNames);
    igdTbl = nan(nA, nP); hvTbl = nan(nA, nP);
    for a = 1:nA
        an = algs{a};
        for p = 1:nP
            f = dir(fullfile('results\largescale_final', an, [an '_' probNames{p} '_s*.mat']));
            if numel(f) < 30, continue; end
            igdS = zeros(1, numel(f)); hvS = zeros(1, numel(f));
            for k = 1:numel(f)
                L = load(fullfile(f(k).folder, f(k).name));
                igdS(k) = L.out.IGD; hvS(k) = L.out.HV;
            end
            igdTbl(a, p) = median(igdS); hvTbl(a, p) = median(hvS);
        end
        fprintf('%-8s IGD齐=%d/10 HV齐=%d/10\n', an, sum(~isnan(igdTbl(a,:))), sum(~isnan(hvTbl(a,:))));
    end
    validCols = ~any(isnan(igdTbl), 1);
    nAvail = sum(validCols);
    fprintf('\n全算法齐的题: %d/10\n', nAvail);
    igdTbl2 = igdTbl(:, validCols); hvTbl2 = hvTbl(:, validCols);
    igdRank = friedmanRank(igdTbl2, nA, nAvail);
    hvRank = friedmanRank(-hvTbl2, nA, nAvail);
    combined = (igdRank + hvRank) / 2;
    [~, iOrd] = sort(igdRank); [~, hOrd] = sort(hvRank); [~, cOrd] = sort(combined);
    fprintf('\n=== IGD Friedman（%d 题，11 算法，小=好）===\n', nAvail);
    for k = 1:nA
        fprintf('  %-8s 秩=%.3f\n', algs{iOrd(k)}, igdRank(iOrd(k)));
    end
    fprintf('\n=== HV Friedman（%d 题，11 算法，大=好）===\n', nAvail);
    for k = 1:nA
        fprintf('  %-8s 秩=%.3f\n', algs{hOrd(k)}, hvRank(hOrd(k)));
    end
    fprintf('\n=== 综合 ===\n');
    for k = 1:nA
        fprintf('  %-8s 综合=%.3f\n', algs{cOrd(k)}, combined(cOrd(k)));
    end
    eIdx = find(strcmp(algs,'EDD'));
    vsIdx = setdiff(1:nA, eIdx);
    pAll = zeros(1, numel(vsIdx));
    fprintf('\n=== 问题级 Wilcoxon（EDD vs 各，%d 题中位不池化）===\n', nAvail);
    for kk = 1:numel(vsIdx)
        a = vsIdx(kk);
        d = igdTbl2(eIdx,:) - igdTbl2(a,:);
        d = d(~isnan(d));
        pAll(kk) = wsrPval(d);
        win = sum(d < 0); lose = sum(d > 0);
        fprintf('  EDD vs %-8s: IGD win=%d lose=%d p=%.4g\n', algs{a}, win, lose, pAll(kk));
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
        if ~rejSort(kk), verdict = '不显著'; end
        fprintf('  EDD vs %-8s: p=%.4g %s\n', algs{a}, pAll(ord(kk)), verdict);
    end
    %% 逐题 IGD/HV 表
    fprintf('\n=== 逐题 IGD（30 种子中位）===\n');
    hdr = sprintf('%-14s', 'prob');
    for a = 1:nA
        s = algs{a};
        if numel(s) > 6, s = s(1:6); end
        hdr = [hdr sprintf('%7s ', s)];
    end
    fprintf('%s\n', hdr);
    for p = 1:nP
        line = sprintf('%-14s', probNames{p});
        for a = 1:nA
            if isnan(igdTbl(a,p)), line = [line sprintf('%7s ', '--')];
            else, line = [line sprintf('%7.2f ', igdTbl(a,p))]; end
        end
        fprintf('%s\n', line);
    end
    fprintf('\n=== 逐题 HV（30 种子中位）===\n');
    for p = 1:nP
        line = sprintf('%-14s', probNames{p});
        for a = 1:nA
            if isnan(hvTbl(a,p)), line = [line sprintf('%7s ', '--')];
            else, line = [line sprintf('%7.3f ', hvTbl(a,p))]; end
        end
        fprintf('%s\n', line);
    end
    save('results\largescale_final\friedman_10.mat', 'algs','probNames','igdTbl','hvTbl','igdRank','hvRank','combined','pAll');
    fprintf('\nsaved results\largescale_final\friedman_10.mat\n');
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

function hdr = algs2short(algs)
    hdr = '';
    for k = 1:numel(algs)
        s = algs{k};
        if numel(s) > 5, s = s(1:5); end
        hdr = [hdr sprintf('%6s ', s)];
    end
end

function line = algs2line(tbl, algs, p, fmt)
    % tbl: nA x nP; algs: cell of names; p: col index; fmt: printf format
    s = sprintf(fmt, nan);  % placeholder to get width
    w = numel(s);
    out = '';
    nA = size(tbl,1);
    for a = 1:nA
        if isnan(tbl(a,p)), out = [out sprintf('%*s', w, '--')];
        else, out = [out sprintf(fmt, tbl(a,p))]; end
        if a < nA, out = [out ' ']; end
    end
    line = out;
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
