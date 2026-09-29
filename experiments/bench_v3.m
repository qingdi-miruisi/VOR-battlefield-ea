function out = bench_v3()
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('experiments'); addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('algorithms'); addpath('algorithms\utils');
    clear IGD HV;
    nRuns = 15;
    out = struct('s', zeros(nRuns,1), 'p', cell(nRuns,1), ...
                 'i1', zeros(nRuns,1), 'h1', zeros(nRuns,1), ...
                 'i2', zeros(nRuns,1), 'h2', zeros(nRuns,1));
    pnames = {'DTLZ2','DTLZ3','DTLZ5','UF2','UF1'};
    pMvals = [3, 3, 3, 0, 0];
    n = 0;
    for s = 1:3
        for pidx = 1:5
            if pMvals(pidx) > 0
                prob = feval(pnames{pidx}, pMvals(pidx));
            else
                prob = feval(pnames{pidx});
            end
            PF = prob.ParetoFront(500);
            ref = prob.setRefPoint(PF).refPoint;
            alg1 = HCEA(100, 200, s);
            [Pop1, R1] = alg1.optimize(prob);
            i1 = IGD(R1.F, PF); h1 = HV(R1.F, ref);
            alg2 = HCEAV3(100, 200, s);
            [Pop2, R2] = alg2.optimize(prob);
            i2 = IGD(R2.F, PF); h2 = HV(R2.F, ref);
            n = n + 1;
            out(n).s = s; out(n).p = pnames{pidx};
            out(n).i1 = i1; out(n).h1 = h1;
            out(n).i2 = i2; out(n).h2 = h2;
            fprintf("s%d %s  HCEA IGD=%.4f HV=%.4f | V3 IGD=%.4f HV=%.4f\n", ...
                s, pnames{pidx}, i1, h1, i2, h2);
        end
    end
end
