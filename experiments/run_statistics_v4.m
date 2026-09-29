function stats = run_statistics_v4(resultsDir, metric, refAlg)
% RUN_STATISTICS_V4 - 以 refAlg（默认 'HCEAV4'）为 Wilcoxon 参考算法，
% 严格按 problem × seed 配对，输出 Friedman + Wilcoxon + Holm 完整表。
%
% 与旧 run_statistics 的区别（修复致命缺陷）：
%   1. Wilcoxon 参考算法由参数 refAlg 指定（旧版硬编码 HCEAV2）；
%   2. 配对按【同 problem + 同 seed 键】显式匹配，而非按文件位置对齐
%      （位置对齐仅在两算法 seed 集合完全相同且排序一致时碰巧正确）；
%   3. 保留全量种子级数据到 stats.seedData，供复核。
%
% 用法：
%   stats = run_statistics_v4('results\merged_v4', 'IGD', 'HCEAV4');
%   stats = run_statistics_v4('results\merged_v4', 'HV',  'HCEAV4');

    if nargin < 1, resultsDir = 'results\merged_v4'; end
    if nargin < 2, metric     = 'IGD'; end
    if nargin < 3, refAlg     = 'HCEAV4'; end

    files = dir(fullfile(resultsDir, '*.mat'));
    if isempty(files), error('No .mat in %s', resultsDir); end

    %% 1) 解析文件名 → 显式 (alg, prob, seed) 键
    algs = {}; probs = {};
    seedData = containers.Map('KeyType','char','ValueType','double');
    nUsed = 0;
    for i = 1:numel(files)
        base = files(i).name;
        if endsWith(base, '.mat'), base = base(1:end-4); end
        toks = regexp(base, '^(.+)_(\w+)_s(\d+)$', 'tokens', 'once');
        if isempty(toks), continue; end
        a = toks{1}; p = toks{2}; s = str2double(toks{3});
        loaded = load(fullfile(resultsDir, files(i).name));
        if ~isstruct(loaded.out), continue; end
        if ~isfield(loaded.out, metric), continue; end
        val = loaded.out.(metric);
        if ~isnumeric(val) || numel(val) ~= 1, continue; end
        val = real(val(1));   % MaF 族的 IGD 可能带 1e-9 量级虚部，取实数
        if ~isfinite(val), continue; end
        key = [a '|' p '|' num2str(s)];
        seedData(key) = double(val);
        if ~any(strcmp(algs, a)), algs{end+1} = a; end
        if ~any(strcmp(probs, p)), probs{end+1} = p; end
        nUsed = nUsed + 1;
    end
    nAlg = numel(algs); nProb = numel(probs);
    fprintf('[run_statistics_v4] %s/%s: %d algos, %d probs, %d records\n', ...
        resultsDir, metric, nAlg, nProb, nUsed);

    %% 2) 组织 (alg, prob) → [seeds x 1] 值（按 seed 号排序，用 cell 存储）
    data = cell(nAlg, nProb);      % 值（按 seed 升序）
    seedKeys = cell(nAlg, nProb);  % 对应 seed 号
    for a = 1:nAlg
        for p = 1:nProb
            v = []; sk = [];
            for s = 1:60
                cellKey = [algs{a} '|' probs{p} '|' num2str(s)];
                if isKey(seedData, cellKey)
                    v(end+1) = seedData(cellKey);
                    sk(end+1) = s;
                end
            end
            data{a,p} = v(:);
            seedKeys{a,p} = sk(:);
        end
    end

    %% 3) Friedman（全量种子中位数排名）
    medianVals = zeros(nAlg, nProb);
    for a = 1:nAlg
        for p = 1:nProb
            v = data{a,p};
            if isempty(v)
                medianVals(a,p) = NaN;
            else
                medianVals(a,p) = median(v);
            end
        end
    end
    rankDir = 'ascend';
    if strcmpi(metric, 'HV'), rankDir = 'descend'; end
    ranks = zeros(nAlg, nProb);
    nProbsRank = 0;
    for p = 1:nProb
        col = medianVals(:,p);
        if all(isfinite(col))
            [~, ord] = sort(col, rankDir);
            ranks(ord, p) = 1:nAlg;
            nProbsRank = nProbsRank + 1;
        end
    end
    meanRank = nanmean(ranks, 2);
    R = nansum(ranks, 2);
    chi2 = (12.0 / (nAlg*(nAlg+1)*nProbsRank)) * sum(R.^2) - 3*nAlg*(nProbsRank+1);
    df = nAlg - 1;
    pFriedman = 1 - cdf('chi2', chi2, df);

    %% 4) Wilcoxon：refAlg vs 每个其他算法，按 (prob, seed) 显式配对
    refIdx = find(strcmp(algs, refAlg), 1);
    if isempty(refIdx)
        error('refAlg %s not found', refAlg);
    end
    pRaw = inf(1, nAlg);
    pRaw(refIdx) = 1;
    holmP = inf(1, nAlg);
    holmP(refIdx) = 1;
    nPairs = nAlg - 1;
    pairInfo = repmat(struct('algo', '', 'nPairs', 0, 'rawP', NaN, 'nTotal', 0), 1, nPairs);
    for a = 1:nAlg
        if a == refIdx, continue; end
        k = a - (a > refIdx);   % 配对序号（跳过 refIdx）
        v1 = []; v2 = [];
        for p = 1:nProb
            vr = data{refIdx, p};
            va = data{a, p};
            sr = seedKeys{refIdx, p};
            sa = seedKeys{a, p};
            if isempty(vr) || isempty(va), continue; end
            common = intersect(sr, sa);
            ir = ismember(sr, common);
            ia = ismember(sa, common);
            if numel(common) >= 2
                v1 = [v1; vr(ir)];
                v2 = [v2; va(ia)];
            end
        end
        if numel(v1) < 2
            pRaw(a) = NaN;
            pairInfo(k).algo = algs{a}; pairInfo(k).nPairs = 0;
            pairInfo(k).rawP = NaN; pairInfo(k).nTotal = numel(v1);
            continue;
        end
        pRaw(a) = wilcoxon_test(v1, v2);
        pairInfo(k).algo = algs{a};
        pairInfo(k).nPairs = numel(v1);
        pairInfo(k).rawP = pRaw(a);
        pairInfo(k).nTotal = numel(v1);
    end
    % Holm
    testIdx = [1:refIdx-1, refIdx+1:nAlg];
    testP = pRaw(testIdx);
    keep = isfinite(testP);
    testIdx = testIdx(keep); testP = testP(keep);
    nTests = numel(testP);
    [pSorted, sortIdx] = sort(testP);
    adjP = zeros(1, nTests);
    for j = 1:nTests
        adjP(j) = min(1, (nTests - j + 1) * pSorted(j));
    end
    for j = 1:nTests
        holmP(testIdx(sortIdx(j))) = adjP(j);
    end

    %% 5) 组装结果
    stats = struct( ...
        'refAlg', refAlg, ...
        'nSeeds', 30, ...
        'metric', metric, ...
        'meanRank', meanRank, ...
        'chi2', chi2, 'df', df, 'pFriedman', pFriedman, ...
        'pRaw', pRaw, 'holmP', holmP, ...
        'medianVals', medianVals, ...
        'seedData', seedData, ...
        'pairInfo', pairInfo);
    stats.meta.algs = algs;
    stats.meta.probs = probs;

    fprintf('\n===== %s (ref=%s): Friedman χ²=%.3f, df=%d, p=%.4g =====\n', ...
        metric, refAlg, chi2, df, pFriedman);
    fprintf('Mean ranks (%s):\n', metric);
    for a = 1:nAlg
        fprintf('  %-12s rank=%6.3f   raw-p=%8.4g   holm-p=%8.4g\n', ...
            algs{a}, meanRank(a), pRaw(a), holmP(a));
    end
end

function n = common_total(v1, v2)
    n = numel(v1);
end
