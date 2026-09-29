function stats_result = run_statistics(resultsDir, metric)
% RUN_STATISTICS - 读取 results/main/*.mat 并执行 Friedman + Wilcoxon + Holm
% 支持不完整数据（部分 .mat 尚未生成时按实际可用数据计算）。
% metric: 'IGD'（越小越好）或 'HV'（越大越好）
%
% 返回字段：nSeeds, metric, meanRank, chi2, df, pFriedman, pRaw, holmP,
%          medianVals, seedCount, algs, probs

    if nargin < 1, resultsDir = 'results\main'; end
    if nargin < 2, metric = 'IGD'; end

    files = dir(fullfile(resultsDir, '*.mat'));
    if isempty(files)
        error('No .mat files in %s', resultsDir);
    end

    %% 解析文件名 → algs × probs × seeds
    algs  = {};
    probs = {};
    tmp   = {};
    for i = 1:numel(files)
        fname = files(i).name;
        base  = fname(1:numel(fname)-4);
        toks  = regexp(base, '^(.+)_(\w+)_s(\d+)$', 'tokens', 'once');
        if isempty(toks), continue; end
        aName = toks{1};
        pName = toks{2};
        seed  = str2double(toks{3});

        aIdx = find(strcmp(algs, aName), 1);
        if isempty(aIdx)
            aIdx = numel(algs)+1;
            algs{aIdx} = aName;
        end
        pIdx = find(strcmp(probs, pName), 1);
        if isempty(pIdx)
            pIdx = numel(probs)+1;
            probs{pIdx} = pName;
        end
        tmp{i} = struct('a', aIdx, 'p', pIdx, 's', seed, 'file', fname);
    end
    nAlg  = numel(algs);
    nProb = numel(probs);

    data = cell(nAlg, nProb);
    for i = 1:numel(tmp)
        loaded = load(fullfile(resultsDir, tmp{i}.file));
        if ~isfield(loaded.out, metric), continue; end
        val = loaded.out.(metric);
        val = val(1);
        data{tmp{i}.a, tmp{i}.p}(tmp{i}.s) = val;
    end

    seedCount = zeros(nAlg, nProb);
    for a = 1:nAlg
        for p = 1:nProb
            if ~isempty(data{a,p}), seedCount(a,p) = numel(data{a,p}); end
        end
    end
    sc = seedCount(seedCount > 0);
    if isempty(sc)
        error('Insufficient data for statistics');
    end
    minSeed = max(2, median(sc));
    fprintf('(metric=%s, using minSeed=%d, per-pair seed counts range %d-%d)\n', ...
        metric, minSeed, min(sc), max(sc));

    %% 1. Friedman 检验
    medianVals = zeros(nAlg, nProb);
    for a = 1:nAlg
        for p = 1:nProb
            if seedCount(a,p) >= minSeed
                vals = data{a,p}(1:minSeed);
            else
                vals = data{a,p};
            end
            medianVals(a,p) = median(vals);
        end
    end
    % IGD 越小越好 → ascend；HV 越大越好 → descend
    rankDir = 'ascend';
    if strcmpi(metric, 'HV'), rankDir = 'descend'; end
    ranks = zeros(nAlg, nProb);
    for p = 1:nProb
        [~, ord] = sort(medianVals(:,p), rankDir);
        ranks(ord, p) = 1:nAlg;
    end
    meanRank = mean(ranks, 2);
    R = sum(ranks, 2);
    chi2 = (12.0 / (nAlg*(nAlg+1)*nProb)) * sum(R.^2) - 3*nAlg*(nProb+1);
    df = nAlg - 1;
    pFriedman = 1 - cdf('chi2', chi2, df);

    %% 2. Wilcoxon + Holm（HCEAV2 vs 每个基线，所有问题×种子合并）
    hceaV2Idx = find(strcmp(algs, 'HCEAV2'), 1);
    if isempty(hceaV2Idx)
        error('HCEAV2 not found in results; cannot compute pairwise Wilcoxon');
    end
    pRaw = inf(1, nAlg);
    pRaw(hceaV2Idx) = 1;
    for a = 1:nAlg
        if a == hceaV2Idx, continue; end
        v1 = []; v2 = [];
        for pp = 1:nProb
            nAv = min([minSeed, seedCount(hceaV2Idx, pp), seedCount(a, pp)]);
            if nAv >= 2
                v1 = [v1; (data{hceaV2Idx, pp}(1:nAv))'];
                v2 = [v2; (data{a, pp}(1:nAv))'];
            end
        end
        if numel(v1) < 2, continue; end
        pRaw(a) = wilcoxon_test(v1(:), v2(:));
    end
    % Holm 校正
    testIdx = [1:hceaV2Idx-1, hceaV2Idx+1:nAlg];
    testP   = pRaw(testIdx);
    testP   = testP(isfinite(testP));
    [pSorted, sortIdx] = sort(testP);
    nTests = numel(pSorted);
    adjP = zeros(1, nTests);
    for j = 1:nTests
        adjP(j) = min(1, (nTests - j + 1) * pSorted(j));
    end
    holmP = inf(1, nAlg);
    holmP(hceaV2Idx) = 1;
    for j = 1:nTests
        holmP(testIdx(sortIdx(j))) = adjP(j);
    end

    meta.algs = algs;
    meta.probs = probs;
    stats_result = struct( ...
        'nSeeds', minSeed, ...
        'metric', metric, ...
        'meanRank', meanRank, ...
        'chi2', chi2, ...
        'df', df, ...
        'pFriedman', pFriedman, ...
        'pRaw', pRaw, ...
        'holmP', holmP, ...
        'medianVals', medianVals, ...
        'seedCount', seedCount);
    stats_result.meta = meta;

    fprintf('\n===== Statistics (%s, nProblems=%d) =====\n', metric, nProb);
    fprintf('Friedman: χ²=%.3f, df=%d, p=%.4g\n', chi2, df, pFriedman);
    if strcmpi(metric, 'HV')
        fprintf('Mean ranks (lower = better, HV higher is better):\n');
    else
        fprintf('Mean ranks (lower = better, IGD lower is better):\n');
    end
    for a = 1:nAlg
        fprintf('  %-12s rank=%5.2f  raw-p=%6.4g  holm-p=%6.4g\n', ...
            algs{a}, meanRank(a), pRaw(a), holmP(a));
    end
end
