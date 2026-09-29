function prescreen_v6b()
% 预筛（选项3）两步：本地段（旧 EDD + EDDV6）→ 官方段（FDSEA）
% 两段分别落盘 .mat，最后汇总 IGD/HV 中位 + 胜负比
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');

    % ============ 段1：本地算法（旧 EDD + EDDV6），只 addpath 本地 ============
    addpath('problems'); addpath('problems\wfg_toolbox'); addpath('problems_official');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF');
    addpath('problems_official\CF'); addpath('problems_official\EMO');
    addpath('problems_official\MaF'); addpath('problems_official\DTLZ'); addpath('problems_ext');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    outDir = 'results\m5_prescreen';
    if ~isdir(outDir), mkdir(outDir); end

    for p = 1:2
        if p == 1
            pn = 'DTLZ2_M5'; wrap = M5Problem('DTLZ2', 5, 300);
        else
            pn = 'MaF14_M5'; wrap = M5Problem('MaF14', 5, 100);
        end
        PF = wrap.ParetoFront(500); ref = wrap.setRefPoint(PF).refPoint;
        for s = 1:3
            % 旧 EDD
            rng(s); algO = EDD(100, 200, s);
            [PopO, ~] = algO.run(wrap);
            [fn,~] = NDSort(PopO.objs, PopO.cons, 1); nd = find(fn==1);
            if isempty(nd), nd = 1:size(PopO.objs,1); end
            outO.IGD = IGD(PopO.objs(nd,:), PF); outO.HV = HV(PopO.objs(nd,:), ref);
            save(fullfile(outDir, [pn '_EDDOld_s' num2str(s) '.mat']), 'outO', '-v7.3');
            fprintf('%s 旧EDD s%d IGD=%.4g HV=%.4g\n', pn, s, outO.IGD, outO.HV);

            % EDDV6
            rng(s); algV = EDDV6(100, 200, s, 'full');
            [PopV, ~] = algV.run(wrap);
            [fn,~] = NDSort(PopV.objs, PopV.cons, 1); nd = find(fn==1);
            if isempty(nd), nd = 1:size(PopV.objs,1); end
            outV.IGD = IGD(PopV.objs(nd,:), PF); outV.HV = HV(PopV.objs(nd,:), ref);
            save(fullfile(outDir, [pn '_EDDV6_s' num2str(s) '.mat']), 'outV', '-v7.3');
            fprintf('%s EDDV6 s%d IGD=%.4g HV=%.4g\n', pn, s, outV.IGD, outV.HV);
        end
    end

    % ============ 段2：官方 FDSEA（需官方 path，与本地 ALGORITHM 隔离）===========
    % 清本地 algorithms（本地 ALGORITHM 类与官方冲突），加官方 ALGORITHM + FDSEA + 官方问题
    % 不 addpath 本地 problems（本地 DTLZ2/MaF14 classdef 会与官方同名类冲突）；
    % IGD/HV 是本地脚本函数（非 classdef），单独 addpath problems 不影响类解析
    rmpath('algorithms'); rmpath('algorithms\utils');
    clear classes; clear IGD HV;
    outDir2 = 'results\m5_prescreen';
    if ~isdir(outDir2), mkdir(outDir2); end
    addpath('algorithms\_platemo_official');
    addpath('algorithms\FDSEA');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\DTLZ');
    addpath('problems'); addpath('problems\wfg_toolbox');
    clear IGD HV;

    for p = 1:2
        if p == 1
            pn = 'DTLZ2_M5'; offProb = feval('DTLZ2_M5_D300');
        else
            pn = 'MaF14_M5'; offProb = feval('MaF14','M',5);
        end
        % PF/ref（与段1同口径）
        if p == 1
            PF = UniformPoint(500, 5); PF = PF ./ sqrt(sum(PF.^2,2));
        else
            PF = UniformPoint(500, 5);
        end
        ref = 1.1 * max(PF, [], 1);
        for s = 1:3
            fn = fullfile(outDir2, [pn '_FDSEA_s' num2str(s) '.mat']);
            if isfile(fn), continue; end
            try
                rng(s);
                offProb.N = 100; offProb.maxFE = 100*201; offProb.FE = 0;
                alg = feval('FDSEA','save',-1,'outputFcn',@noopOutput);
                alg.Solve(offProb);
                if isempty(alg.result)
                    outF.IGD = NaN; outF.HV = NaN;
                    fprintf('%s FDSEA s%d: 无结果（官方 FDSEA 可能不支持 M=5）\n', pn, s);
                else
                    PopSOL = alg.result{end,2};
                    F = PopSOL.objs;
                    [fn2,~] = NDSort(F, zeros(size(F,1),0), 1); nd = find(fn2==1);
                    if isempty(nd), nd = 1:size(F,1); end
                    F = F(nd,:);
                    outF.IGD = IGD(F, PF); outF.HV = HV(F, ref);
                end
                save(fn, 'outF', '-v7.3');
                fprintf('%s FDSEA s%d IGD=%.4g HV=%.4g\n', pn, s, outF.IGD, outF.HV);
            catch err
                outF.IGD = NaN; outF.HV = NaN;
                fprintf('%s FDSEA s%d FAIL: %s\n', pn, s, err.message);
                save(fn, 'outF', '-v7.3');
            end
        end
    end

    % ============ 汇总 ============
    summaryPrescreen(outDir);
