%% stat_30.m — 30-seed Friedman + Wilcoxon（VOR vs EDD）
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
resDir = 'results/vor2_bench';
algos = {'VOR','EDD','MOEAD','RVEA','NSGA2'};
probs = {'MaF14','CF1','ZDT1','LSMOP1','DTLZ2_300D','LSMOP6'};
nSeed = 30;
nA = numel(algos); nP = numel(probs);

% 载入 IGD 矩阵：igd{ai,pi} = nSeed x 1
igd = cell(nA,nP);
for ai=1:nA
  for pi=1:nP
    v = NaN(nSeed,1);
    for s=1:nSeed
      f = sprintf('%s/%s_%s_s%d.mat', resDir, algos{ai}, probs{pi}, s);
      if isfile(f)
        q = load(f);
        if isfield(q,'igd'), v(s) = q.igd; end
      end
    end
    igd{ai,pi} = v;
  end
end

%% ---- Friedman（180 块，块=题×种子；5 算法按 IGD 升序排名，1=最优，并列取平均秩）----
blockRank = NaN(nSeed*nP, nA);
for pi=1:nP
  for s=1:nSeed
    blk = (pi-1)*nSeed + s;
    row = zeros(1,nA); full = true;
    for ai=1:nA
      v = igd{ai,pi}(s);
      if isnan(v), full=false; break; end
      row(ai) = v;
    end
    if ~full, continue; end
    % 平均秩（并列）
    [~,r] = tiedrank(row);   % tiedrank 返回秩，1=最小
    blockRank(blk,:) = r;
  end
end
valid = all(~isnan(blockRank),2);
br = blockRank(valid,:);
N = sum(valid);
R = sum(br,1);                       % 各算法总秩
k = nA;
Q = 12/(N*k*(k+1)) * (sum(R.^2) - 0.25*N*k*(k+1)^2);
df = k-1;
pF = 1 - chi2cdf(Q, df);

fid = fopen('results/stat_results_30.txt','w');
fprintf(fid, '=== Friedman 秩检验（IGD，5 算法 × 6 题 × 30 种子，块=题×种子 共 %d，有效 %d）===\n', nSeed*nP, N);
fprintf(fid, '各算法总秩（期望=N*(k+1)/2=%g）:\n', N*(k+1)/2);
for ai=1:k
  fprintf(fid, '  %-8s Rtot=%9.2f\n', algos{ai}, R(ai));
end
fprintf(fid, 'Q=%.4f, df=%d, p=%.4g\n', Q, df, pF);
if pF<0.05, c1='p<0.05 → 算法间 IGD 差异显著'; else, c1='p>=0.05 → 不显著'; end
fprintf(fid, '结论: %s\n\n', c1);

%% ---- Wilcoxon 符号秩（VOR vs EDD，逐种子 IGD 配对，n=30）----
fprintf(fid, '=== Wilcoxon 符号检验：VOR vs EDD（IGD，逐种子配对，n=30）===\n');
for pi=1:nP
  d = igd{1,pi} - igd{2,pi};       % VOR - EDD
  d = d(~isnan(d));
  nz = d(d~=0);
  m = numel(nz);
  if m==0
    fprintf(fid, '%-12s 无有效差异（全部并列）\n', probs{pi});
    continue;
  end
  r = tiedrank(abs(nz));
  Wp = sum(nz(nz>0) .* r(nz>0));    % VOR 较差（IGD 更大）的秩和
  Wn = sum(nz(nz<0) .* r(nz<0));
  mu = m*(m+1)/4;
  sig = sqrt(m*(m+1)*(2*m+1)/24);
  Z = (Wp - mu)/sig;
  p = 2*normcdf(-abs(Z));
  if p<0.05, s2='VOR 显著优于 EDD (p<0.05)'; else, s2='差异不显著 (p>=0.05)'; end
  fprintf(fid, '%-12s nEff=%2d W+=%7.0f W-=%7.0f Z=%+.3f p=%.4f → %s\n', ...
    probs{pi}, m, Wp, Wn, Z, p, s2);
end
fclose(fid);
disp('stat_30 COMPLETE');

function [sorted, rank] = tiedrank(x)
% 返回按 x 升序的排序值与平均秩（1=最小值）
    [sx,ix] = sort(x);
    n = numel(x);
    rank = (1+n)/2;            % 先给全并列占位
    j = 1;
    while j <= n
      jj = j;
      while jj<n && sx(jj+1)==sx(jj), jj = jj+1; end
      if jj>j
        avg = (j+jj)/2;
        rank(ix(j:jj)) = avg;
      else
        rank(ix(j)) = j;
      end
      j = jj+1;
    end
    sorted = sx;
end
