% SOTA CF/MW 30-seed 基准：FDSEA / GDVTSF / MOEA-IB
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
N = 100; G = 200; maxFE = N*(G+1);
bClass = {'FDSEA','GDVTSF','MOEAIB'};
bDir   = {'FDSEA','GDVTSF','MOEA-IB'};
bEP = {
    {'algorithms\FDSEA'},
    {'algorithms\GDVTSF'},
    {'algorithms\MOEA_IB\WOF','algorithms\MOEA_IB\ReMO','algorithms\MOEA_IB'}
};
testSet = {'CF1','CF2','CF3','CF4','CF5','CF6','CF7','CF8','CF9','CF10','MW1','MW2','MW3','MW4','MW5','MW6','MW7','MW8','MW9','MW10','MW11','MW12','MW13','MW14'};

function setupPaths()
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;
end

function noopOutput(a,b)
end

function Res = runSota(cls, offProb, N, G, maxFE, seed)
    rng(seed);
    offProb.N = N; offProb.maxFE = maxFE; offProb.FE = 0;
    alg = feval(cls, 'save', -1, 'outputFcn', @noopOutput);
    alg.main(alg, offProb);
    PopSOL = alg.result{end,2};
    Res.F = PopSOL.objs; Res.nFE = offProb.FE;
end

for b = 1:numel(bClass)
    cls = bClass{b}; dname = bDir{b};
    setupPaths();
    for e = 1:numel(bEP{b}), addpath(bEP{b}{e}); end
    outDir = ['results\cf_sota\' dname];
    if ~isdir(outDir), mkdir(outDir); end
    for p = 1:numel(testSet)
        pn = testSet{p};
        prob = OfficialProblem(pn, 3, 10);
        offProb = prob.officialObj;
        PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
        igd = nan(1,30); hv = nan(1,30);
        for s = 1:30
            fn = sprintf('%s/%s_%s_s%d.mat', outDir, dname, pn, s);
            if isfile(fn)
                L = load(fn); igd(s) = L.out.IGD; hv(s) = L.out.HV;
                continue;
            end
            try
                Res = runSota(cls, offProb, N, G, maxFE, s);
                [fn2, ~] = NDSort(Res.F, offProb.FE >= 0 && ~isempty(Res.F), 1);
                nd = 1:size(Res.F,1);
                out.IGD = IGD(Res.F, PF); out.HV = HV(Res.F, ref);
                out.nFE = Res.nFE; out.PPS = size(Res.F,1);
                save(fn, 'out', '-v7.3');
                igd(s) = out.IGD; hv(s) = out.HV;
            catch e
                fprintf('FAIL %s %s s%d: %s\n', dname, pn, s, e.message);
            end
        end
        fprintf('%s %s IGD med=%.4g HV med=%.4g\n', dname, pn, median(igd), median(hv));
    end
end
fprintf('DONE cf_sota\n');
