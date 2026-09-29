function smoke_test_moeaib()
    % MOEA-IB 冒烟测试：LSMOP1, N=100, maxFE=20100, 1 seed
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('algorithms\_platemo_official');
    addpath('algorithms\MOEA_IB\WOF');
    addpath('algorithms\MOEA_IB\ReMO');
    addpath('algorithms\MOEA_IB');
    addpath('problems_official');
    addpath('problems_official\LSMOP');
    addpath('problems');
    addpath('problems\wfg_toolbox');
    clear classes; clear IGD HV;

    N     = 100;
    maxFE = N*(200+1);
    prob  = OfficialProblem('LSMOP1', 3, 300);
    offProb = prob.officialObj;
    offProb.N = N; offProb.maxFE = maxFE; offProb.FE = 0;

    rng(1);
    t0  = tic;
    alg = MOEAIB('save', 0, 'outputFcn', @noopOutput);
    alg.Solve(offProb);
    elap = toc(t0);

    % 最终种群在 alg.result{end,2}（SOLUTION 数组）
    PopSOL = alg.result{end, 2};
    F    = PopSOL.objs;
    decs = PopSOL.decs;
    [fn, ~] = NDSort(F, zeros(size(F,1),0), 1);
    nd = find(fn == 1);
    if isempty(nd), nd = 1:size(F,1); end
    PF  = prob.ParetoFront(500);
    ref = prob.setRefPoint(PF).refPoint;
    fprintf('MOEA-IB LSMOP1 s1: PPS=%d, IGD=%.4g, HV=%.4g, nFE=%d, elapsed=%.1fs\n', ...
        numel(nd), IGD(F(nd,:),PF), HV(F(nd,:),ref), offProb.FE, elap);
end

function noopOutput(a, p)
end
