function run_ablation_edd()
    % EDD 组件消融：4 模式 × 3 问题 × 5 种子，G=200，N=100
    %   mode 0 = full EDD  |  1 = no-EED  |  2 = no-DSG  |  3 = no-polish
    % 数据存 results/ablation_abl/<mode>_<prob>_s<seed>.mat
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
    addpath('problems_official\EMO'); addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext'); addpath('experiments');
    clear classes; clear IGD HV;
    if ~isdir('results\ablation_abl'), mkdir('results\ablation_abl'); end

    modeNames = {'full','noEED','noDSG','noPolish'};
    modes = 0:3;
    probNames = {'LSMOP6','LSMOP9','LSMOP2'};
    seeds = 1:5;
    N = 100; G = 200;
    t0 = tic;
    for mi = 1:numel(modes)
        mode = modes(mi);
        for p = 1:numel(probNames)
            pn = probNames{p};
            prob = OfficialProblem(pn, 3, 300);
            PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
            for s = seeds
                fn = fullfile('results\ablation_abl', ...
                    sprintf('%s_%s_s%d.mat', modeNames{mi}, pn, s));
                if isfile(fn), continue; end
                try
                    alg = EDD_ABL(N, G, s, mode);
                    [~, Res] = alg.optimize(prob);
                    out.IGD = IGD(Res.F, PF); out.HV = HV(Res.F, ref);
                    out.PPS = size(Res.F,1); out.mech = Res.mechanism;
                    out.switchGen = Res.switchGen; out.nFE = Res.nFE; out.elap = Res.elap;
                    save(fn, 'out', '-v7.3');
                catch err
                    fprintf('FAIL %s %s s%d: %s\n', modeNames{mi}, pn, s, err.message);
                end
            end
            igdV = nan(1, numel(seeds));
            for k = 1:numel(seeds)
                fn = fullfile('results\ablation_abl', ...
                    sprintf('%s_%s_s%d.mat', modeNames{mi}, pn, seeds(k)));
                if isfile(fn), L = load(fn); igdV(k) = L.out.IGD; end
            end
            fprintf('%-9s %-8s IGD median=%.4g  elapsed=%.0fs\n', modeNames{mi}, pn, ...
                median(igdV, 'omitnan'), toc(t0));
        end
    end
    fprintf('=== EDD 消融完成 %.0fs ===\n', toc(t0));
end
