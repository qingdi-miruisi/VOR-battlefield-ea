%% aggregate_vor2_30.m — 30-seed 聚合（IGD/HV/PPS 均值±std）+ Friedman + Wilcoxon
% 读 results/vor2_bench/ 全部 {algo}_{prob}_s{1:30}.mat，按 30 seeds 统计。
% 输出：results/vor2_bench/agg30_stats.txt（每算法×题 均值±std）
%       results/stat_results_30.txt（Friedman + Wilcoxon，与 10-seed 版同口径）
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');

resDir = 'results/vor2_bench';
algos = {'VOR','EDD','MOEAD','RVEA','NSGA2'};
probs = {'MaF14','CF1','ZDT1','LSMOP1','DTLZ2_300D','LSMOP6'};
nSeed = 30;

%% ---- 1) 逐 run 读 IGD/HV/PPS ----
% 数据布局：data{ai,pi} = [nSeed,3] (IGD,HV,PPS)，缺失为 NaN
data = cell(numel(algos),numel(probs));
for ai = 1:numel(algos)
    for pi = 1:numel(probs)
        M = NaN(nSeed,3);
        for s = 1:nSeed
            f = sprintf('%s/%s_%s_s%d.mat', resDir, algos{ai}, probs{pi}, s);
            if isfile(f)
                q = load(f);
                if isfield(q,'igd'), M(s,1) = q.igd; end
                if isfield(q,'hv'),  M(s,2) = q.hv;  end
                if isfield(q,'pps'), M(s,3) = q.pps;
                elseif isfield(q,'R') && isfield(q.R,'F'), M(s,3) = size(q.R.F,1);
                end
            end
        end
        data{ai,pi} = M;
    end
end

%% ---- 2) 聚合表（30-seed 均值±std）----
fid = fopen('results/vor2_bench/agg30_stats.txt','w');
fprintf(fid, '=== 30-seed 聚合（IGD/HV/PPS 均值±std）===\n');
fprintf(fid, '%-8s %-14s %16s %14s %8s\n','Algo','Problem','IGD(mean±std)','HV(mean±std)','PPS(mean)');
for ai = 1:numel(algos)
    for pi = 1:numel(probs)
        M = data{ai,pi};
        igdV = M(:,1); hvV = M(:,2); ppsV = M(:,3);
        igdV = igdV(~isnan(igdV)); hvV = hvV(~isnan(hvV)); ppsV = ppsV(~isnan(ppsV));
        if ~isempty(igdV)
            fprintf(fid, '%-8s %-14s %6.4f±%5.4f %6.4f±%5.4f %4.0f  (n=%d)\n', ...
                algos{ai}, probs{pi}, mean(igdV), std(igdV), mean(hvV), std(hvV), mean(ppsV), numel(igdV));
        else
            fprintf(fid, '%-8s %-14s  NO DATA\n', algos{ai}, probs{pi});
        end
    end
end
fclose(fid);

%% ---- 3) Friedman（块=题×种子=180，5 算法，按 IGD 排名）----
% 每块（题,seed）给 5 算法按 IGD 升序排名（1=最优）；同值取平均秩
nBlock = numel(probs)*nSeed;
rankSum = zeros(1,numel(algos));
blockRank = zeros(nBlock, numel(algos));
% 预排：对每个 (pi,s) 取 5 算法 IGD 排序
for pi = 1:numel(probs)
    for s = 1:nSeed
        blk = (pi-1)*nSeed + s;
        igdArr = zeros(1,numel(algos));
        ok = true;
        for ai = 1:numel(algos)
            v = data{ai,pi}(s,1);
            if isnan(v)
                ok = false;
                break;
            end
            igdArr(ai) = v;
        end
        if ~ok
            continue;  % 该块有缺失算法则跳过（Friedman 需完整块）
        end
        [sg,sgi] = sort(igdArr,'ascend');
        % 处理并列：平均秩
        r = sgi;
        eq = sg(2)-sg(1);
        for a = 1:numel(sg)-1
            if sg(a+1)==sg(a)
                idx = find(igdArr==sg(a));
                meanr = mean(a:numel(idx));
                r(idx) = meanr;  % 近似：并列取该组平均位置
            end
        end
        blockRank(blk,:) = r;
    end
