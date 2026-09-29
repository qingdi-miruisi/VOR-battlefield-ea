function gen_paper_tables()
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('experiments');

    % ---------- A) LSMOP: 14-alg mat -> 12-alg subset tables ----------
    L14 = load('results\friedman_13_lsmop.mat');
    A14 = L14.algs; P = L14.probs;
    keep12 = ~ismember(A14, {'HCEA','HCEAV4'});
    A12 = A14(keep12); igd12 = L14.igdTbl(keep12,:); hv12 = L14.hvTbl(keep12,:);
    n12 = numel(A12);
    igdR = friRank(igd12, n12); hvR = friRank(-hv12, n12); combR = (igdR+hvR)/2;

    % Build header row for IGD/HV tables (plain string, no sprintf)
    hdr = '\textbf{Algorithm}';
    for p=1:numel(P), hdr = [hdr ' & \textbf{' P{p} '}']; end

    % ---- Table 1: LSMOP 12-alg Friedman ranks ----
    cap = 'Friedman mean ranks over the nine LSMOP instances (M=3, D=300), 12 algorithms = EDD (ours) + eight traditional baselines (NSGA-II/III, MOEAD, SPEA2, SMS-EMOA, RVEA, AGE-MOEA, MOGWO) + three 2026 state-of-the-art methods (FDSEA, GDVTSF, MOEA-IB); 30 independent seeds per cell. Lower is better; bold = best. The 2026 SOTA methods are the strongest on this family; EDD ranks 5th (IGD) / 4th (combined), ahead of all eight traditional baselines but behind the SOTA trio.';
    fid = fopen('paper\tables_lsmop_ranks.tex','w');
    fW(fid, '% tables_lsmop_ranks.tex - EDD+8trad+3SOTA (12 alg), LSMOP1-9\n');
    fW(fid, '\begin{table*}[t]\n\centering\n');
    fW(fid, ['\caption{' cap '}\n']);
    fW(fid, '\label{tab:lsmop_ranks}\n');
    fW(fid, '\resizebox{0.98\textwidth}{!}{%\n\footnotesize\n\setlength{\tabcolsep}{5pt}\n');
    fW(fid, '\begin{tabular}{lccc}\n\toprule\n');
    fW(fid, '\textbf{Algorithm} & \textbf{IGD rank} & \textbf{HV rank} & \textbf{Combined rank} \\\n\midrule\n');
    for k = 1:n12
        tag = A12{k};
        if strcmp(tag,'EDD'), tag = '\textbf{EDD (ours)}'; end
        line = [tag ' & ' fmtv(igdR(k)) ' & ' fmtv(hvR(k)) ' & ' fmtv(combR(k)) ' \\\n'];
        fW(fid, line);
    end
    fW(fid, '\bottomrule\n\end{tabular}\n}\n\end{table*}\n');
    fclose(fid);

    % ---- Table 2: LSMOP 12-alg per-problem IGD medians ----
    cap2 = 'Per-problem median IGD (30 seeds, lower = better) for the 12-algorithm LSMOP comparison. Bold = per-column best. EDD is never the column best against the 2026 SOTA on LSMOP1--9; it leads the traditional-baseline block on every instance except where MOEAD is competitive.';
    fid = fopen('paper\tables_lsmop_igd.tex','w');
    fW(fid, '% tables_lsmop_igd.tex - per-problem IGD medians, 12 alg\n');
    fW(fid, '\begin{table*}[t]\n\centering\n');
    fW(fid, ['\caption{' cap2 '}\n']);
    fW(fid, '\label{tab:lsmop_igd}\n');
    fW(fid, '\resizebox{\textwidth}{!}{%\n\footnotesize\n\setlength{\tabcolsep}{4pt}\n');
    fW(fid, ['\begin{tabular}{l' repmat(' r',numel(P),1) '}\n\toprule\n']);
    fW(fid, [hdr ' \\\n\midrule\n']);
    for k=1:n12
        tag=A12{k}; if strcmp(tag,'EDD'), tag='\textbf{EDD}'; end
        row = tag;
        for p=1:numel(P)
            best = find(igd12(:,p)==min(igd12(:,p)),1,'first');
            vv = fmtv(igd12(k,p));
            if k==best, vv=['\textbf{' vv '}']; end
            row = [row ' & ' vv];
        end
        fW(fid, [row ' \\\n']);
    end
    fW(fid, '\midrule\n');
    for k=1:n12
        tag=A12{k}; if strcmp(tag,'EDD'), tag='\textbf{EDD}'; end
        row = tag;
        rk = zeros(1,numel(P));
        for p=1:numel(P), rk(p) = 1+sum(igd12(:,p)<igd12(k,p)); end
        for p=1:numel(P), row=[row ' & ' fmtv(rk(p))]; end
        fW(fid, [row ' (rank) \\\n']);
    end
    fW(fid, '\bottomrule\n\end{tabular}\n}\n\end{table*}\n');
    fclose(fid);

    % ---- Table 3: LSMOP 12-alg per-problem HV medians ----
    cap3 = 'Per-problem median hypervolume (30 seeds, larger = better; reference point = 1.1x max of the true front). Bold = per-column best. On LSMOP6 and LSMOP7 every algorithm attains HV=0 (total convergence collapse); the 2026 SOTA reach non-zero HV on more instances than EDD.';
    fid = fopen('paper\tables_lsmop_hv.tex','w');
    fW(fid, '% tables_lsmop_hv.tex - per-problem HV medians, 12 alg\n');
    fW(fid, '\begin{table*}[t]\n\centering\n');
    fW(fid, ['\caption{' cap3 '}\n']);
    fW(fid, '\label{tab:lsmop_hv}\n');
    fW(fid, '\resizebox{\textwidth}{!}{%\n\footnotesize\n\setlength{\tabcolsep}{4pt}\n');
    fW(fid, ['\begin{tabular}{l' repmat(' r',numel(P),1) '}\n\toprule\n']);
    fW(fid, [hdr ' \\\n\midrule\n']);
    for k=1:n12
        tag=A12{k}; if strcmp(tag,'EDD'), tag='\textbf{EDD}'; end
        row = tag;
        for p=1:numel(P)
            best = find(hv12(:,p)==max(hv12(:,p)),1,'first');
            vv = fmtv(hv12(k,p));
            if k==best, vv=['\textbf{' vv '}']; end
            row = [row ' & ' vv];
        end
        fW(fid, [row ' \\\n']);
    end
    fW(fid, '\bottomrule\n\end{tabular}\n}\n\end{table*}\n');
    fclose(fid);

    % ---- Table 4: CF/MW EDD_cf vs 11 alg ----
    C = load('results\friedman_cf_mw.mat');
    AC = C.algs; PC = C.probs; igdC = C.igdTbl; hvC = C.hvTbl;
    ppsTbl = ppsOf(AC, PC);
    fid = fopen('paper\tables_cfmw.tex','w');
    cap4 = 'EDD_cf (constrained variant) versus 11 baselines/SOTA on the official constrained CF/MW family (CF1--10, MW1--14; the 8 fully-complete problems enter the Friedman test). EDD_cf attains the last combined rank (12/12), an honest negative result. The mechanism is the non-dominated-set (PPS) collapse in the adjacent panel: EDD_cf retains only PPS approximately 1--24 candidate points whereas the field keeps approximately full populations, so its IGD/HV are inflated by sparsity rather than by worse convergence.';
    fW(fid, '% tables_cfmw.tex - EDD_cf vs 11 alg on CF/MW: Friedman + PPS collapse\n');
    fW(fid, '\begin{table*}[t]\n\centering\n');
    fW(fid, ['\caption{' cap4 '}\n']);
    fW(fid, '\label{tab:cfmw}\n');
    fW(fid, '\vspace{3pt}\n');
    fW(fid, '\begin{minipage}[t]{0.42\textwidth}\n\centering\n\footnotesize\n');
    fW(fid, '\textbf{(a) Friedman ranks (8 complete CF/MW problems)}\n\n');
    fW(fid, '\begin{tabular}{lcc}\n\toprule\n\textbf{Algorithm} & \textbf{IGD} & \textbf{Combined} \\\n\midrule\n');
    igdCR = friRank(igdC, numel(AC)); hvCR = friRank(-hvC, numel(AC)); combCR=(igdCR+hvCR)/2;
    [~, ocR] = sort(combCR);
    for k=1:numel(AC)
        tag=AC{ocR(k)}; if strcmp(tag,'EDD_cf'), tag='\textbf{EDD\_cf}'; end
        ig = 1+sum(igdCR<igdCR(ocR(k))); cb=1+sum(combCR<combCR(ocR(k)));
        fW(fid, [tag ' & ' num2str(ig) ' & ' num2str(cb) ' \\\n']);
    end
    fW(fid, '\bottomrule\n\end{tabular}\n\n');
    fW(fid, ['Chi-sq = ' sprintf('%.2f',C.chi) ', p = ' sprintf('%.1g',C.pval) '. EDD\_cf last on both IGD and combined.\n']);
    fW(fid, '\end{minipage}\hfill\n');
    fW(fid, '\begin{minipage}[t]{0.52\textwidth}\n\centering\n\footnotesize\n');
    fW(fid, '\textbf{(b) Mean final non-dominated-set size (PPS, over 30 seeds)}\n\n');
    fW(fid, '\begin{tabular}{lrrrr}\n\toprule\n\textbf{Algorithm} & \textbf{CF1} & \textbf{CF7} & \textbf{MW1} & \textbf{MW7} \\\n\midrule\n');
    cfi=1; cf7i=7; mw1i=11; mw7i=17;
    for k=1:numel(AC)
        tag=AC{k}; if strcmp(tag,'EDD_cf'), tag='\textbf{EDD\_cf}'; end
        a=fmtppsv(ppsTbl(k,cfi)); b=fmtppsv(ppsTbl(k,cf7i));
        c=fmtppsv(ppsTbl(k,mw1i)); d=fmtppsv(ppsTbl(k,mw7i));
        fW(fid, [tag ' & ' a ' & ' b ' & ' c ' & ' d ' \\\n']);
    end
    fW(fid, '\bottomrule\n\end{tabular}\n\n');
    fW(fid, 'EDD\_cf PPS collapses to approximately 1 on the MW family and at most 24 on CF, while the field keeps approximately 100; this is the epsilon-grid structural boundary at low D (10--15), reported as a finding.\n');
    fW(fid, '\end{minipage}\n\end{table*}\n');
    fclose(fid);

    % Console summary
    fprintf('\n=== 12-alg LSMOP (EDD+8trad+3SOTA) recomputed ranks ===\n');
    for k=1:n12, fprintf('  %-10s IGD=%.2f HV=%.2f Comb=%.2f\n', A12{k}, igdR(k), hvR(k), combR(k)); end
    fprintf('  EDD combined position = %d / %d\n', 1+sum(combR<combR(1)), n12);
