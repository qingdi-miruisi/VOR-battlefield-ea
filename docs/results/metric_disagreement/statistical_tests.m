function statistical_tests()
% STATISTICAL_TESTS  Friedman + Wilcoxon + Nemenyi CD on the 5x9x30 IGD/HV data.
%   Blocks: 5 problems (each cell = 30-seed mean). No algorithm re-runs.

addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\utils');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\problems');

DIR  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\metric_disagreement\';
FIG  = [DIR 'figures\'];
if ~exist(FIG, 'dir'), mkdir(FIG); end

S = load([DIR 'raw_data.mat']);
IGD = S.IGD; HV = S.HV; algos = S.algos; probName = S.probName;
[nP, nA, nS] = size(IGD);
k = nA; N = nP;

mI = mean(IGD, 3, 'omitnan');            % [5x9] IGD means (lower better)
mH = mean(HV, 3, 'omitnan');             % [5x9] HV means (higher better)

%% ================= 1. Friedman =================
% rows = 5 problems (blocks), cols = 9 algorithms, reps = 1 (cell = 30-seed mean)
[pI, tblI, stI] = friedman(mI, 1);
[pH, tblH, stH] = friedman(-mH, 1);      % negate HV so "better" ranks like IGD
chiI = tblI{2,5}; chiH = tblH{2,5};
mrI = stI.meanranks; mrH = stH.meanranks;

fprintf('=== Friedman IGD ===\n');
fprintf('chi2 = %.4f, df = %d, p = %.4e\n', chiI, tblI{2,3}, pI);
fprintf('mean ranks (1=best):\n');
for a = 1:nA, fprintf('  %-8s %.4f\n', algos{a}, mrI(a)); end
fprintf('=== Friedman HV ===\n');
fprintf('chi2 = %.4f, df = %d, p = %.4e\n', chiH, tblH{2,3}, pH);
fprintf('mean ranks (1=best):\n');
for a = 1:nA, fprintf('  %-8s %.4f\n', algos{a}, mrH(a)); end

%% ================= 2. Wilcoxon pairwise =================
% all 36 pairs; per problem 30-seed ranksum; combine 5 problems by Fisher
PcombI = ones(nA); PcombH = ones(nA);
PprobI = cell(nA); PprobH = cell(nA);
for i = 1:nA
    for j = i+1:nA
        pi5 = zeros(1, nP); ph5 = zeros(1, nP);
        for q = 1:nP
            pi5(q) = ranksum(squeeze(IGD(q,i,:)), squeeze(IGD(q,j,:)));
            ph5(q) = ranksum(squeeze(HV(q,i,:)),  squeeze(HV(q,j,:)));
        end
        PcombI(i,j) = fisherCombine(pi5); PcombI(j,i) = PcombI(i,j);
        PcombH(i,j) = fisherCombine(ph5); PcombH(j,i) = PcombH(i,j);
        PprobI{i,j} = pi5; PprobI{j,i} = pi5;
        PprobH{i,j} = ph5; PprobH{j,i} = ph5;
    end
end
fprintf('\n=== Wilcoxon HCEA vs others (Fisher-combined over 5 problems) ===\n');
h = 9;
fprintf('%-10s %-12s %-12s %-12s %s\n', 'vs', 'p_IGD', 'sig_IGD', 'p_HV', 'sig_HV');
for a = 1:nA
    if a == h, continue; end
    fprintf('%-10s %.4e %-12s %.4e %s\n', algos{a}, PcombI(h,a), star(PcombI(h,a)), PcombH(h,a), star(PcombH(h,a)));
end
fprintf('\nHCEA per-problem IGD p-values:\n');
for a = 1:nA
    if a == h, continue; end
    fprintf('  vs %-8s ', algos{a});
    for q = 1:nP, fprintf('%s=%.3g ', probName{q}, PprobI{h,a}(q)); end
    fprintf('\n');
end

%% ================= 3. Nemenyi CD =================
% q_{0.05, k=9} = 3.102 (Demsar table)
qA = 3.102;
CD = qA * sqrt(k*(k+1) / (6*N));
fprintf('\nHCEA per-problem HV p-values:\n');
for a = 1:nA
    if a == h, continue; end
    fprintf('  vs %-8s ', algos{a});
    for q = 1:nP, fprintf('%s=%.3g ', probName{q}, PprobH{h,a}(q)); end
    fprintf('\n');
end

fprintf('\n=== Nemenyi CD ===\n');
fprintf('k=%d, N=%d blocks, alpha=0.05, q=3.102 -> CD = %.4f\n', k, N, CD);

fprintf('\nIGD: HCEA mean rank %.4f; algorithms NOT significantly different from HCEA (|rank diff| < CD):\n', mrI(h));
for a = 1:nA
    if a ~= h && abs(mrI(a) - mrI(h)) < CD
        fprintf('  %-8s rank %.4f |diff| %.4f\n', algos{a}, mrI(a), abs(mrI(a)-mrI(h)));
    end
end
fprintf('HV: HCEA mean rank %.4f; algorithms NOT significantly different from HCEA:\n', mrH(h));
for a = 1:nA
    if a ~= h && abs(mrH(a) - mrH(h)) < CD
        fprintf('  %-8s rank %.4f |diff| %.4f\n', algos{a}, mrH(a), abs(mrH(a)-mrH(h)));
    end
end

%% CD figures
drawCD(mrI, algos, CD, [FIG 'fig4_cd_igd.png'], [FIG 'fig4_cd_igd.fig'], 'CD diagram - IGD (alpha=0.05)');
drawCD(mrH, algos, CD, [FIG 'fig4_cd_hv.png'],  [FIG 'fig4_cd_hv.fig'],  'CD diagram - HV (alpha=0.05)');

%% ================= 4. xlsx =================
xlsx = [DIR 'statistical_tests.xlsx'];
if exist(xlsx, 'file'), delete(xlsx); end
% Friedman sheets
frI = cell(nA+2, 3);
frI(1,:) = {'Algorithm','Friedman mean rank (IGD, 1=best)',''};
for a = 1:nA, frI(a+1,:) = {algos{a}, mrI(a), ''}; end
frI(nA+2,:) = {sprintf('chi2=%.4f df=%d p=%.4e', chiI, tblI{2,3}, pI), '', ''};
xlswrite(xlsx, frI, 'Friedman_IGD');
frH = cell(nA+2, 3);
frH(1,:) = {'Algorithm','Friedman mean rank (HV, 1=best)',''};
for a = 1:nA, frH(a+1,:) = {algos{a}, mrH(a), ''}; end
frH(nA+2,:) = {sprintf('chi2=%.4f df=%d p=%.4e', chiH, tblH{2,3}, pH), '', ''};
xlswrite(xlsx, frH, 'Friedman_HV');
% Wilcoxon sheets: 9x9 combined-p matrix + HCEA per-problem detail
wI = cell(nA+1, nA+1); wI(1,1) = {'IGD Fisher-combined p (pairs)'};
wI(1,2:end) = algos;
for a = 1:nA, wI(a+1,1) = algos(a); end
for i = 1:nA, for j = 1:nA, wI(i+1,j+1) = {PcombI(i,j)}; end, end
detail = cell(nA+2, nP+3);
detail(1,:) = [{'HCEA vs'}, probName, {'Fisher-p'}, {'sig'}];
for a = 1:nA
    if a == h, continue; end
    detail(a+1,:) = [algos(a), num2cell(PprobI{h,a}), {PcombI(h,a)}, {star(PcombI(h,a))}];
end
xlswrite(xlsx, wI, 'Wilcoxon_IGD');
xlswrite(xlsx, detail, 'Wilcoxon_IGD_detail');
wH = cell(nA+1, nA+1); wH(1,1) = {'HV Fisher-combined p (pairs)'};
wH(1,2:end) = algos;
for a = 1:nA, wH(a+1,1) = algos(a); end
for i = 1:nA, for j = 1:nA, wH(i+1,j+1) = {PcombH(i,j)}; end, end
xlswrite(xlsx, wH, 'Wilcoxon_HV');
% CD sheet
cds = cell(nA+2, 5);
cds(1,:) = {'Algorithm','IGD mean rank (1=best)','HV mean rank (1=best)','CD value','Within CD of HCEA (IGD)'};
for a = 1:nA
    inCD = abs(mrI(a)-mrI(h)) < CD;
    cds(a+1,:) = {algos{a}, mrI(a), mrH(a), CD, inCD};
end
cds(nA+2,:) = {'Nemenyi CD (k=9, N=5, alpha=0.05)', CD, '', '', ''};
xlswrite(xlsx, cds, 'CD_data');
fprintf('\nwrote %s\n', xlsx);

%% save mat
save([DIR 'statistical_tests.mat'], 'mrI', 'mrH', 'chiI', 'chiH', 'pI', 'pH', ...
     'PcombI', 'PcombH', 'PprobI', 'PprobH', 'CD', 'qA', 'algos');
fprintf('saved statistical_tests.mat\n');
end

%% ============ local helpers ============
function pc = fisherCombine(ps)
ps = max(ps, 1e-300);
X2 = -2 * sum(log(ps));
pc = max(1 - chi2cdf(X2, 2*numel(ps)), 1e-300);
end

function s = star(p)
if p < 0.001, s = '***'; elseif p < 0.01, s = '**'; elseif p < 0.05, s = '*'; else, s = 'ns'; end
end

function drawCD(ranks, names, cd, pngPath, figPath, titlestr)
[ranks, ord] = sort(ranks);
names = names(ord);
k = numel(ranks);
f = figure('Color','w','Position',[80 80 1320 420]); hold on;
set(gca, 'XDir', 'reverse');                % rank 1 on the right
set(gca, 'XTick', 1:k, 'FontSize', 10);
set(gca, 'YTick', []);
set(gca, 'XLim', [0.4, k+0.6], 'YLim', [0, 7]);
xlabel('Mean rank (1 = best)');
title(titlestr);
baseY = 1.8;
line([1, k], [baseY, baseY], 'Color', 'k', 'LineWidth', 1.5);
% greedy Nemenyi grouping lines
i = 1; h = 0.5;
while i <= k
    j = i;
    while j < k && ranks(j+1) - ranks(i) < cd
        j = j + 1;
    end
    if j > i
        line([ranks(i), ranks(j)], [baseY+h, baseY+h], 'Color', 'k', 'LineWidth', 1.2);
    end
    h = h + 0.5;
    i = j + 1;
end
for a = 1:k
    y = baseY + 0.38*mod(a-1, 3) + 0.15;
    text(ranks(a), y, names{a}, 'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', 'FontSize', 11);
    plot(ranks(a), baseY, 'k.', 'MarkerSize', 14);
end
exportgraphics(f, pngPath, 'Resolution', 150);
savefig(f, figPath);
close(f);
end
