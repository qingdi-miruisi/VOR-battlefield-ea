function [fQ, fP, wPvals] = stat_tests()
% stat_tests — 统计检验脚本（应用期刊硬要求）
%   1) Friedman 秩检验：5 算法 × 6 题，每个 (题,种子) 为一个"块"（共 60 块），
%      块内按 IGD 对 5 算法排名。
%   2) Wilcoxon 符号秩检验：VOR vs EDD（逐种子 IGD 差，正态近似 + 连续性校正）
%   输出：results/stat_results.txt
  cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
  probNames = {'MaF14','CF1','ZDT1','LSMOP1','DTLZ2_300D','LSMOP6'};
  algoNames = {'VOR','EDD','MOEAD','RVEA','NSGA2'};
  nP = numel(probNames); nA = numel(algoNames); nS = 10;
  M = zeros(nA, nP, nS);  % 算法 × 题 × 种子 IGD
  for ai = 1:nA
    for pi = 1:nP
      for s = 1:nS
        f = sprintf('results/vor2_bench/%s_%s_s%d.mat', algoNames{ai}, probNames{pi}, s);
        if isfile(f), v = load(f); M(ai,pi,s) = v.igd; end
      end
    end
  end

  fid = fopen('results/stat_results.txt','w');

  %% ---- Friedman 秩检验 ----
  % 块 = (题, 种子)，共 nP*nS 块；每块内对 nA 算法按 IGD 排名（小 IGD 小秩）
  R = zeros(nA, nP, nS);
  for pi = 1:nP
    for s = 1:nS
      vals = squeeze(M(:,pi,s));
      [~, ord] = sort(vals);
      R(1:nA, pi, s) = ord(:);     % IGD 升序 → 第 1 名秩 1
    end
  end
  b = nP*nS;                      % 块数 = 60
  k = nA;                          % 处理数 = 5
  % 正确的总秩：对每个算法，把 60 个块（题×种子）内的秩全加起来
  Rtot2 = zeros(nA,1);
  for ai = 1:nA
    Rtot2(ai) = sum(R(ai,:,:),'all');   % 标量：该算法在 60 个块上的总秩
  end
  % Friedman Q 标准公式：Q = [12/(N·k·(k+1))]·[Σ R_r² − (1/4)·k·(k+1)²·N]
  %   N=块数(b), k=处理数, R_r=第 r 个处理在 N 块上的秩和
  fQ = (12/(b*k*(k+1))) * (sum(Rtot2.^2) - 0.25*k*(k+1)^2*b);
  fP = 1 - chi2cdf(fQ, k-1);
  fprintf(fid, '=== Friedman 秩检验（IGD，5 算法 × 6 题 × 10 种子，块=题×种子 共 60）===\n');
  fprintf(fid, '总秩（每个算法 60 块秩之和，期望=%.0f）:\n', b*(k+1)/2);
  fprintf(fid, 'sumR2=%.0f, b*k*(k+1)=%d, 公式项=%.0f\n', sum(Rtot2.^2), b*k*(k+1), 0.25*k^2*(k+1)^2*b);
  for ai = 1:nA
    fprintf(fid, '  %-8s Rtot=%.2f  (rank1=最优)\n', algoNames{ai}, Rtot2(ai));
  end
  fprintf(fid, 'Q=%.4f, df=%d, p=%.4g\n', fQ, k-1, fP);
  if fP < 0.05
    fprintf(fid, '结论: p<0.05 → 算法间 IGD 差异显著\n');
  else
    fprintf(fid, '结论: p>=0.05 → 算法间 IGD 差异不显著\n');
  end

  %% ---- Wilcoxon 符号秩检验：VOR vs EDD（逐种子 IGD 差，正态近似）----
  % d_s = IGD_vor_s - IGD_edd_s；VOR 更优 → d_s < 0
  % 正号秩和 W+（d_s>0，VOR 更差）；负号秩和 W-（d_s<0，VOR 更优）
  % Z = (W+ - mu)/sigma，mu=n(n+1)/4, sigma=sqrt(n(n+1)(2n+1)/24)
  % |Z| 大 → VOR 与 EDD 差异显著；Z 强负 → VOR 显著更优
  fprintf(fid, '\n=== Wilcoxon 符号检验：VOR vs EDD（IGD，逐种子配对，n=10）===\n');
  wPvals = zeros(nP,1);
  for pi = 1:nP
    d = squeeze(M(1,pi,:) - M(2,pi,:));   % VOR - EDD
    d = d(isfinite(d));
    n = numel(d);
    if n < 2
      fprintf(fid, '%s: 数据不足\n', probNames{pi}); wPvals(pi)=NaN; continue;
    end
    % 去掉 0 差值（不计入 n）
    dNZ = d(d~=0);
    nEff = numel(dNZ);
    if nEff == 0
      fprintf(fid, '%s: 全种子 IGD 相同（无差值）\n', probNames{pi}); wPvals(pi)=1; continue;
    end
    ad = abs(dNZ);
    [ra, ord] = sort(ad);
    % 处理并列：取平均秩
    ranks = zeros(size(ra));
    i = 1;
    while i <= numel(ra)
      j = i;
      while j < numel(ra) && ra(j+1)==ra(i), j = j+1; end
      ranks(i:j) = (i+j)/2;
      i = j+1;
    end
    % 按符号还原秩（dNZ 与 ra 顺序对应）
    rSig = ranks(ord);          % ranks 按 dNZ 原序
    Wplus  = sum(rSig(dNZ>0));
    Wminus = sum(rSig(dNZ<0));
    mu   = nEff*(nEff+1)/4;
    sigma = sqrt(nEff*(nEff+1)*(2*nEff+1)/24);
    Z    = (Wplus - mu)/sigma;
    p    = 2*(1-normcdf(abs(Z)));
    wPvals(pi) = p;
    if p < 0.05
      if Z < 0, verdict = 'VOR 显著优于 EDD (p<0.05)';
      else,      verdict = 'EDD 显著优于 VOR (p<0.05)'; end
    else
      verdict = '差异不显著 (p>=0.05)';
    end
    fprintf(fid, '%-12s nEff=%d W+=%d W-=%d Z=%.3f p=%.4g → %s\n', ...
        probNames{pi}, nEff, Wplus, Wminus, Z, p, verdict);
  end
  fclose(fid);
end