end

% Write MATLAB char vector to file.  Use fprintf with '%s' when the string
% is safe (no backslashes), or fall back to fwrite with numeric bytes.
function fW(fid, s)
    c = char(s);
    c = strrep(c, '\n', newline);
    fwrite(fid, uint8(c));
end

function r = friRank(tbl, nA)
    nP = size(tbl,2); R = zeros(nA,nP);
    for p=1:nP
        v = tbl(:,p); [vs,od]=sort(v); rr=zeros(nA,1);
        i=1;
        while i<=nA
            j=i; while j<nA && vs(j)==vs(i), j=j+1; end
            rr(od(i:j)) = mean(i:j);
            i=j+1;
        end
        R(:,p)=rr;
    end
    r = mean(R,2);
end

function s = fmtv(x)
    s = sprintf('%.3f', x);
end

function s = fmtppsv(x)
    if isnan(x), s = '---'; else, s = sprintf('%.1f', x); end
end

function ppsTbl = ppsOf(algs, probs)
    base = 'results';
    ppsTbl = zeros(numel(algs), numel(probs));
    for a=1:numel(algs)
        an=algs{a};
        if strcmp(an,'EDD_cf')
            dd=[base '\cf_edd_cf'];
        elseif any(strcmp(an,{'NSGA2','NSGA3','MOEAD','SPEA2','SMSEMOA','RVEA','AGEMOEA','MOGWO'}))
            dd=[base '\cf_baselines\' an];
        elseif any(strcmp(an,{'FDSEA','GDVTSF'}))
            dd=[base '\cf_sota\' an];
        else
            dd=[base '\cf_sota\MOEA-IB'];
        end
        for p=1:numel(probs)
            pn=probs{p};
            f1=dir(fullfile(dd,[an '_' pn '_s*.mat']));
            f2=dir(fullfile(dd,[pn '_' an '_s*.mat']));
            f=[f1;f2];
            vals=zeros(1,0);
            for i=1:numel(f)
                L=load(fullfile(f(i).folder,f(i).name));
                if isfield(L,'out') && isfield(L.out,'PPS'), vals=[vals L.out.PPS]; end
            end
            if numel(vals)>0, ppsTbl(a,p)=mean(vals); else, ppsTbl(a,p)=NaN; end
        end
    end
end