end

function summaryPrescreen(outDir)
    addpath('problems'); addpath('problems\wfg_toolbox');
    clear IGD HV;
    for p = 1:2
        if p == 1, pn = 'DTLZ2_M5'; M = 5; D = 300;
        else, pn = 'MaF14_M5'; M = 5; D = 100; end
        if p == 1
            PF = UniformPoint(500, M); PF = PF ./ sqrt(sum(PF.^2,2));
        else
            PF = UniformPoint(500, M);
        end
        ref = 1.1 * max(PF, [], 1);
        igdO = nan(1,3); hvO = nan(1,3); igdV = nan(1,3); hvV = nan(1,3); igdF = nan(1,3); hvF = nan(1,3);
        for s = 1:3
            L = load(fullfile(outDir, [pn '_EDDOld_s' num2str(s) '.mat']));
            igdO(s)=L.outO.IGD; hvO(s)=L.outO.HV;
            L = load(fullfile(outDir, [pn '_EDDV6_s' num2str(s) '.mat']));
            igdV(s)=L.outV.IGD; hvV(s)=L.outV.HV;
            fn = fullfile(outDir2, [pn '_FDSEA_s' num2str(s) '.mat']);
            if isfile(fn)
                L = load(fn); igdF(s)=L.outF.IGD; hvF(s)=L.outF.HV;
            end
        end
        winOld = sum(igdV<igdO); loseOld = sum(igdV>igdO); tieOld = sum(igdV==igdO);
        winFD  = sum(igdV<igdF);  loseFD  = sum(igdV>igdF);  tieFD  = sum(igdF==igdV);
        hvWinOld = sum(hvV>hvO); hvLoseOld = sum(hvV<hvO);
        hvWinFD  = sum(hvV>hvF);  hvLoseFD  = sum(hvV<hvF);
        fprintf('\n=== %s（3 种子中位）===\n', pn);
        fprintf('  旧EDD : IGD=%.4f HV=%.4f | 逐种子 IGD=[%.3f %.3f %.3f] HV=[%.3f %.3f %.3f]\n', ...
            median(igdO), median(hvO), igdO, hvO);
        if any(~isnan(igdF))
            fprintf('  FDSEA : IGD=%.4f HV=%.4f | 逐种子 IGD=[%.3f %.3f %.3f] HV=[%.3f %.3f %.3f]\n', ...
                median(igdF), median(hvF), igdF, hvF);
        else
            fprintf('  FDSEA : NaN（官方不支持 M=5 或结果空）\n');
        end
        fprintf('  EDDV6 : IGD=%.4f HV=%.4f | 逐种子 IGD=[%.3f %.3f %.3f] HV=[%.3f %.3f %.3f]\n', ...
            median(igdV), median(hvV), igdV, hvV);
        fprintf('  胜负 IGD  V6:旧EDD = %d:%d (tie=%d)', winOld, loseOld, tieOld);
        if any(~isnan(igdF))
            fprintf('   V6:FDSEA = %d:%d (tie=%d)', winFD, loseFD, tieFD);
        else
            fprintf('   V6:FDSEA = N/A');
        end
        fprintf('\n  胜负 HV   V6:旧EDD = %d:%d', hvWinOld, hvLoseOld);
        if any(~isnan(hvF))
            fprintf('   V6:FDSEA = %d:%d\n', hvWinFD, hvLoseFD);
        else
            fprintf('   V6:FDSEA = N/A\n');
        end
    end
    fprintf('\n>>> 预筛完成：v6 在 DTLZ2_M5 + MaF14_M5 上 vs 旧EDD 胜负比见上\n');
end

function noopOutput(a, p)
end
