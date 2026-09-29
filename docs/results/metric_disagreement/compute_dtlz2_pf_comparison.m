function compute_dtlz2_pf_comparison()
% COMPUTE_DTLZ2_PF_COMPARISON  Compare IGD under two DTLZ2 reference fronts
%   PF_A = problem.ParetoFront(500)  (PlatEMO NBI discretization)
%   PF_B = [cos(t), sin(t)], t = linspace(0,pi/2,500)  (arc-uniform)
%   Uses saved objs (dtlz2_objs.mat); verifies bit-level agreement with old
%   raw_data.mat IGD; recomputes IGD ranks under both PFs and Spearman/Kendall
%   of (IGD rank vector, HV rank vector). HV ranks are reused from raw_data.mat.

addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\utils');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\problems');

DIR = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\metric_disagreement\';
O = load([DIR 'dtlz2_objs.mat']);
R = load([DIR 'raw_data.mat']);
objs = O.objs; algos = O.algos;
nA = 9; nS = 30;

%% two reference fronts
p = DTLZ2(12, 2);
PF_A = p.ParetoFront(500);
t = linspace(0, pi/2, 500)';
PF_B = [cos(t), sin(t)];

%% IGD under both PFs
IGD_A = nan(nA, nS); IGD_B = nan(nA, nS);
for ia = 1:nA
    for s = 1:nS
        if isempty(objs{ia, s}), continue; end
        IGD_A(ia, s) = IGD(objs{ia, s}, PF_A);
        IGD_B(ia, s) = IGD(objs{ia, s}, PF_B);
    end
end

%% bit-level verification vs old raw_data.mat (old IGD used the same PF_A)
oldIGD = squeeze(R.IGD(4, :, :));   % [nA x nS]
relDiff = abs(IGD_A - oldIGD) ./ max(oldIGD, 1e-12);
maxRel = max(relDiff, [], 'all');
maxAbs = max(abs(IGD_A - oldIGD), [], 'all');
fprintf('=== verification vs old raw_data.mat (PF_A) ===\n');
fprintf('max abs diff = %.3e, max rel diff = %.6f%%\n', maxAbs, 100*maxRel);
for ia = 1:nA
    d = abs(IGD_A(ia,:) - oldIGD(ia,:));
    fprintf('  %-8s max abs diff = %.3e\n', algos{ia}, max(d));
end
if 100*maxRel > 1
    fprintf('WARNING: rel diff > 1%% -> stop and report per protocol\n');
    return;
end

%% means, ranks, HV ranks
mI_A = mean(IGD_A, 2, 'omitnan'); mI_B = mean(IGD_B, 2, 'omitnan');
sI_A = std(IGD_A, 0, 2, 'omitnan'); sI_B = std(IGD_B, 0, 2, 'omitnan');
mH = mean(squeeze(R.HV(4, :, :)), 2, 'omitnan');   % old HV means (unchanged)

[~, o] = sort(mI_A); rI_A = zeros(nA,1); for k=1:nA, rI_A(o(k)) = k; end
[~, o] = sort(mI_B); rI_B = zeros(nA,1); for k=1:nA, rI_B(o(k)) = k; end
[~, o] = sort(mH, 'descend'); rH = zeros(nA,1); for k=1:nA, rH(o(k)) = k; end
rdA = rI_A - rH; rdB = rI_B - rH;

[rhoA, ~] = corr(rI_A, rH, 'type', 'Spearman');
[tauA, ~] = corr(rI_A, rH, 'type', 'Kendall');
[rhoB, ~] = corr(rI_B, rH, 'type', 'Spearman');
[tauB, ~] = corr(rI_B, rH, 'type', 'Kendall');

%% print
fprintf('\n=== IGD mean +/- std under PF_A (NBI) ===\n');
for ia = 1:nA, fprintf('  %-8s %.6f +/- %.6f\n', algos{ia}, mI_A(ia), sI_A(ia)); end
fprintf('\n=== IGD mean +/- std under PF_B (arc-uniform) ===\n');
for ia = 1:nA, fprintf('  %-8s %.6f +/- %.6f\n', algos{ia}, mI_B(ia), sI_B(ia)); end
fprintf('\n=== ranks ===\n');
fprintf('%-8s %6s %6s %6s %8s %8s\n', 'Algo', 'rI_A', 'rI_B', 'rH', 'diff_A', 'diff_B');
for ia = 1:nA
    fprintf('%-8s %6d %6d %6d %8d %8d\n', algos{ia}, rI_A(ia), rI_B(ia), rH(ia), rdA(ia), rdB(ia));
end
fprintf('\nSpearman: PF_A rho=%.4f, PF_B rho=%.4f\n', rhoA, rhoB);
fprintf('Kendall:   PF_A tau=%.4f, PF_B tau=%.4f\n', tauA, tauB);

%% save results
save([DIR 'dtlz2_pf_comparison.mat'], 'PF_A', 'PF_B', 'IGD_A', 'IGD_B', 'mI_A', 'mI_B', ...
     'sI_A', 'sI_B', 'mH', 'rI_A', 'rI_B', 'rH', 'rdA', 'rdB', 'rhoA', 'tauA', 'rhoB', 'tauB', ...
     'oldIGD', 'maxRel', 'maxAbs', 'algos');
fprintf('\nsaved dtlz2_pf_comparison.mat\n');
end
