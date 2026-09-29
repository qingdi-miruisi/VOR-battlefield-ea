function make_figs()
    % 生成论文图：收敛曲线（2 题 × 11 算法）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    if ~isdir('results\figs\out'), mkdir('results\figs\out'); end
    algs = {'EDD','HCEA','HCEAV4','NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD'};
    probs = {'LSMOP6','LSMOP2'};
    titles = {'LSMOP6 (collapse instance)', 'LSMOP2 (converged instance)'};

    for p = 1:numel(probs)
        f = figure('Visible','off','Position',[100 100 760 520]);
        hold on; box on; grid on;
        leg = {};
        for a = 1:numel(algs)
            fn = fullfile('results\figs\conv', sprintf('%s_%s.mat', algs{a}, probs{p}));
            if ~isfile(fn), continue; end
            L = load(fn);
            m = median(L.traj, 2, 'omitnan');
            if strcmp(algs{a}, 'EDD')
                plot(L.fe, m, '-o', 'LineWidth', 2.6, 'MarkerSize', 5);
            else
                plot(L.fe, m, '-', 'LineWidth', 1.2);
            end
            leg{end+1} = algs{a};
        end
        set(gca, 'YScale', 'log');
        xlabel('Function evaluations');
        ylabel('IGD (median of 3 seeds, log scale)');
        title(titles{p});
        legend(leg, 'Location', 'eastoutside', 'FontSize', 8);
        exportgraphics(f, fullfile('results\figs\out', sprintf('conv_%s.png', probs{p})), 'Resolution', 300);
        close(f);
        fprintf('saved conv_%s.png\n', probs{p});
    end

    %% 消融柱状图
    modeNames = {'full','noEED','noDSG','noPolish'};
    probNames = {'LSMOP6','LSMOP9','LSMOP2'};
    seeds = 1:5;
    M = nan(numel(modeNames), numel(probNames));
    for mi = 1:numel(modeNames)
        for p = 1:numel(probNames)
            v = nan(1,numel(seeds));
            for k = 1:numel(seeds)
                fn = fullfile('results\ablation_abl', ...
                    sprintf('%s_%s_s%d.mat', modeNames{mi}, probNames{p}, seeds(k)));
                if isfile(fn), L = load(fn); v(k) = L.out.IGD; end
            end
            M(mi,p) = median(v,'omitnan');
        end
    end
    f = figure('Visible','off','Position',[100 100 700 480]);
    bar(log10(M'));
    set(gca, 'XTickLabel', probNames);
    ylabel('log_{10}(IGD median)');
    legend(modeNames, 'Location', 'northwest', 'FontSize', 8);
    title('Component ablation: log_{10} IGD (lower is better)');
    grid on; box on;
    exportgraphics(f, fullfile('results\figs\out', 'ablation_bar.png'), 'Resolution', 300);
    close(f);
    fprintf('saved ablation_bar.png\n');
end
