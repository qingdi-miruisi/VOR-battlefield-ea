function make_pf_figs()
    % Pareto 前沿对比图
    %   每个问题出两张图：
    %     1) pf_<prob>_panels.png —— 5 个算法各一子图（f1-f2 投影），
    %        每子图自适应坐标 + 标题标注 IGD（因 LSMOP6 上 IGD 跨 3 个数量级，
    %        共享坐标会让 EDD 的前沿不可见）
    %     2) pf_<prob>_3d.png   —— 3D 视图（EDD 与真前沿 + 最强基线）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    if ~isdir('results\figs\out'), mkdir('results\figs\out'); end
    algs = {'EDD','HCEAV4','MOEAD','RVEA','NSGA2'};
    probNames = {'LSMOP6','LSMOP2','DTLZ2_300D_M3'};

    for p = 1:numel(probNames)
        pn = probNames{p};
        D = struct();
        ok = true;
        for a = 1:numel(algs)
            fn = fullfile('results\figs\pf', sprintf('%s_%s.mat', algs{a}, pn));
            if ~isfile(fn), ok = false; break; end
            D.(algs{a}) = load(fn);
        end
        if ~ok, fprintf('缺少 %s 数据，跳过\n', pn); continue; end
        PFtrue = D.('EDD').PFtrue;

        %% (1) 分面板 2D 投影
        f = figure('Visible','off','Position',[80 80 1180 700]);
        for a = 1:numel(algs)
            an = algs{a};
            subplot(2,3,a);
            plot(PFtrue(:,1), PFtrue(:,2), 'k.', 'MarkerSize', 4); hold on;
            F = D.(an).F;
            plot(F(:,1), F(:,2), 'o', 'MarkerSize', 5, 'LineWidth', 1.2);
            box on; grid on;
            xlabel('f_1'); ylabel('f_2');
            title(sprintf('%s   (IGD = %.4g, |front| = %d)', an, D.(an).igd, size(F,1)), ...
                'FontSize', 9);
            if a == 1
                legend({'true PF', an}, 'Location', 'northeast', 'FontSize', 7);
            end
        end
        % 第 6 格：共享坐标总览（log 友好提示）
        subplot(2,3,6);
        plot(PFtrue(:,1), PFtrue(:,2), 'k.', 'MarkerSize', 4); hold on;
        for a = 1:numel(algs)
            F = D.(algs{a}).F;
            plot(F(:,1), F(:,2), 'o', 'MarkerSize', 4);
        end
        box on; grid on; xlabel('f_1'); ylabel('f_2');
        title('All algorithms (shared axes)', 'FontSize', 9);
        legend([{'true PF'}, algs], 'Location', 'northeast', 'FontSize', 6);
        sgtitle(sprintf('Pareto fronts on %s (M=3, D=%d, seed 1)', pn, 300), ...
            'FontSize', 11, 'FontWeight', 'bold');
        exportgraphics(f, fullfile('results\figs\out', sprintf('pf_%s_panels.png', pn)), ...
            'Resolution', 300);
        close(f);
        fprintf('saved pf_%s_panels.png\n', pn);

        %% (2) 3D 视图（EDD + 真前沿 + IGD 最好的基线）
        [~, ord] = sort(cellfun(@(x) D.(x).igd, algs));
        bestBase = algs{ord(2)};   % 除 EDD 外 IGD 最优
        f = figure('Visible','off','Position',[80 80 900 640]);
        plot3(PFtrue(:,1), PFtrue(:,2), PFtrue(:,3), 'k.', 'MarkerSize', 6); hold on;
        F = D.('EDD').F;
        plot3(F(:,1), F(:,2), F(:,3), 'o', 'MarkerSize', 6, 'LineWidth', 1.6);
        Fb = D.(bestBase).F;
        plot3(Fb(:,1), Fb(:,2), Fb(:,3), '^', 'MarkerSize', 5, 'LineWidth', 1.2);
        box on; grid on;
        xlabel('f_1'); ylabel('f_2'); zlabel('f_3');
        title(sprintf('%s: EDD (IGD=%.4g) vs %s (IGD=%.4g) vs true PF', ...
            pn, D.('EDD').igd, bestBase, D.(bestBase).igd), 'FontSize', 10);
        legend({'true PF', 'EDD', bestBase}, 'Location', 'northeast', 'FontSize', 8);
        view(135, 20);
        exportgraphics(f, fullfile('results\figs\out', sprintf('pf_%s_3d.png', pn)), ...
            'Resolution', 300);
        close(f);
        fprintf('saved pf_%s_3d.png (baseline=%s)\n', pn, bestBase);
    end
end
