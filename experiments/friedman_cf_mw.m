function friedman_cf_mw()
% 任务5：CF1-10 + MW1-14 上 14 算法 Friedman（IGD/HV/综合）
% EDD_cf vs 8 传统基线 + 3 SOTA（主判定战场 CF1-10；MW 族为对照）
% 数据源（全 14 算法同 PF/ref 口径：OfficialProblem 解析 PF + 1.1*max）：
%   EDD_cf    -> results/cf_edd_cf/<PN>_EDD_cf_s<k>.mat
%   8基线     -> results/cf_baselines/<ALG>/<PN>_<ALG>_s<k>.mat
%   3 SOTA    -> results/cf_sota/<ALG>/<PN>_<ALG>_s<k>.mat
% 红线：PF/ref 口径全 24 题一致（官方 GetOptimum 解析），EDD_cf/SOTA/基线同口径。
%   NDSort 已修 2参兼容（官方 GetOptimum 调 NDSort(R,1) 不再崩）。
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');

    probs = cell(0,1);
    for i = 1:10, probs{end+1} = ['CF' num2str(i)]; end
    for i = 1:14, probs{end+1} = ['MW' num2str(i)]; end
    nP = numel(probs);

    algs = {'EDD_cf','MOEAD','MOGWO','NSGA2','NSGA3', ...
            'RVEA','SMSEMOA','SPEA2','AGEMOEA','FDSEA','GDVTSF','MOEA-IB'};
    nA = numel(algs);
    % 基线/SOTA mat 各在 <父目录>\<ALG>\ 子目录；EDD_cf 直接在 cf_edd_cf\
    loadDir = { 'results\cf_edd_cf', ...
                'results\cf_baselines\MOEAD','results\cf_baselines\MOGWO','results\cf_baselines\NSGA2', ...
                'results\cf_baselines\NSGA3', ...
                'results\cf_baselines\RVEA','results\cf_baselines\SMSEMOA','results\cf_baselines\SPEA2', ...
                'results\cf_baselines\AGEMOEA', ...
                'results\cf_sota\FDSEA','results\cf_sota\GDVTSF','results\cf_sota\MOEA-IB' };
    filePre = { 'EDD_cf','MOEAD','MOGWO','NSGA2','NSGA3', ...
                'RVEA','SMSEMOA','SPEA2','AGEMOEA','FDSEA','GDVTSF','MOEA-IB' };

    igdTbl = nan(nA, nP); hvTbl = nan(nA, nP);
    for a = 1:nA
        an = algs{a}; ld = loadDir{a}; pre = filePre{a};
        for p = 1:nP
            % 文件名格式：基线/EDD_cf 用 <PN>_<ALG>_s<k>.mat（PN 在前）；
            % SOTA 用 <ALG>_<PN>_s<k>.mat（ALG 在前）——两个方向都要试
            f = dir(fullfile(ld, [probs{p} '_' pre '_s*.mat']));
            if isempty(f), f = dir(fullfile(ld, [pre '_' probs{p} '_s*.mat'])); end
            if numel(f) < 30
                fprintf('%-8s %-8s 种子不齐: %d/30\n', an, probs{p}, numel(f));
                continue;
            end
            igdS = zeros(1, numel(f)); hvS = zeros(1, numel(f)); ok = true;
            for k = 1:numel(f)
                L = load(fullfile(f(k).folder, f(k).name));
                if isfield(L,'out') && isfield(L.out,'IGD')
                    igdS(k) = L.out.IGD; hvS(k) = L.out.HV;
                else
                    ok = false; break;
                end
            end
            if ~ok, continue; end
            igdTbl(a,p) = median(igdS);
            hvTbl(a,p)  = median(hvS);
        end
        fprintf('%-8s IGD齐=%d/24 HV齐=%d/24\n', an, sum(~isnan(igdTbl(a,:))), sum(~isnan(hvTbl(a,:))));
    end

    validCols = ~any(isnan(igdTbl),1) & ~any(isnan(hvTbl),1);
    nAvail = sum(validCols);
    fprintf('\n全 %d 算法全齐的题数: %d/24\n', nA, nAvail);
    if nAvail < 5
        error('可用题数不足 5，无法算 Friedman');
    end
    igdTbl2 = igdTbl(:,validCols);
    hvTbl2  = hvTbl(:,validCols);

    igdRank  = friedmanRank(igdTbl2, nA, nAvail);
    hvRank   = friedmanRank(-hvTbl2, nA, nAvail);
    combRank = (igdRank + hvRank) / 2;
    chi = (12*nAvail/(nA*(nA+1))) * (sum((igdRank-mean(igdRank)).^2)/(nA*(nA+1))) * nA*(nA+1);
    pval = 1 - cdf('chi2', chi, nA-1);

    [~, iOrd] = sort(igdRank);
    [~, hOrd] = sort(hvRank);
    [~, cOrd] = sort(combRank);
    fprintf('\n=== IGD Friedman（%d 题，%d 算法，小=好）===\n', nAvail, nA);
    for k = 1:nA, fprintf('  %d. %-8s 秩=%.3f\n', k, algs{iOrd(k)}, igdRank(iOrd(k))); end
    fprintf('\n=== HV Friedman（%d 题，14 算法，小=好）===\n');
    for k = 1:nA, fprintf('  %d. %-8s 秩=%.3f\n', k, algs{hOrd(k)}, hvRank(hOrd(k))); end
    fprintf('\n=== 综合 Friedman（(IGD+HV)/2，小=好）===\n');
    for k = 1:nA, fprintf('  %d. %-8s 秩=%.3f\n', k, algs{cOrd(k)}, combRank(cOrd(k))); end
    fprintf('\nIGD Friedman stat=%.2f pval=%.4g\n', chi, pval);

    % EDD_cf vs 13 baseline 问题级 Wilcoxon（仅全齐题）
    eIdx = find(strcmp(algs,'EDD_cf'));
    vsIdx = setdiff(1:nA, eIdx);
    pAll = zeros(1, numel(vsIdx));
    fprintf('\n=== 问题级 Wilcoxon（EDD_cf vs 各，全齐题 IGD）===\n');
    for kk = 1:numel(vsIdx)
        a = vsIdx(kk);
        d = igdTbl2(eIdx,:) - igdTbl2(a,:);
        d = d(~isnan(d));
        pAll(kk) = wsrPval(d);
        win=sum(d<0); lose=sum(d>0); tie=sum(d==0);
        fprintf('  EDD_cf vs %-8s: IGD win=%d lose=%d tie=%d p=%.4g\n', algs{a}, win, lose, tie, pAll(kk));
    end
    pHolm = holmAdjust(pAll);

    % 判定
    fprintf('\n=== EDD_cf CF/MW 判定（%d 全齐题）===\n', nAvail);
    eIgd=igdRank(eIdx); eHv=hvRank(eIdx); eComb=combRank(eIdx);
    fprintf('EDD_cf IGD 秩=%.3f (第 %d 名 / %d)\n', eIgd, rankpos(igdRank,eIgd), nA);
    fprintf('EDD_cf HV  秩=%.3f (第 %d 名 / %d)\n', eHv,  rankpos(hvRank,eHv),  nA);
    fprintf('EDD_cf 综合秩=%.3f (第 %d 名 / %d)\n', eComb, rankpos(combRank,eComb), nA);
    nSig = sum(pHolm < 0.05);
    fprintf('Wilcoxon p<0.05 题数: %d / %d\n', nSig, numel(pHolm));
    if rankpos(combRank,eComb)==1
        fprintf('\n>>> EDD_cf 综合 Friedman 第一 → 进任务6（消融）\n');
    elseif rankpos(igdRank,eIgd)==1 || rankpos(hvRank,eHv)==1
        fprintf('\n>>> EDD_cf 单项第一（IGD 或 HV）→ 需综合也第一才算成功\n');
    else
        fprintf('\n>>> EDD_cf 掉出全部第一 → 触发任务7（最终判定，硬上限）\n');
    end

    save('results/friedman_cf_mw.mat', ...
        'algs','probs','igdTbl','hvTbl','igdRank','hvRank','combRank','chi','pval', ...
        'iOrd','hOrd','cOrd','pAll','pHolm','validCols','-v7.3');
    fprintf('\n已存 results/friedman_cf_mw.mat\n');
end

function pAdj = holmAdjust(pVec)
    % Holm-Bonferroni 校正
    n = numel(pVec);
    [pSorted, ord] = sort(pVec);
    c = zeros(1,n);
    for k = 1:n
        c(k) = min(1, pSorted(k) * (n-k+1));
    end
    c = cummax(c);
    pAdj = zeros(size(pVec));
    pAdj(ord) = c;
end

function pos = rankpos(rankVec, v)
    pos = sum(rankVec < v) + 1;
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
    d = d(~(d==0 | isnan(d)));
    n = numel(d);
    if n==0, p=1; return; end
    absd = abs(d);
    [absd, ord] = sort(absd);
    r = (1:n)';
    i = 1;
    while i <= n
        j = i;
        while j < n && absd(j)==absd(i), j = j+1; end
        if j>i, r(ord(i:j)) = mean(i:j); end
        i = j+1;
    end
    W = min(sum(r(ord(d>0))), sum(r(ord(d<0))));
    mu = n*(n+1)/4;
    sig = sqrt(n*(n+1)*(2*n+1)/24);
    z = (W - mu + 0.5)/sig;
    p = 2*(1-normcdf(z,0,1));
    p = min(max(p,0),1);
end
