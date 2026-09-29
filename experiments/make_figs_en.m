function make_figs_en()
% make_figs_en — 生成英文稿 VOR 图（vector PDF，期刊要求 600DPI 矢量）
%   fig1_igd_conv.pdf   6 题 IGD 收敛曲线（5 算法叠画，30 seeds，6 子图）
%   fig2_pf_scat.pdf    ZDT1(2D) + LSMOP1(3D) 前沿散点（VOR vs EDD vs PF）
%   fig3_friedman.pdf   Friedman 平均秩柱状图（180 blocks，30 seeds）
  cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
  outdir = 'results\figs\out';
  if ~isdir(outdir), mkdir(outdir); end
  probNames = {'MaF14','CF1','ZDT1','LSMOP1','DTLZ2_300D','LSMOP6'};
  algoNames = {'VOR','EDD','MOEAD','RVEA','NSGA2'};
  nP = numel(probNames); nA = numel(algoNames); nS = 30;
  colors = [0 0 1; 0.9 0.2 0; 0 0.6 0; 0.5 0.5 0.5; 0.8 0.5 0];

  %% 1) IGD 收敛曲线：6 子图（每题一张，5 算法 30 seeds IGD 轨迹叠画）
  fig = figure('Visible','off','Position',[100 100 1100 600]);
  for pi = 1:nP
    ax = subplot(2,3,pi); hold on;
    for ai = 1:nA
      for s = 1:nS
        f = sprintf('results/vor2_bench/%s_%s_s%d.mat', algoNames{ai}, probNames{pi}, s);
        if isfile(f)
          v = load(f);
          if ~isfield(v.R, 'igdHistory'), continue; end
          h = v.R.igdHistory;
          g = 1:numel(h);
          plot(g, h, '-', 'Color', colors(ai,:), 'LineWidth', 0.4);
          hold on;
        end
      end
    end
    set(gca,'XScale','log'); grid on; box on;
    xlabel('Generation (log)', 'FontSize', 8);
    ylabel('IGD', 'FontSize', 8);
    title(probNames{pi}, 'FontSize', 9);
    legend(algoNames, 'Location','best', 'FontSize', 6, 'NumColumns', 1);
  end
  exportgraphics(fig, [outdir,'/fig1_igd_conv.pdf'], 'Resolution', 600);
  close(fig);

  %% 2) 前沿散点：ZDT1 (2D) + LSMOP1 (3D)
  fig2 = figure('Visible','off','Position',[100 100 1100 420]);
  ax2 = subplot(1,2,1); hold on;
  vz = load('results/vor2_bench/VOR_ZDT1_s1.mat');
  plot(vz.R.F(:,1), vz.R.F(:,2), 'o', 'MarkerSize', 4, ...
       'MarkerFaceColor', [0 0 1], 'Color', [0 0 1], 'DisplayName', 'VOR');
  ve = load('results/vor2_bench/EDD_ZDT1_s1.mat');
  plot(ve.R.F(:,1), ve.R.F(:,2), 's', 'MarkerSize', 4, ...
       'MarkerFaceColor', [0.9 0.2 0], 'Color', [0.9 0.2 0], 'DisplayName', 'EDD');
  plot(vz.PF(:,1), vz.PF(:,2), 'k-', 'LineWidth', 1.2, 'DisplayName', 'True PF');
  xlabel('$f_1$', 'FontSize', 10); ylabel('$f_2$', 'FontSize', 10);
  title('ZDT1 Pareto front ($M=2$, $D=30$)', 'FontSize', 10);
  legend('Location','best', 'FontSize', 8); grid on; box on;
  ax3 = subplot(1,2,2); hold on;
  vl = load('results/vor2_bench/VOR_LSMOP1_s1.mat');
  plot3(vl.R.F(:,1), vl.R.F(:,2), vl.R.F(:,3), 'o', 'MarkerSize', 4, ...
       'MarkerFaceColor', [0 0 1], 'Color', [0 0 1], 'DisplayName', 'VOR');
  el = load('results/vor2_bench/EDD_LSMOP1_s1.mat');
  plot3(el.R.F(:,1), el.R.F(:,2), el.R.F(:,3), 's', 'MarkerSize', 4, ...
       'MarkerFaceColor', [0.9 0.2 0], 'Color', [0.9 0.2 0], 'DisplayName', 'EDD');
  plot3(vl.PF(:,1), vl.PF(:,2), vl.PF(:,3), 'k-', 'LineWidth', 1.0, 'DisplayName', 'True PF');
  xlabel('$f_1$', 'FontSize', 10); ylabel('$f_2$', 'FontSize', 10); zlabel('$f_3$', 'FontSize', 10);
  title('LSMOP1 Pareto front ($M=3$, $D=300$)', 'FontSize', 10);
  view(135, 35);
  legend('Location','best', 'FontSize', 8); grid on; box on;
  exportgraphics(fig2, [outdir,'/fig2_pf_scat.pdf'], 'Resolution', 600);
  close(fig2);

  %% 3) Friedman 平均秩柱状图（30 seeds, 180 blocks）
  M = NaN(nA, nP, nS);
  for ai = 1:nA
    for pi = 1:nP
      for s = 1:nS
        f = sprintf('results/vor2_bench/%s_%s_s%d.mat', algoNames{ai}, probNames{pi}, s);
        if isfile(f), v = load(f); M(ai,pi,s) = v.igd; end
      end
    end
  end
  R = zeros(nA, nP, nS);
  for pi = 1:nP
    for s = 1:nS
      vals = squeeze(M(:,pi,s));
      if any(isnan(vals)), continue; end
      [~, ord] = sort(vals);
      R(1:nA, pi, s) = ord;
    end
  end
  Rtot = zeros(nA,1);
  for ai = 1:nA
    Rtot(ai) = sum(R(ai,:,:), 'all');
  end
  fig3 = figure('Visible','off','Position',[100 100 560 360]);
  barh(1:nA, Rtot, 0.7, 'FaceColor', [0.2 0.5 0.8]);
  hold on;
  for ai = 1:nA
    text(Rtot(ai), ai, sprintf('  %.1f', Rtot(ai)), 'FontSize', 9, 'Color', [0 0 0]);
  end
  xlabel('Friedman rank sum (180 blocks)', 'FontSize', 10);
  title('Friedman rank test: per-algorithm rank sum (30 seeds)', 'FontSize', 10);
  set(gca, 'YDir', 'reverse', 'YTick', 1:nA, 'YTickLabel', algoNames);
  ylim([0.5, nA+0.5]);
  xlim([0 max(Rtot)*1.25]);
  grid on; box on;
  exportgraphics(fig3, [outdir,'/fig3_friedman.pdf'], 'Resolution', 600);
  close(fig3);

  fid = fopen('results/figs_done_en.txt','w');
  fprintf(fid, '3 vector PDF figs (30-seed) written to %s\n', outdir);
  fclose(fid);
  disp('make_figs_en: 3 PDF figs written (30-seed)');
end
