function friedman_edd()
    % 基于问题级 IGD/HV 中位数（30 种子每题中位，不池化）做 Friedman 平均秩
    % 对比 8 基线 + HCEA + HCEAV4 + EDD（共 11 算法）在 80 扩展集上
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext'); clear classes; clear IGD HV;
    algs = {'NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD','HCEA','HCEAV4','EDD'};
    [problems, names] = extProbs();
    nP = numel(names); nA = numel(algs);
    % 每个算法每题 30 种子 IGD/HV 中位数（断点续跑已保存的）
    igdMed = zeros(nA, nP); hvMed = zeros(nA, nP);
    missing = 0;
    for a = 1:nA
        for p = 1:nP
            an = algs{a}; pn = names{p};
            igdS = zeros(1,30); hvS = zeros(1,30); ok = true;
            for s = 1:30
                fn = fullfile('results\baselines_ext', sprintf('%s_%s_s%d.mat', an, pn, s));
                if ~isfile(fn)
                    % HCEA/HCEAV4/EDD 在 new_algo
                    fn = fullfile('results\new_algo', sprintf('%s_%s_s%d.mat', an, pn, s));
                end
                if ~isfile(fn), ok = false; missing = missing + 1; break; end
                L = load(fn); igdS(s) = L.out.IGD; hvS(s) = L.out.HV;
            end
            if ~ok, igdMed(a,p) = NaN; hvMed(a,p) = NaN; continue; end
            igdMed(a,p) = median(igdS); hvMed(a,p) = median(hvS);
        end
    end
    if missing > 0, fprintf('WARNING: %d 个 (算法,题) 组 30 种子不齐（跳过 Friedman，等补齐）\n', missing); end
    % Friedman 平均秩（ties-averaged）
    [igdRank, igdStat, igdPval, igdRankTab] = friedmanTies(igdMed);
    [hvRank, hvStat, hvPval, hvRankTab] = friedmanTies(-hvMed);
    % IGD 小=好，直接排；HV 大=好，取负后小=好
    ord = sort(igdRank); igdOrder = [1:nA]; igdOrder = igdOrder(ord);
    ordH = sort(hvRank); hvOrder = [1:nA]; hvOrder = hvOrder(ordH);
    fprintf('=== IGD Friedman 平均秩（小=好）===\n');
    for a = 1:nA, fprintf('  %-8s 秩=%.3f\n', algs{igdOrder(a)}, igdRank(igdOrder(a))); end
    fprintf('IGD Friedman stat=%.2f pval=%.4g\n\n', igdStat, igdPval);
    fprintf('=== HV Friedman 平均秩（大=好，取负后小=好）===\n');
    for a = 1:nA, fprintf('  %-8s 秩=%.3f\n', algs{hvOrder(a)}, hvRank(hvOrder(a))); end
    fprintf('HV Friedman stat=%.2f pval=%.4g\n', hvStat, hvPval);
    %% ===== 问题级 Wilcoxon + Holm 校正（新算法 EDD vs 每个基线）=====
    % EDD 在 algs 中的索引
    eIdx = strfind(algs, 'EDD');
    % 每题的 IGD/HV 中位数向量（已按题计算），Wilcoxon 逐题做配对比
    fprintf('\n=== 问题级 Wilcoxon 符号秩（EDD vs 各基线，基于 30 种子每题中位）===\n');
    for a = 1:nA
        if a == eIdx, continue; end
        igdD = igdMed(eIdx,:) - igdMed(a,:);   % EDD - 基线，负=EDD IGD 更小（更好）
        hvD = hvMed(eIdx,:) - hvMed(a,:);       % 正=EDD HV 更大（更好）
        igdWin = sum(igdD < 0 & ~isnan(igdD)); igdLose = sum(igdD > 0 & ~isnan(igdD));
        hvWin = sum(hvD > 0 & ~isnan(hvD)); hvLose = sum(hvD < 0 & ~isnan(hvD));
        igdP = wsrPval(igdD(~isnan(igdD)));
        hvP = wsrPval(hvD(~isnan(hvD)));
        fprintf('  EDD vs %-8s: IGD win=%d lose=%d p=%.4g | HV win=%d lose=%d p=%.4g\n', ...
            algs{a}, igdWin, igdLose, igdP, hvWin, hvLose, hvP);
    end
    %% ===== Holm 校正（所有成对 IGD p 值）=====
    nPair = nA - 1;
    pAll = zeros(1, nPair);
    k = 0;
    for a = 1:nA
        if a == eIdx, continue; end
        k = k + 1;
        pAll(k) = wsrPval((igdMed(eIdx,:) - igdMed(a,:))');
    end
    [pHolm, rejHolm] = holmCorr(pAll);
    fprintf('\n=== Holm 校正后 IGD 显著性（EDD vs 各基线）===\n');
    for a = 1:nA
        if a == eIdx, continue; end
        kIdx = 0;
        for b = 1:a-1
            if b ~= eIdx, kIdx = kIdx + 1; end
        end
        if kIdx > 0
            fprintf('  EDD vs %-8s: pHolm=%.4g %s\n', algs{a}, pHolm(kIdx), ...
                string(rejHolm(kIdx)));
        end
    end
    save('results\friedman_edd.mat', 'algs','names','igdMed','hvMed','igdRank','hvRank','igdStat','hvStat','igdPval','hvPval','pHolm','rejHolm');
end

function p = wsrPval(d)
    % Wilcoxon 符号秩双侧 p 值（ties-averaged ranks + 正态近似）
    d = d(~(d == 0 | isnan(d)));
    n = numel(d);
    if n == 0, p = 1; return; end
    absd = abs(d);
    [absd, ord] = sort(absd);
    r = (1:n)';
    % ties-averaged
    i = 1;
    while i <= n
        j = i;
        while j < n && absd(j) == absd(i), j = j + 1; end
        if j > i
            avgR = mean(i:j);
            r(ord(i:j)) = avgR;
        end
        i = j + 1;
    end
    Wplus = sum(r(ord(d > 0)));
    Wneg = sum(r(ord(d < 0)));
    W = min(Wplus, Wneg);
    mu = n*(n+1)/4;
    sig = sqrt(n*(n+1)*(2*n+1)/24);
    z = (W - mu + 0.5) / sig;   % 连续性校正
    p = 2 * (1 - normcdf(z, 0, 1));
    p = min(max(p, 0), 1);
end

function [pHolm, rej] = holmCorr(p)
    % Holm-Bonferroni 校正
    n = numel(p);
    [~, ord] = sort(p);
    thresh = (n - (1:n) + 1) / n * 0.05;
    pSort = p(ord);
    rejSort = pSort <= thresh;
    % 传递：一旦某位不拒绝，其后全不拒绝
    for k = 2:n
        if ~rejSort(k-1)
            rejSort(k:n) = false;
        end
    end
    pHolm = pSort;   % 对应 ord 顺序的 p 值
    rej = rejSort;   % 对应 ord 顺序的拒绝标志
end

function [rank, stat, pval, rankTab] = friedmanTies(M)
    % M: nA x nP 矩阵（每行算法，每列题），NaN 跳过；Friedman ties-averaged
    [nA, nP] = size(M);
    rankTab = zeros(nA, nP);
    for p = 1:nP
        col = M(:,p);
        valid = ~isnan(col);
        if sum(valid) < 2, continue; end
        v = col(valid);
        vals = v;
        [~, ord] = sort(vals);
        r = zeros(numel(v),1);
        % ties-averaged ranks: group equal values, assign average rank
        i = 1;
        while i <= numel(v)
            j = i;
            while j < numel(v) && vals(ord(j)) == vals(ord(i)), j = j + 1; end
            avgR = mean(i:j);
            r(ord(i:j)) = avgR;
            i = j + 1;
        end
        rankTab(valid, p) = r;
    end
    rank = mean(rankTab, 2);
    % Friedman 统计量
    F = (12 * nP / (nA*(nA+1))) * (sum((rank - mean(rank))^2) / (nA*(nA+1))) * (nA*(nA+1));
    stat = F;
    pval = 1 - cdf('chi2', F, nA-1);
end