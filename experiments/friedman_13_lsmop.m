function friedman_13_lsmop()
% friedman_13_lsmop — 阶段2：13 算法（旧 11 + FDSEA + GDVTSF + MOEA-IB）
% 在 LSMOP1-9（9 题）上重算 Friedman IGD/HV/综合 + EDD vs 12 baseline Wilcoxon+Holm。
% 路线B：DTLZ2_300D_M3 不进 Friedman 主判定（PF 口径差异：新3算法=官方91点，旧算法=本地500点）。
% 数据源：
%   EDD      -> results/new_algo_v12/EDD_<prob>_s<seed>.mat
%   旧8个    -> results/baselines_ext/<alg>_<prob>_s<seed>.mat
%   HCEA/HCEAV4 -> results/new_algo/<alg>_<prob>_s<seed>.mat
%   新3个    -> results/largescale_extended/<algDir>/<algDir>_<prob>_s<seed>.mat
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');

    probs = {'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9'};
    nP = numel(probs);

    % 13 算法：名称 + 数据目录 + 文件名前缀
    algs = {'EDD','HCEA','HCEAV4','MOEAD','MOGWO','NSGA2','NSGA3', ...
            'RVEA','SMSEMOA','SPEA2','AGEMOEA','FDSEA','GDVTSF','MOEA-IB'};
    nA = numel(algs);
    loadDir = {'results\new_algo_v12','results\new_algo','results\new_algo', ...
               'results\baselines_ext','results\baselines_ext','results\baselines_ext', ...
               'results\baselines_ext','results\baselines_ext','results\baselines_ext', ...
               'results\baselines_ext','results\baselines_ext', ...
               'results\largescale_extended\FDSEA', ...
               'results\largescale_extended\GDVTSF', ...
               'results\largescale_extended\MOEA-IB'};
    filePre = {'EDD','HCEA','HCEAV4','MOEAD','MOGWO','NSGA2','NSGA3', ...
               'RVEA','SMSEMOA','SPEA2','AGEMOEA','FDSEA','GDVTSF','MOEA-IB'};

    igdTbl = nan(nA, nP); hvTbl = nan(nA, nP);
    for a = 1:nA
        an = algs{a}; ld = loadDir{a}; pre = filePre{a};
        for p = 1:nP
            f = dir(fullfile(ld, [pre '_' probs{p} '_s*.mat']));
            if numel(f) < 30
                fprintf('%-8s %-8s 种子不齐: %d/30\n', an, probs{p}, numel(f));
                continue;
            end
            igdS = zeros(1, numel(f)); hvS = zeros(1, numel(f)); ok = true;
            for k = 1:numel(f)
                L = load(fullfile(f(k).folder, f(k).name));
                if isfield(L, 'out') && isfield(L.out, 'IGD')
                    igdS(k) = L.out.IGD; hvS(k) = L.out.HV;
                else
                    ok = false; break;
                end
            end
            if ~ok, continue; end
            igdTbl(a, p) = median(igdS);
            hvTbl(a, p)   = median(hvS);
        end
        fprintf('%-8s IGD齐=%d/9 HV齐=%d/9\n', an, sum(~isnan(igdTbl(a,:))), sum(~isnan(hvTbl(a,:))));
    end

    validCols = ~any(isnan(igdTbl), 1) & ~any(isnan(hvTbl), 1);
    nAvail = sum(validCols);
    fprintf('\n13 算法全齐的题数: %d/9\n', nAvail);
    if nAvail < 5
        error('可用题数不足 5，无法算 Friedman');
    end
    igdTbl2 = igdTbl(:, validCols);
    hvTbl2  = hvTbl(:, validCols);

    %% Friedman（IGD 小=好，HV 大=好；同题平均秩 → 小=好）
    igdRank = friedmanRank(igdTbl2, nA, nAvail);
    hvRank  = friedmanRank(-hvTbl2, nA, nAvail);
    combRank = (igdRank + hvRank) / 2;
    chi = (12*nAvail/(nA*(nA+1))) * (sum((igdRank - mean(igdRank)).^2) / (nA*(nA+1))) * nA*(nA+1);
    pval = 1 - cdf('chi2', chi, nA-1);

    [~, iOrd] = sort(igdRank);
    [~, hOrd] = sort(hvRank);
    [~, cOrd] = sort(combRank);
    fprintf('\n=== IGD Friedman（%d 题，13 算法，小=好）===\n', nAvail);
    for k = 1:nA, fprintf('  %d. %-8s 秩=%.3f\n', k, algs{iOrd(k)}, igdRank(iOrd(k))); end
    fprintf('\n=== HV Friedman（%d 题，13 算法，小=好）===\n', nAvail);
    for k = 1:nA, fprintf('  %d. %-8s 秩=%.3f\n', k, algs{hOrd(k)}, hvRank(hOrd(k))); end
    fprintf('\n=== 综合 Friedman（(IGD+HV)/2，小=好）===\n');
    for k = 1:nA, fprintf('  %d. %-8s 秩=%.3f\n', k, algs{cOrd(k)}, combRank(cOrd(k))); end
    fprintf('\nIGD Friedman stat=%.2f pval=%.4g\n', chi, pval);

    %% 逐题 IGD/HV 表（markdown，便于贴论文）
    fprintf('\n=== 逐题中位 IGD（小=好）===\n');
    hdr = ['算法' sblank(8)];
    for p = 1:nAvail
        v = igdTbl2(:, p);
        [~, ord] = sort(v);
        fprintf('  %s: ', algs{ord(1)});
        for a = 1:nA
            fprintf('%-10s', algs{a});
        end
        fprintf('\n');
    end

    %% EDD vs 12 baseline：Wilcoxon（问题级中位差）+ Holm-Bonferroni
    eIdx = find(strcmp(algs, 'EDD'));
    vsIdx = setdiff(1:nA, eIdx);
    pAll = zeros(1, numel(vsIdx));
    fprintf('\n=== 问题级 Wilcoxon（EDD vs 各，9 题 IGD 中位差）===\n');
    for kk = 1:numel(vsIdx)
        a = vsIdx(kk);
        d = igdTbl2(eIdx, :) - igdTbl2(a, :);
        d = d(~isnan(d));
        pAll(kk) = wsrPval(d);
        win  = sum(d < 0); lose = sum(d > 0); tie = sum(d == 0);
        fprintf('  EDD vs %-8s: IGD win=%d lose=%d tie=%d p=%.4g\n', algs{a}, win, lose, tie, pAll(kk));
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

    %% 判定
    fprintf('\n=== EDD 保第一判定（路线B：LSMOP1-9）===\n');
    eIgd = igdRank(eIdx); eHv = hvRank(eIdx); eComb = combRank(eIdx);
    fprintf('EDD IGD 秩=%.3f (第 %d 名 / %d)\n', eIgd, rankpos(igdRank, eIgd), nA);
    fprintf('EDD HV  秩=%.3f (第 %d 名 / %d)\n', eHv,  rankpos(hvRank, eHv),  nA);
    fprintf('EDD 综合秩=%.3f (第 %d 名 / %d)\n', eComb, rankpos(combRank, eComb), nA);
    if rankpos(combRank, eComb) == 1
        fprintf('\n>>> EDD 综合 Friedman 第一 → 进入阶段4（更新论文）\n');
    elseif rankpos(igdRank, eIgd) == 1 || rankpos(hvRank, eHv) == 1
        fprintf('\n>>> EDD IGD/HV 单项第一（综合非第一）→ 按协议仍需阶段3 拿到综合第一\n');
    else
        fprintf('\n>>> EDD 掉出 IGD/HV/综合 全部第一 → 触发阶段3（EDD 保第一协议）\n');
    end

    save('results\friedman_13_lsmop.mat', ...
         'algs','probs','igdTbl','hvTbl','igdRank','hvRank','combRank','chi','pval', ...
         'iOrd','hOrd','cOrd','pAll','vsIdx','validCols','-v7.3');
    fprintf('已存 results/friedman_13_lsmop.mat\n');
end

function pos = rankpos(rankVec, v)
    % rankVec: 各算法平均秩（小=好）；返回 v 的名次
    pos = sum(rankVec < v) + 1;
end

function sblank = sblank(n)
    sblank = repmat(' ', 1, n);
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
