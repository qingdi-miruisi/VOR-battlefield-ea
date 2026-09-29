function fill_mogwo()
% 补跑 MOGWO 在 CF/MW 的缺失种子（断点续跑，已存在的 mat 跳过）
% 用绝对路径 addpath（避免 cd 到 experiments 后相对路径失效）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    probs = cell(0,1);
    for i = 1:10, probs{end+1} = ['CF' num2str(i)]; end
    for i = [1 2 3 4 5 6], probs{end+1} = ['MW' num2str(i)]; end
    N = 100; G = 200;
    an = 'MOGWO';
    algDir = fullfile('results','cf_baselines',an);
    if ~isdir(algDir), mkdir(algDir); end
    nDone = 0; nFail = 0;
    for p = 1:numel(probs)
        pn = probs{p};
        wrap = OfficialProblem(pn, 2, 10);
        PF = wrap.ParetoFront(500); ref = wrap.setRefPoint(PF).refPoint;
        for s = 1:30
            fn = fullfile(algDir, [pn '_' an '_s' num2str(s) '.mat']);
            if isfile(fn), continue; end
            try
                rng(s); alg = MOGWO(N, G, s); [Pop, Res] = alg.run(wrap);
                [fn2, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn2==1);
                if isempty(nd), nd = 1:size(Pop.objs,1); end
                F = Pop.objs(nd,:);
                out.IGD = IGD(F, PF); out.HV = HV(F, ref);
                out.nFE = Res.nFE; out.PPS = numel(nd);
                save(fn, 'out', '-v7.3');
                nDone = nDone + 1;
            catch err
                nFail = nFail + 1;
                fprintf('  MOGWO %s s%d FAIL: %s\n', pn, s, err.message);
            end
        end
    end
    fprintf('MOGWO CF/MW 补跑: done=%d fail=%d\n', nDone, nFail);
end
