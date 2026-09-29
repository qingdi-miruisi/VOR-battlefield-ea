function out = bench_v4_full()
    % HCEAV4 vs HCEA 全 33 问题 × 3 种子小步验证（不覆盖 results/main）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('experiments'); addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('algorithms'); addpath('algorithms\utils');
    clear IGD HV;

    problems = { ...
        'ZDT1',0; 'ZDT2',0; 'ZDT3',0; 'ZDT4',0; 'ZDT5',0; 'ZDT6',0; ...
        'DTLZ1',0; 'DTLZ2',3; 'DTLZ3',3; 'DTLZ4',0; 'DTLZ5',0; 'DTLZ7',0; ...
        'WFG1',0; 'WFG2',0; 'WFG3',0; 'WFG4',0; 'WFG5',0; 'WFG6',0; ...
        'UF1',0; 'UF2',0; 'UF5',0; 'UF6',0; 'CMO1',0; 'CMO5',0; ...
        'MaF1',3; 'MaF2',3; 'MaF3',3; 'MaF4',3; 'MaF5',3; 'MaF11',3};
    nProbs = size(problems, 1);
    nSeeds = 3;
    out = struct('p', cell(nProbs,1), 'iHCEA', zeros(nProbs,1), 'iV4', zeros(nProbs,1), ...
                 'hHCEA', zeros(nProbs,1), 'hV4', zeros(nProbs,1));

    for p = 1:nProbs
        pname = problems{p,1}; pM = problems{p,2};
        if pM > 0
            prob = feval(pname, pM);
        else
            prob = feval(pname);
        end
        PF = prob.ParetoFront(500);
        ref = prob.setRefPoint(PF).refPoint;
        iH = []; iV = []; hH = []; hV = [];
        for s = 1:nSeeds
            alg1 = HCEA(100, 200, s); [P1, R1] = alg1.optimize(prob);
            alg2 = HCEAV4(100, 200, s); [P2, R2] = alg2.optimize(prob);
            iH(end+1) = IGD(R1.F,PF); iV(end+1) = IGD(R2.F,PF);
            hH(end+1) = HV(R1.F,ref);  hV(end+1) = HV(R2.F,ref);
        end
        out(p).p = pname;
        out(p).iHCEA = mean(iH); out(p).iV4 = mean(iV);
        out(p).hHCEA = mean(hH);  out(p).hV4 = mean(hV);
        iGDgap = out(p).iV4 - out(p).iHCEA;
        marker = '';
        if iGDgap < -0.001, marker = '  <<< V4 IGD better';
        elseif iGDgap > 0.001, marker = '  (V4 IGD worse)';
        end
        fprintf("%-8s HCEA IGD=%9.4f HV=%9.4f | V4 IGD=%9.4f HV=%9.4f%s\n", ...
            pname, out(p).iHCEA, out(p).hHCEA, out(p).iV4, out(p).hV4, marker);
    end

    % 统计胜负（排除 ~0 平局）
    iH = [out.iHCEA]; iV = [out.iV4];
    hH = [out.hHCEA]; hV = [out.hV4];
    fprintf("\n=== %d problems x %d seeds ===\n", nProbs, nSeeds);
    fprintf("IGD: V4 better %d, HCEA better %d, tie %d\n", ...
        sum(iV < iH - 1e-3), sum(iV > iH + 1e-3), sum(abs(iV-iH) <= 1e-3));
    fprintf("HV : V4 better %d, HCEA better %d, tie %d\n", ...
        sum(hV > hH + 1e-3), sum(hV < hH - 1e-3), sum(abs(hV-hH) <= 1e-3));
    save('results\bench_v4.mat', 'out', '-v7.3');
    fprintf("saved to results/bench_v4.mat\n");
end
