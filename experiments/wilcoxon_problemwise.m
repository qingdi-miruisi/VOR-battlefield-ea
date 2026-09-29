function report = wilcoxon_problemwise(resDir, v4Dir, refAlg, metric, targets, problems)
% WILCOXON_PROBLEMWISE - 严格问题级 Wilcoxon 符号秩（任务1 要求的统计推断）
%   1) 每个问题内，取各算法 30 种子的中位数
%   2) 跨问题做 Wilcoxon 符号秩（符号差 = med_ref - med_target）
%   3) 输出真实 p 值（不再池化种子）
    if nargin < 2, v4Dir = 'results\main_v4'; end
    if nargin < 3, refAlg = 'HCEAV4'; end
    if nargin < 4, metric = 'IGD'; end
    if nargin < 5
        targets = {'HCEA','HCEAV2','SMSEMOA','NSGA2','MOEAD','RVEA','SPEA2','NSGA3','AGEMOEA','MOGWO'};
    end
    if nargin < 6
        problems = {'ZDT1','ZDT2','ZDT3','ZDT4','ZDT5','ZDT6','DTLZ1','DTLZ2','DTLZ3', ...
            'DTLZ4','DTLZ5','DTLZ7','WFG1','WFG2','WFG3','WFG4','WFG5','WFG6','WFG7', ...
            'WFG8','WFG9','UF1','UF2','UF5','UF6','CMO1','CMO5','MaF1','MaF2','MaF3', ...
            'MaF4','MaF5','MaF11'};
    end
    nProb = numel(problems);
    isIGD = strcmp(metric, 'IGD');
    rawP = zeros(1, numel(targets));
    nProbs = zeros(1, numel(targets));
    winCounts = zeros(1, numel(targets));
    for ti = 1:numel(targets)
        tg = targets{ti};
        d = [];
        winCount = 0;
        for p = 1:nProb
            mref = []; mtgt = [];
            for s = 1:30
                fn1 = fullfile(v4Dir, [refAlg '_' problems{p} '_s' num2str(s) '.mat']);
                fn2 = fullfile(resDir, [tg '_' problems{p} '_s' num2str(s) '.mat']);
                if ~isfile(fn1) || ~isfile(fn2), continue; end
                a = load(fn1); b = load(fn2);
                if ~isfield(a, 'out') || ~isfield(a.out, metric), continue; end
                if ~isfield(b, 'out') || ~isfield(b.out, metric), continue; end
                av = real(a.out.(metric)); bv = real(b.out.(metric));
                if numel(av) > 1, av = mean(av(:)); end
                if numel(bv) > 1, bv = mean(bv(:)); end
                if ~isfinite(av) || ~isfinite(bv), continue; end
                mref(end+1, 1) = av; mtgt(end+1, 1) = bv;
            end
            if numel(mref) < 5 || numel(mtgt) < 5, continue; end
            med_ref = median(mref); med_tg = median(mtgt);
            d(end+1, 1) = med_ref - med_tg;
            if isIGD
                win = (med_ref < med_tg);
            else
                win = (med_ref > med_tg);
            end
            if win, winCount = winCount + 1; end
        end
        nProbs(ti) = numel(d);
        winCounts(ti) = winCount;
        ad = abs(d);
        [sorted, ord] = sort(ad);
        ranks = (1:numel(d));
        ii = 1;
        while ii <= numel(sorted)
            jj = ii;
            while jj < numel(sorted) && sorted(jj+1) == sorted(ii), jj = jj+1; end
            rr = (ii + jj)/2;
            ranks(ord(ii:jj)) = rr;
            ii = jj+1;
        end
        Rpos = sum(ranks(d > 0)); Rneg = sum(ranks(d < 0));
        T = min(Rpos, Rneg);
        nn = numel(d);
        muT = nn*(nn+1)/4; sdT = sqrt(nn*(nn+1)*(2*nn+1)/24);
        z = (T - muT)/sdT;
        p = 2*normcdf(-abs(z));
        rawP(ti) = min(1, p);
    end
    report.metric = metric;
    report.refAlg = refAlg;
    report.targets = targets;
    report.nProblems = nProbs;
    report.winCounts = winCounts;
    report.pValues = rawP;
    report.sig05 = rawP < 0.05;
end
