function report = wilcoxon_50(resDir, v4Dir, refAlg, metric, targets50, problems50, problems33)
% WILCOXON_50 - 全 50 问题 Wilcoxon（HCE 族 50 问题配对，8 基线仅 33 旧问题）
    if nargin < 2, v4Dir = 'results\main_v4'; end
    if nargin < 3, refAlg = 'HCEAV4'; end
    if nargin < 4, metric = 'IGD'; end
    if nargin < 5
        targets50 = {'HCEA','HCEAV2'};
    end
    if nargin < 6
        problems33 = {'ZDT1','ZDT2','ZDT3','ZDT4','ZDT5','ZDT6','DTLZ1','DTLZ2','DTLZ3', ...
            'DTLZ4','DTLZ5','DTLZ7','WFG1','WFG2','WFG3','WFG4','WFG5','WFG6','WFG7', ...
            'WFG8','WFG9','UF1','UF2','UF5','UF6','CMO1','CMO5','MaF1','MaF2','MaF3', ...
            'MaF4','MaF5','MaF11'};
    end
    if nargin < 7
        problemsExt = {'MaF7','MaF8','MaF9','MaF10','MaF12','MaF13','MaF14','MaF15', ...
            'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9'};
        problems50 = [problems33, problemsExt];
    end
    targets8 = {'SMSEMOA','NSGA2','MOEAD','RVEA','SPEA2','NSGA3','AGEMOEA','MOGWO'};
    isIGD = strcmp(metric, 'IGD');

    allTargets = [targets50, targets8];
    nT = numel(allTargets);
    nProbs = zeros(1, nT); nWin = zeros(1, nT); zMed = zeros(1, nT); nPairs = zeros(1, nT);

    for ti = 1:nT
        tg = allTargets{ti};
        % HCE 族用 50 问题，8 基线用 33 旧问题
        if startsWith(tg, 'HCEA')
            probs = problems50;
        else
            probs = problems33;
        end
        winCount = 0; nWinTotal = 0; zVals = [];
        for p = 1:numel(probs)
            d = [];
            for s = 1:30
                fn1 = fullfile(v4Dir, [refAlg '_' probs{p} '_s' num2str(s) '.mat']);
                fn2 = fullfile(resDir, [tg '_' probs{p} '_s' num2str(s) '.mat']);
                if ~isfile(fn1) || ~isfile(fn2), continue; end
                a = load(fn1).out; b = load(fn2).out;
                if ~isfield(a, metric) || ~isfield(b, metric), continue; end
                av = real(a.(metric)); bv = real(b.(metric));
                if numel(av) > 1, av = mean(av(:)); end
                if numel(bv) > 1, bv = mean(bv(:)); end
                if ~isfinite(av) || ~isfinite(bv), continue; end
                d(end+1,1) = av - bv;
            end
            if numel(d) < 5, continue; end
            nWinTotal = nWinTotal + 1;
            med = median(d);
            if isIGD
                win = (med < 0);
            else
                win = (med > 0);
            end
            if win, winCount = winCount + 1; end
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
            Rpos = sum(ranks(d > 0));
            Rneg = sum(ranks(d < 0));
            T = min(Rpos, Rneg);
            nn = numel(d);
            muT = nn*(nn+1)/4;
            sdT = sqrt(nn*(nn+1)*(2*nn+1)/24);
            zVals(end+1,1) = (T - muT)/sdT;
        end
        nProbs(ti) = nWinTotal;
        nWin(ti) = winCount;
        if ~isempty(zVals), zMed(ti) = median(abs(zVals)); else, zMed(ti) = NaN; end
        nPairs(ti) = nWinTotal * 30;
    end

    report.metric = metric;
    report.refAlg = refAlg;
    report.targets = allTargets;
    report.nProblems = nProbs;
    report.nWin = nWin;
    report.zMed = zMed;
    report.nPairs = nPairs;
end
