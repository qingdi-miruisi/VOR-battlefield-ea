function prescreen_fdsea()
% 段2：官方 FDSEA 在 DTLZ2_M5 + MaF14_M5 上 3 种子（独立 session 跑，避免 path 冲突）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('algorithms\_platemo_official');
    addpath('algorithms\FDSEA');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\DTLZ');
    addpath('problems'); addpath('problems\wfg_toolbox');
    clear classes; clear IGD HV;

    outDir2 = 'results\m5_prescreen';
    if ~isdir(outDir2), mkdir(outDir2); end

    for p = 1:2
        if p == 1
            pn = 'DTLZ2_M5'; offProb = feval('DTLZ2_M5_D300');
            PF = UniformPoint(500, 5); PF = PF ./ sqrt(sum(PF.^2,2));
        else
            pn = 'MaF14_M5'; offProb = feval('MaF14','M',5);
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
    fprintf('>>> 段2 FDSEA 完成\n');
end

function noopOutput(a, p)
end
