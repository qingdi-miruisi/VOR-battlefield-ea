function analyze_abl_conv()
    % 汇总消融 + 收敛曲线数据，打印论文用数字
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils');

    %% ===== 1. 消融汇总 =====
    modeNames = {'full','noEED','noDSG','noPolish'};
    probNames = {'LSMOP6','LSMOP9','LSMOP2'};
    seeds = 1:5;
    fprintf('=== EDD 组件消融（G=200, N=100, 5 种子中位）===\n');
    fprintf('%-10s', 'mode');
    for p = 1:numel(probNames), fprintf('%14s', probNames{p}); end
    fprintf('\n');
    IGD = nan(numel(modeNames), numel(probNames));
    HV  = nan(numel(modeNames), numel(probNames));
    for mi = 1:numel(modeNames)
        fprintf('%-10s', modeNames{mi});
        for p = 1:numel(probNames)
            iv = nan(1,numel(seeds)); hv = nan(1,numel(seeds));
            for k = 1:numel(seeds)
                fn = fullfile('results\ablation_abl', ...
                    sprintf('%s_%s_s%d.mat', modeNames{mi}, probNames{p}, seeds(k)));
                if isfile(fn), L = load(fn); iv(k)=L.out.IGD; hv(k)=L.out.HV; end
            end
            IGD(mi,p) = median(iv,'omitnan'); HV(mi,p) = median(hv,'omitnan');
            fprintf('%14.4g', IGD(mi,p));
        end
        fprintf('\n');
    end
    fprintf('\n--- 相对完整版的 IGD 倍数 ---\n%-10s', 'mode');
    for p = 1:numel(probNames), fprintf('%14s', probNames{p}); end
    fprintf('\n');
    for mi = 2:numel(modeNames)
        fprintf('%-10s', modeNames{mi});
        for p = 1:numel(probNames)
            fprintf('%13.1fx', IGD(mi,p)/IGD(1,p));
        end
        fprintf('\n');
    end
    fprintf('\n--- HV（大=好）---\n%-10s', 'mode');
    for p = 1:numel(probNames), fprintf('%14s', probNames{p}); end
    fprintf('\n');
    for mi = 1:numel(modeNames)
        fprintf('%-10s', modeNames{mi});
        for p = 1:numel(probNames), fprintf('%14.4g', HV(mi,p)); end
        fprintf('\n');
    end

    %% ===== 2. 收敛曲线汇总（G=200 处 IGD）=====
    fprintf('\n=== 收敛曲线：G=200 处 IGD 中位 ===\n');
    algs = {'EDD','HCEA','HCEAV4','NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD'};
    probs = {'LSMOP6','LSMOP2'};
    for p = 1:numel(probs)
        fprintf('\n--- %s ---\n', probs{p});
        for a = 1:numel(algs)
            fn = fullfile('results\figs\conv', sprintf('%s_%s.mat', algs{a}, probs{p}));
            if ~isfile(fn), fprintf('  %-8s (missing)\n', algs{a}); continue; end
            L = load(fn);
            fprintf('  %-8s G=25: %10.4g   G=100: %10.4g   G=200: %10.4g\n', ...
                algs{a}, median(L.traj(1,:),'omitnan'), ...
                median(L.traj(3,:),'omitnan'), median(L.traj(end,:),'omitnan'));
        end
    end

    save('results\ablation_abl\ablation_summary.mat', 'modeNames','probNames','IGD','HV');
    fprintf('\nsaved results\\ablation_abl\\ablation_summary.mat\n');
end
