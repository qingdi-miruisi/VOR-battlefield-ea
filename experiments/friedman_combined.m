function out = friedman_combined()
    % 合并 M=2 33 问题 + M>=3 23 核心问题 = 56 问题，10 算法 Friedman + Wilcoxon
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO'); addpath('problems_official\UF');
    clear classes; clear IGD HV;
    algs = {'NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD','HCEA','HCEAV4'};
    commonM2 = {'CMO1','CMO5','DTLZ1','DTLZ2','DTLZ3','DTLZ4','DTLZ5','DTLZ7','MaF1','MaF11','MaF2','MaF3','MaF4','MaF5','UF1','UF2','UF5','UF6','WFG1','WFG2','WFG3','WFG4','WFG5','WFG6','WFG7','WFG8','WFG9','ZDT1','ZDT2','ZDT3','ZDT4','ZDT5','ZDT6'};
    m3core = {'MaF1','MaF2','MaF3','MaF4','MaF5','MaF7','MaF8','MaF9','MaF10','MaF11','MaF12','MaF13','MaF14','MaF15','LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9'};
    % 56 问题 = M2 33 + M3 23（注意 MaF1/2/3/4/5/11 在 M2 已用 M=2 版本，M3 用 M=3 版本，区分标注）
    allProbs = [commonM2, m3core];
    nA = numel(algs); nP = numel(allProbs);
    igdMed = NaN(nA, nP); hvMed = NaN(nA, nP);
    for a = 1:nA
        an = algs{a};
        for p = 1:nP
            pn = allProbs{p};
            % 8 基线 M>=3 数据在 main_m3/（补齐目录），HCEA/HCEAV4 在 merged_v4/
            if a <= 8 && p > 33
                f = dir(fullfile('results\main_m3', [an '_' pn '_s*.mat']));
                dn2 = 'results\main_m3';
                if numel(f) == 0
                    f = dir(fullfile('results\main', [an '_' pn '_s*.mat'])); dn2 = 'results\main';
                end
            else
                if a == 10, dn2 = 'results\merged_v4'; else, dn2 = 'results\main'; end
                f = dir(fullfile(dn2, [an '_' pn '_s*.mat']));
            end
            igdAll = []; hvAll = [];
            for i = 1:numel(f)
                try
                    d = load(fullfile(dn2, f(i).name), 'out');
                    ig = d.out.IGD; hv = d.out.HV;
                    if numel(ig)>1, ig = mean(ig(:)); end
                    if numel(hv)>1, hv = mean(hv(:)); end
                    if isfinite(ig), igdAll(end+1) = ig; end
                    if isfinite(hv), hvAll(end+1) = hv; end
                catch
                end
            end
            if numel(igdAll)>0, igdMed(a,p) = median(igdAll); end
            if numel(hvAll)>0, hvMed(a,p) = median(hvAll); end
        end
    end
    nMiss = sum(~isfinite(igdMed(:)));
    fprintf('数据矩阵: %d 算法 x %d 问题, IGD 缺失 %d\n', nA, nP, nMiss);
    % 统计秩（并列取平均）
    rankIGD = zeros(nA, nP); rankHV = zeros(nA, nP);
    for p = 1:nP
        [sg, og] = sort(igdMed(:,p)); r = zeros(nA,1); for i=1:nA, same=find(sg==sg(i)); ar=mean(same); r(og(same))=ar; end; rankIGD(:,p)=r;
        [sh, oh] = sort(-hvMed(:,p)); r = zeros(nA,1); for i=1:nA, same=find(sh==sh(i)); ar=mean(same); r(oh(same))=ar; end; rankHV(:,p)=r;
    end
    avgRankIGD = mean(rankIGD,2); avgRankHV = mean(rankHV,2);
    [~, ordIGD] = sort(avgRankIGD,'ascend'); [~, ordHV] = sort(avgRankHV,'ascend');
    fprintf('\n===== 合并 Friedman（56 问题，10 算法）=====\n--- IGD 排名 ---\n');
    for r=1:nA, a=ordIGD(r); fprintf('  %2d. %-8s 平均秩=%.3f\n', r, algs{a}, avgRankIGD(a)); end
    fprintf('--- HV 排名 ---\n');
    for r=1:nA, a=ordHV(r); fprintf('  %2d. %-8s 平均秩=%.3f\n', r, algs{a}, avgRankHV(a)); end
    chi2I = (12*nP/(nA*(nA+1)))*sum((avgRankIGD-(nA+1)/2).^2);
    chi2H = (12*nP/(nA*(nA+1)))*sum((avgRankHV-(nA+1)/2).^2);
    pIGD = 1-chi2cdf(chi2I,nA-1); pHV = 1-chi2cdf(chi2H,nA-1);
    fprintf('\nFriedman chi2: IGD=%.2f p=%.4f | HV=%.2f p=%.4f\n', chi2I, pIGD, chi2H, pHV);
    % 问题级 Wilcoxon：HCEAV4 vs HCEA + 8 基线
    iV4 = 10; iH = 9;
    dIGD = igdMed(iV4,:) - igdMed(iH,:); dHV = hvMed(iV4,:) - hvMed(iH,:);
    pV4H_IGD = wsrPval(dIGD); pV4H_HV = wsrPval(dHV);
    fprintf('\nHCEAV4 vs HCEA: IGD V4优 %d/%d p=%.4f | HV V4优 %d/%d p=%.4f\n', sum(dIGD<0),nP,pV4H_IGD, sum(dHV>0),nP,pV4H_HV);
    fprintf('HCEAV4 vs 8 基线（IGD）:\n');
    for a=1:8, d = igdMed(10,:)-igdMed(a,:); p = wsrPval(d); fprintf('  %-8s V4优 %d/%d p=%.4f\n', algs{a}, sum(d<0), nP, p); end
    out = struct('algs',algs,'allProbs',allProbs,'igdMed',igdMed,'hvMed',hvMed,'avgRankIGD',avgRankIGD,'avgRankHV',avgRankHV,'ordIGD',ordIGD,'ordHV',ordHV,'chi2I',chi2I,'chi2H',chi2H,'pIGD',pIGD,'pHV',pHV,'pV4H_IGD',pV4H_IGD,'pV4H_HV',pV4H_HV);
    save('results\friedman_combined.mat','out','-v7.3');
    fprintf('\n结果已存 results/friedman_combined.mat\n');
end
function p = wsrPval(d)
    d = d(isfinite(d)); d = d(d ~= 0); n = numel(d);
    if n==0, p=1; return; end
    ad = abs(d); [sa,ia] = sort(ad); ranks = (1:n)'; r = zeros(n,1);
    i=1; while i<=n, j=i; while j<n && sa(j+1)==sa(i), j=j+1; end; ar = mean(ranks(i:j)); r(i:j)=ar; i=j+1; end
    Wplus = sum(r(d>0)); Wminus = sum(r(d<0)); W = min(Wplus,Wminus);
    mu = n*(n+1)/4; sigma = sqrt(n*(n+1)*(2*n+1)/24); z = (W-mu+0.5)/sigma; p = 2*normcdf(-abs(z));
end