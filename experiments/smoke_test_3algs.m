function smoke_test_3algs()
    % 冒烟测试 GDVTSF / MOEA-IB / LDS-AF：LSMOP1, N=20, G=5, 1 seed
    % 目的：确认 3 个算法在 headless（无 GUI）下都能跑通，不报 Draw/drawnow 错
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('algorithms\_platemo_official');
    addpath('algorithms\GDVTSF');
    addpath('algorithms\MOEA_IB\WOF');
    addpath('algorithms\MOEA_IB\ReMO');
    addpath('algorithms\MOEA_IB');
    addpath('algorithms\LDSAF');
    addpath('problems_official');
    addpath('problems_official\LSMOP');
    addpath('problems');
    addpath('problems\wfg_toolbox');
    addpath('problems_ext');
    clear classes; clear IGD HV;

    algs = {'GDVTSF','MOEAIB','LDSAF'};
    N     = 20;
    G     = 5;
    maxFE = N*(G+1);

    prob = OfficialProblem('LSMOP1', 3, 300);
    PF   = prob.ParetoFront(200);
    ref  = prob.setRefPoint(PF).refPoint;

    for j = 1:numel(algs)
        an = algs{j};
        try
            off = prob.officialObj;
            off.N = N; off.maxFE = maxFE; off.FE = 0;
            rng(1);
            alg = feval(an, 'save', -1, 'outputFcn', @noopOutput);
            alg.Solve(off);
            F = alg.result{end,2}.objs;
            [fn,~] = NDSort(F, zeros(size(F,1),0), 1);
            nd = find(fn==1);
            if isempty(nd), nd = 1:size(F,1); end
            fprintf('%-8s N=%d G=%d s1: PPS=%d, IGD=%.4g, HV=%.4g, nFE=%d  [OK]\n', ...
                an, N, G, numel(nd), IGD(F(nd,:),PF), HV(F(nd,:),ref), off.FE);
        catch err
            fprintf('%-8s FAIL: %s\n', an, err.message);
            if err.stack(1).name ~= an
                fprintf('  出错函数: %s (行 %d)\n', err.stack(1).name, err.stack(1).line);
            end
        end
    end
end

function noopOutput(a, p)
end
