function run_edd_v2_lsmop()
% 阶段3.3：EDDV2 在 LSMOP1-3 上 30 种子（N=100 G=200 maxFE=20100）
% 对照旧 EDD 结果。纯数字循环，不用 cell/函数传递（避免 clear classes 影响）。
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox'); addpath('problems_official');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF');
    addpath('problems_official\CF'); addpath('problems_official\EMO'); addpath('problems_ext');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;
    outDir = 'results\largescale_edd_v2';
    if ~isdir(outDir), mkdir(outDir); end

    % ---- EDDV2 30 种子 × 3 题（纯数字循环）----
    for p = 1:3
        pn = ['LSMOP' num2str(p)];
        wrap = OfficialProblem(pn, 3, 300);
        PF   = wrap.ParetoFront(500);
        ref  = wrap.setRefPoint(PF).refPoint;
        for s = 1:30
            fn = fullfile(outDir, [pn '_EDDV2_s' num2str(s) '.mat']);
            if isfile(fn), continue; end
            rng(s);
            alg = EDDV2(100, 200, s);
            [Pop, Res] = alg.run(wrap);
            [fnr, ~] = NDSort(Pop.objs, Pop.cons, 1);
            nd = find(fnr==1); if isempty(nd), nd = 1:size(Pop.objs,1); end
            F = Pop.objs(nd,:);
            out.IGD = IGD(F, PF); out.HV = HV(F, ref);
            out.nFE = Res.nFE; out.elap = Res.nFE;
            out.PPS = numel(nd);
            save(fn, 'out', '-v7.3');
            fprintf('%s EDDV2 s%-2d IGD=%.4g HV=%.4g\n', pn, s, out.IGD, out.HV);
        end
    end

    % ---- 对照：旧 EDD 同 3 题 30 种子 + 逐题中位对比 ----
    clear classes; clear IGD HV;
    addpath('algorithms'); addpath('algorithms\utils');
    outDir2 = 'results\largescale_edd_v2';
    for p = 1:3
        pn = ['LSMOP' num2str(p)];
        wrap = OfficialProblem(pn, 3, 300);
        PF = wrap.ParetoFront(500); ref = wrap.setRefPoint(PF).refPoint;
        igdV = zeros(1,30); igdO = zeros(1,30); hvV = zeros(1,30); hvO = zeros(1,30);
        for s = 1:30
            L = load(fullfile(outDir2, [pn '_EDDV2_s' num2str(s) '.mat']));
            igdV(s) = L.out.IGD; hvV(s) = L.out.HV;
            % 旧 EDD
            clear classes; clear IGD HV;
            wrap2 = OfficialProblem(pn, 3, 300);
            PF2 = wrap2.ParetoFront(500); ref2 = wrap2.setRefPoint(PF2).refPoint;
            rng(s);
            alg2 = EDD(100, 200, s);
            [Pop2, Res2] = alg2.run(wrap2);
            [fnr2, ~] = NDSort(Pop2.objs, Pop2.cons, 1);
            nd2 = find(fnr2==1); if isempty(nd2), nd2 = 1:size(Pop2.objs,1); end
            igdO(s) = IGD(Pop2.objs(nd2,:), PF2); hvO(s) = HV(Pop2.objs(nd2,:), ref2);
        end
        medV = median(igdV); medO = median(igdO);
        win = sum(igdV < igdO); lose = sum(igdV > igdO);
        fprintf('\n=== %s: EDDV2 IGD中位=%.4f vs 旧EDD IGD中位=%.4f (%.1f%%)  胜负=%d:%d  HV %.4f->%.4f ===\n', ...
            pn, medV, medO, (medO-medV)/medO*100, win, lose, median(hvO), median(hvV));
    end
end
