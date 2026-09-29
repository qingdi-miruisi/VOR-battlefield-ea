function report = wilcoxon_full(dirV4, dirMain, refAlg, metric, targets, problems33, nSeeds)
% 严格 Wilcoxon 配对（problem×seed 显式匹配）：refAlg vs targets，输出 raw-p / Holm-p / 显著性
    if nargin < 4, metric = 'IGD'; end
    if nargin < 5, targets = {'HCEA','HCEAV2','SMSEMOA','NSGA2','MOEAD','RVEA','SPEA2','NSGA3','AGEMOEA','MOGWO'}; end
    if nargin < 6
        problems33 = {'ZDT1','ZDT2','ZDT3','ZDT4','ZDT5','ZDT6', ...
                      'DTLZ1','DTLZ2','DTLZ3','DTLZ4','DTLZ5','DTLZ7', ...
                      'WFG1','WFG2','WFG3','WFG4','WFG5','WFG6','WFG7','WFG8','WFG9', ...
                      'UF1','UF2','UF5','UF6','CMO1','CMO5', ...
                      'MaF1','MaF2','MaF3','MaF4','MaF5','MaF11'};
    end
    if nargin < 7, nSeeds = 30; end
    nProb = numel(problems33);
    v1 = zeros(nProb, nSeeds); v2 = zeros(nProb, nSeeds);
    v1(:) = NaN; v2(:) = NaN;
    for p = 1:nProb
        for s = 1:nSeeds
            fn1 = fullfile(dirV4, [refAlg '_' problems33{p} '_s' num2str(s) '.mat']);
            for ti = 1:numel(targets)
                tg = targets{ti};
                fn2 = fullfile(dirMain, [tg '_' problems33{p} '_s' num2str(s) '.mat']);
                if ~isfile(fn1) || ~isfile(fn2), continue; end
                d1 = load(fn1); d2 = load(fn2);
                if ~isfield(d1,'out') || ~isfield(d1.out,metric) || ~isfield(d2,'out') || ~isfield(d2.out,metric)
                    continue;
                end
                a = real(d1.out.(metric)); b = real(d2.out.(metric));
                if isfinite(a) && isfinite(b)
                    % 存到第 ti 列
                    v1(p,s) = v1(p,s); % 占位（refAlg 固定，下面单独存）
                end
            end
        end
    end
    % 重新组织：逐 target 配对
    rawP = zeros(1, numel(targets));
    nPair = zeros(1, numel(targets));
    refVals = cell(numel(targets),1);
    tarVals = cell(numel(targets),1);
    for ti = 1:numel(targets)
        tg = targets{ti};
        xv = []; yv = [];
        for p = 1:nProb
            for s = 1:nSeeds
                fn1 = fullfile(dirV4, [refAlg '_' problems33{p} '_s' num2str(s) '.mat']);
                fn2 = fullfile(dirMain, [tg '_' problems33{p} '_s' num2str(s) '.mat']);
                if ~isfile(fn1) || ~isfile(fn2), continue; end
                d1 = load(fn1); d2 = load(fn2);
                if ~isfield(d1,'out') || ~isfield(d1.out,metric) || ~isfield(d2,'out') || ~isfield(d2.out,metric)
                    continue;
                end
                a = real(d1.out.(metric)); b = real(d2.out.(metric));
                if isfinite(a) && isfinite(b)
                    xv(end+1) = a; yv(end+1) = b;
                end
            end
        end
        refVals{ti} = xv; tarVals{ti} = yv;
        nPair(ti) = numel(xv);
        rawP(ti) = wilcoxon_test(xv, yv);
    end
    % Holm 校正
    pSorted = sort(rawP);
    nT = numel(rawP);
    holm = pSorted .* (nT:-1:1)';
    holm = min(1, holm);
    % 找 rawP 升序位置对应的 holm
    [~, idx] = sort(rawP);
    holmP = zeros(1, nT);
    holmP(idx) = holm;
    report.metric = metric;
    report.refAlg = refAlg;
    report.targets = targets;
    report.rawP = rawP;
    report.holmP = holmP;
    report.nPairs = nPair;
    report.sigRaw = rawP < 0.05;
    report.sigHolm = holmP < 0.05;
end
