function gen_paper_figures()
% GEN_PAPER_FIGURES  Export PDF versions of the core figures (from .fig) and
% build a 5-problem IGD boxplot (fig5) from raw_data.mat.
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\utils');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\problems');

PAP  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\paper\figures\';
RES  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\';

% PDF exports from existing .fig files
src = { [RES 'new_algorithm\figures\fig1_boxplots.fig'], [RES 'new_algorithm\figures\fig2_pareto_fronts.fig'], ...
        [RES 'new_algorithm\figures\fig3_hcea_convergence.fig'], [RES 'metric_disagreement\figures\fig4_cd_igd.fig'], ...
        [RES 'metric_disagreement\figures\fig4_cd_hv.fig'] };
dst = { 'fig1_boxplots.pdf', 'fig2_pareto_fronts.pdf', 'fig3_hcea_convergence.pdf', 'fig4_cd_igd.pdf', 'fig4_cd_hv.pdf' };
for i = 1:numel(src)
    f = openfig(src{i}, 'invisible');
    exportgraphics(f, [PAP dst{i}], 'ContentType', 'vector');
    close(f);
    fprintf('exported %s\n', dst{i});
end

% fig5: 5-problem IGD boxplot (all 9 algorithms)
S = load([RES 'metric_disagreement\raw_data.mat']);
IGD = S.IGD; algos = S.algos; probName = S.probName;
f5 = figure('Position', [100 100 1400 420], 'Color', 'w');
for ip = 1:5
    subplot(1, 5, ip);
    X = squeeze(IGD(ip,:,:))';   % 30 x 9
    boxplot(X, algos);
    set(gca, 'YScale', 'log');
    set(gca, 'XTickLabelRotation', 90);
    title(probName{ip});
    if ip == 1, ylabel('IGD (log)'); end
    grid on;
end
exportgraphics(f5, [PAP 'fig5_boxplots_5problems.png'], 'Resolution', 150);
exportgraphics(f5, [PAP 'fig5_boxplots_5problems.pdf'], 'ContentType', 'vector');
savefig(f5, [PAP 'fig5_boxplots_5problems.fig']);
close(f5);
fprintf('wrote fig5\n');
end
