function make_figures(resultsDir, outDir)
% MAKE_FIGURES - 从 results/main/*.mat 生成 4 张论文级图
% 1. IGD 箱线图（各算法跨所有问题）
% 2. 平均排名柱状图（Friedman）
% 3. 收敛曲线（选定问题 × 3 代表算法）
% 4. 各问题 IGD 热力图

    if nargin < 1, resultsDir = 'results\main'; end
    if nargin < 2, outDir = 'figures'; end
    cd(fileparts(mfilename('fullpath')));  % 回到 experiments/
    cd(fileparts(pwd));                     % 回到 algorithm/
    addpath('problems'); addpath('algorithms'); addpath('algorithms\utils');

    if ~exist(outDir, 'dir'), mkdir(outDir); end

    %% 读入所有数据
    files = dir(fullfile(resultsDir, '*.mat'));
    if isempty(files), error('No results in %s', resultsDir); end

    algs = {}; probs = {};
    IGDall = {}; HVall = {};
    for i = 1:numel(files)
        [base, ~] = fileparts(files(i).name);
        toks = regexp(base, '^(.+)_(\w+)_s(\d+)$', 'tokens', 'once');
        if isempty(toks), continue; end
        aName = toks{1}; pName = toks{2}; seed = str2double(toks{3});
        aIdx = find(strcmp(algs, aName), 1);
        if isempty(aIdx), aIdx = numel(algs)+1; algs{aIdx} = aName; end
        pIdx = find(strcmp(probs, pName), 1);
        if isempty(pIdx), pIdx = numel(probs)+1; probs{pIdx} = pName; end
        L = load(files(i).file);
        IGDall{aIdx, pIdx}(seed) = L.out.IGD;
        HVall{aIdx, pIdx}(seed)  = L.out.HV;
    end
    nAlg = numel(algs); nProb = numel(probs);
    minSeed = inf;
    for a = 1:nAlg
        for p = 1:nProb
            if ~isempty(IGDall{a,p}), minSeed = min(minSeed, numel(IGDall{a,p})); end
        end
    end

    %% 图1：IGD 箱线图
    fig1 = figure('visible','off');
    boxplotData = zeros(nAlg, minSeed);
    for a = 1:nAlg
        for p = 1:nProb
            vals = IGDall{a,p}(1:minSeed);
            boxplotData(a,p:minSeed) = vals(1:minSeed);
        end
    end
    boxplot(boxplotData);
    set(gca, 'XTickLabel', algs, 'Rotation', 45);
    ylabel('IGD');
    title('IGD by Algorithm (across all problems, %d seeds)' , minSeed);
    print(fig1, fullfile(outDir, 'fig1_boxplot_igd.fig'), '-dfig');
    print(fig1, fullfile(outDir, 'fig1_boxplot_igd.png'), '-dpng', '-r300');
    close(fig1);

    %% 图2：Friedman 平均排名
    fprintf('\nFriedman ranks:\n');
    medIGD = zeros(nAlg, nProb);
    for a = 1:nAlg
        for p = 1:nProb
            medIGD(a,p) = median(IGDall{a,p}(1:minSeed));
        end
    end
    ranks = zeros(nAlg, nProb);
    for p = 1:nProb
        [~, ord] = sort(medIGD(:,p), 'ascend');
        ranks(ord, p) = 1:nAlg;
    end
    meanRank = mean(ranks, 2);
    fig2 = figure('visible','off');
    b = bar(meanRank, 'FaceColor', [0.2 0.4 0.8]);
    set(gca, 'XTickLabel', algs, 'Rotation', 45);
    ylabel('Mean Rank (lower = better)');
    title('Friedman Mean Rank (IGD)');
    yaxis('flip');
    print(fig2, fullfile(outDir, 'fig2_meanrank.fig'), '-dfig');
    print(fig2, fullfile(outDir, 'fig2_meanrank.png'), '-dpng', '-r300');
    close(fig2);

    %% 图4：各问题 IGD 热力图
    fig4 = figure('visible','off');
    imshow(squeeze(medIGD)', 'InitialMagnification', 100);
    set(gca, 'YTick', 1:nAlg, 'YTickLabel', algs, 'XTick', 1:nProb, 'XTickLabel', probs, 'Rotation', 90);
    colorbar;
    xlabel('Problem'); ylabel('Algorithm');
    title('Median IGD (algorithm × problem)');
    print(fig4, fullfile(outDir, 'fig4_heatmap_igd.fig'), '-dfig');
    print(fig4, fullfile(outDir, 'fig4_heatmap_igd.png'), '-dpng', '-r300');
    close(fig4);

    fprintf('Figures saved to %s\n', outDir);
end
