function report = wilcoxon_task1(resDir, v4Dir, refAlg, metric, targets, problems33, nSeeds)
% WILCOXON_TASK1 - 严格 problem×seed 配对 Wilcoxon + Holm 校正
    if nargin < 2, v4Dir = 'results\main_v4'; end
    if nargin < 3, refAlg = 'HCEAV4'; end
    if nargin < 4, metric = 'IGD'; end
    if nargin < 5
        targets = {'HCEA','HCEAV2','SMSEMOA','NSGA2','MOEAD','RVEA','SPEA2','NSGA3','AGEMOEA','MOGWO'};
    end
    if nargin < 6
        problems33 = {'ZDT1','ZDT2','ZDT3','ZDT4','ZDT5','ZDT6','DTLZ1','DTLZ2','DTLZ3', ...
            'DTLZ4','DTLZ5','DTLZ7','WFG1','WFG2','WFG3','WFG4','WFG5','WFG6','WFG7', ...
            'WFG8','WFG9','UF1','UF2','UF5','UF6','CMO1','CMO5','MaF1','MaF2','MaF3', ...
            'MaF4','MaF5','MaF11'};
    end
    if nargin < 7, nSeeds = 30; end
    nProb = numel(problems33);
    rawP = zeros(1, numel(targets));
    nPair = zeros(1, numel(targets));
    for ti = 1:numel(targets)
        tg = targets{ti};
        xv = []; yv = [];
        for p = 1:nProb
            for s = 1:nSeeds
                fn1 = fullfile(v4Dir, [refAlg '_' problems33{p} '_s' num2str(s) '.mat']);
                fn2 = fullfile(resDir, [tg '_' problems33{p} '_s' num2str(s) '.mat']);
                if ~isfile(fn1), continue; end
                if ~isfile(fn2), continue; end
                d1 = load(fn1);
                d2 = load(fn2);
                if ~isfield(d1,'out'), continue; end
                if ~isfield(d1.out,metric), continue; end
                if ~isfield(d2,'out'), continue; end
                if ~isfield(d2.out,metric), continue; end
                a = real(d1.out.(metric));
                b = real(d2.out.(metric));
                % 非标量处理：MaF 族 HV 可能存为常数向量，取 mean 作为标量
                if numel(a) > 1
                    a = mean(a(:));
                end
                if numel(b) > 1
                    b = mean(b(:));
                end
                if ~isfinite(a), continue; end
                if ~isfinite(b), continue; end
                xv(end+1,1) = a;
                yv(end+1,1) = b;
            end
        end
        nPair(ti) = numel(xv);
        rawP(ti) = wilcoxon_test(xv, yv);
    end
    % Holm 校正
    pSorted = sort(rawP);
    nT = numel(rawP);
    holmPSorted = min(1, pSorted .* (nT:-1:1)');
    [~, idx] = sort(rawP);
    holmPFinal = zeros(1, nT);
    for j = 1:nT
        holmPFinal(idx(j)) = holmPSorted(j);
    end
    report.metric = metric;
    report.refAlg = refAlg;
    report.targets = targets;
    report.rawP = rawP;
    report.holmP = holmPFinal;
    report.nPairs = nPair;
    report.sigRaw = rawP < 0.05;
    report.sigHolm = holmPFinal < 0.05;
end
