function smoke_sota_cf1()
% 冒烟：官方 FDSEA 在官方 CF1（M=2 D=10, 带约束）上 s1
% 验证：官方 ALGORITHM 隔离 path + 官方 PROBLEM + 约束处理 + 结果提取
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('algorithms\_platemo_official');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('algorithms\FDSEA');
    clear classes; clear IGD HV;

    N = 100; G = 200; maxFE = N*(G+1);
    offProb = feval('CF1'); offProb.Setting();
    offProb.N = N; offProb.maxFE = maxFE; offProb.FE = 0;
    fprintf('CF1: M=%d D=%d\n', offProb.M, offProb.D);
    try
        PF = offProb.GetOptimum(500);
        if isempty(PF) || ~all(isfinite(PF(:))), PF = UniformPoint(500, offProb.M); end
    catch
        PF = UniformPoint(500, offProb.M);
    end
    ref = 1.1 * max(PF, [], 1);

    rng(1);
    alg = feval('FDSEA','save',-1,'outputFcn',@noopOutput);
    t0 = tic;
    alg.Solve(offProb);
    fprintf('FDSEA CF1 s1 elap=%.1fs nFE=%d\n', toc(t0), offProb.FE);
    if ~isempty(alg.result)
        PopSOL = alg.result{end, 2};
        F = PopSOL.objs; cons = PopSOL.cons;
        [fn, ~] = NDSort(F, zeros(size(F,1),0), 1); nd = find(fn==1);
        if isempty(nd), nd = 1:size(F,1); end
        F = F(nd,:);
        igd = IGD(F, PF); hv = HV(F, ref);
        fprintf('FDSEA CF1 s1 IGD=%.4g HV=%.4g PPS=%d\n', igd, hv, numel(nd));
    else
        fprintf('FDSEA CF1 s1: result 空\n');
    end
end
function noopOutput(a, p)
end
