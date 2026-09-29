function dump_lsmop13()
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    S = load('results\friedman_13_lsmop.mat');
    A=S.algs; P=S.probs; iR=S.igdRank; hR=S.hvRank; cR=S.combRank; V=S.validCols;
    fprintf('validCols: '); for i=1:numel(P), if V(i), fprintf('%s ', P{i}); end; end; fprintf('\n');
    [~,io]=sort(iR); fprintf('\n=== IGD Friedman ===\n');
    for k=1:numel(A), fprintf('  %d. %-10s %.3f\n', k, A{io(k)}, iR(io(k))); end
    [~,ho]=sort(hR); fprintf('\n=== HV Friedman ===\n');
    for k=1:numel(A), fprintf('  %d. %-10s %.3f\n', k, A{ho(k)}, hR(ho(k))); end
    [~,co]=sort(cR); fprintf('\n=== Combined ===\n');
    for k=1:numel(A), fprintf('  %d. %-10s %.3f\n', k, A{co(k)}, cR(co(k))); end
    fprintf('\nchi=%.3f pval=%.4g\n', S.chi, S.pval);
    fprintf('\nEDD: IGD=%.3f(%.0f) HV=%.3f(%.0f) Comb=%.3f(%.0f)\n', ...
        iR(1), rankpos(iR,iR(1)), hR(1), rankpos(hR,hR(1)), cR(1), rankpos(cR,cR(1)));
    fprintf('\n=== EDD per-problem IGD median (9 LSMOP) ===\n');
    for p=1:numel(P), fprintf('  %-8s IGD=%.4g HV=%.4g\n', P{p}, S.igdTbl(1,p), S.hvTbl(1,p)); end
    % EDD vs 3 SOTA per-problem IGD
    iFD=find(strcmp(A,'FDSEA')); iGD=find(strcmp(A,'GDVTSF')); iMOEA=find(strcmp(A,'MOEA-IB'));
    fprintf('\n=== EDD vs 3 SOTA per-problem IGD (smaller=better; mark SOTA wins) ===\n');
    sotaWins=0;
    for p=1:numel(P)
        e=S.igdTbl(1,p); f=S.igdTbl(iFD,p); g=S.igdTbl(iGD,p); m=S.igdTbl(iMOEA,p);
        win = (f<e)+(g<e)+(m<e); sotaWins = sotaWins + win;
        fprintf('  %-8s EDD=%.4g | FDSEA=%.4g GDVTSF=%.4g MOEAIB=%.4g  SOTA beats=%d/3\n', ...
            P{p}, e, f, g, m, win);
    end
    fprintf('  SOTA beats EDD per-problem total: %d / %d problem-seats\n', sotaWins, numel(P)*3);
    % Wilcoxon pAll (EDD vs each of 13, IGD)
    if isfield(S,'pAll')
        fprintf('\n=== EDD vs 13 opponents problem-level Wilcoxon (IGD, pAll) ===\n');
        for k=1:numel(S.pAll)
            fprintf('  EDD vs %-10s p=%.4g\n', A{S.vsIdx(k)}, S.pAll(k));
        end
    end
    % PPS sample EDD vs SOTA on LSMOP6 / LSMOP1
    fprintf('\n=== PPS sample (mean over seeds) ===\n');
    ppsRow = {'EDD','results\largescale_final\EDD','EDD'};
    ppsRow = [ppsRow; {'FDSEA','results\largescale_extended\FDSEA','FDSEA'}; ...
              {'GDVTSF','results\largescale_extended\GDVTSF','GDVTSF'}; ...
              {'MOEA-IB','results\largescale_extended\MOEA-IB','MOEA-IB'}; ...
              {'NSGA2','results\largescale_final\NSGA2','NSGA2'}; ...
              {'MOEAD','results\largescale_final\MOEAD','MOEAD'}];
    for pr = [1 6]
        pn = P{pr};
        fprintf('  %s PPS means:\n', pn);
        for r = 1:size(ppsRow,1)
            dn = ppsRow{r,3}; dd = ppsRow{r,2};
            f1 = dir(fullfile(dd, [dn '_' pn '_s*.mat']));
            f2 = dir(fullfile(dd, [pn '_' dn '_s*.mat']));
            f = [f1; f2];
            if ~isempty(f)
                vals=zeros(1,0);
                for i=1:numel(f)
                    L=load(fullfile(f(i).folder,f(i).name));
                    if isfield(L,'out') && isfield(L.out,'PPS'), vals=[vals L.out.PPS]; end
                end
                fprintf('    %-8s PPS mean=%.1f  (n=%d)\n', dn, mean(vals), numel(vals));
            end
        end
    end
end
function pos = rankpos(v, x)
    pos = sum(v < x) + 1;
end