end
validBlocks = sum(blockRank(:,1)~=0);
rankSum = sum(blockRank,1);
k = numel(algos);
N = validBlocks;
% Friedman Q（基于有效块上的列和）
Q = 12/(N*k*(k+1)) * (sum(rankSum.^2) - N*k*(k+1)^2/4);
df = k-1;
pFried = 1 - chi2cdf(Q, df);

%% ---- 4) Wilcoxon 符号秩（VOR vs EDD，逐种子 IGD 配对）----
wilc = struct('prob',probs,'nEff',zeros(1,numel(probs)),'Wp',zeros(1,numel(probs)),'Z',zeros(1,numel(probs)),'p',zeros(1,numel(probs)));
for pi = 1:numel(probs)
    d = data{1,pi}(:,1) - data{2,pi}(:,1);   % VOR - EDD
    d = d(~isnan(d));
    nz = d(d~=0);
    nEff = numel(nz);
    % 符号秩
    r = ranks(abs(nz));
    Wp = sum(nz(nz>0).*r(nz>0));   % VOR 较差侧（IGD 更大）
    Wn = sum(nz(nz<0).*r(nz<0));
    m = nEff;
    mu = m*(m+1)/4;
    sig2 = m*(m+1)*(2*m+1)/24;
    Z = (Wp - mu)/sqrt(sig2);
    p = 2*normcdf(-abs(Z));
    wilc(pi).prob = probs{pi}; wilc(pi).nEff = nEff; wilc(pi).Wp = Wp; wilc(pi).Z = Z; wilc(pi).p = p;
end

fid = fopen('results/stat_results_30.txt','w');
fprintf(fid, '=== Friedman 秩检验（IGD，5 算法 × %d 题 × 30 种子，块=题×种子 共 %d）===\n', numel(probs), N);
fprintf(fid, '有效块: %d / %d\n', N, numel(probs)*nSeed);
fprintf(fid, '总秩（每个算法块秩之和，期望=N*(k+1)/2=%d）:\n', round(N*(k+1)/2));
for ai = 1:numel(algos)
    fprintf(fid, '  %-8s Rtot=%8.2f\n', algos{ai}, rankSum(ai));
end
fprintf(fid, 'Q=%.4f, df=%d, p=%.4g\n', Q, df, pFried);
if pFried<0.05
  conclF = 'p<0.05 → 算法间 IGD 差异显著';
else
  conclF = 'p>=0.05 → 不显著';
end
fprintf(fid, '结论: %s\n', conclF);

fprintf(fid, '\n=== Wilcoxon 符号检验：VOR vs EDD（IGD，逐种子配对，n=30）===\n');
for pi = 1:numel(probs)
    if wilc(pi).p<0.05
      sig = 'VOR 显著优于 EDD (p<0.05)';
    else
      sig = '差异不显著 (p>=0.05)';
    end
    fprintf(fid, '%-12s nEff=%2d W+=%d Z=%.3f p=%.4f → %s\n', ...
        wilc(pi).prob, wilc(pi).nEff, round(wilc(pi).Wp), wilc(pi).Z, wilc(pi).p, sig);
end
fclose(fid);
disp('aggregate_vor2_30 COMPLETE');

function r = ranks(x)
% 返回并列平均秩（升序）
    [sx,ix] = sort(x);
    n = numel(x);
    rr = 1:n;
    cnt = 1;
    while cnt <= n
        if cnt < n && sx(cnt+1)==sx(cnt)
            e = cnt;
            while e<n && sx(e+1)==sx(cnt), e=e+1; end
            meanr = mean(rr(cnt:e));
            rr(cnt:e) = meanr;
            cnt = e+1;
        else
            cnt = cnt+1;
        end
    end
    r = zeros(1,n); r(ix) = rr; r = r(:).';
end
