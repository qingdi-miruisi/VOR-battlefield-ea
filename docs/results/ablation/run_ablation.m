function run_ablation(varIdx, probIdx, seeds)
% RUN_ABLATION  Run one HCEA ablation variant on one problem (resumable).
%   run_ablation(varIdx, probIdx, seeds)
%   varIdx : 1..8 = HCEA, HCEA_A1, HCEA_B1, HCEA_C1, HCEA_D1, HCEA_D2, HCEA_D3, HCEA_D4
%   probIdx: 1 = ZDT1(30), 2 = DTLZ2(12,2)
%   HCEA (varIdx=1) is reused from metric_disagreement/raw_data.mat (never re-run).
%   Config: popSize=100, maxGen=200, seeds 1..30.
%   Metrics: IGD vs ParetoFront(500); HV vs max(PF500)*1.1 (same as metric study).

addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\ablation');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\utils');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\problems');

DIR  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\ablation\';
OUTF = [DIR 'raw_ablation.mat'];
MD   = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\metric_disagreement\raw_data.mat';

names = {'HCEA','HCEA_A1','HCEA_B1','HCEA_C1','HCEA_D1','HCEA_D2','HCEA_D3','HCEA_D4'};
nV = 8; nP = 2; nS = 30;

IGD = nan(nP, nV, nS); HV = IGD; nFE = IGD; elap = IGD;
errMsg = repmat({''}, nP, nV, nS); refPt = zeros(nP, 2);

if exist(OUTF, 'file')
    S = load(OUTF);
    if isfield(S,'IGD'), IGD = S.IGD; end
    if isfield(S,'HV'), HV = S.HV; end
    if isfield(S,'nFE'), nFE = S.nFE; end
    if isfield(S,'elap'), elap = S.elap; end
    if isfield(S,'errMsg'), errMsg = S.errMsg; end
    if isfield(S,'refPt'), refPt = S.refPt; end
end

% HCEA (varIdx=1) reuse: copy from metric_disagreement raw_data.mat
if exist(MD, 'file')
    R = load(MD);
    % ZDT1 -> R.IGD(1,:,:); DTLZ2 -> R.IGD(4,:,:)
    IGD(1,1,:) = squeeze(R.IGD(1,9,:)); HV(1,1,:) = squeeze(R.HV(1,9,:));
    IGD(2,1,:) = squeeze(R.IGD(4,9,:)); HV(2,1,:) = squeeze(R.HV(4,9,:));
    nFE(1,1,:) = squeeze(R.nFE(1,9,:)); nFE(2,1,:) = squeeze(R.nFE(4,9,:));
    elap(1,1,:) = squeeze(R.elap(1,9,:)); elap(2,1,:) = squeeze(R.elap(4,9,:));
    errMsg(:,1,:) = {''};
end

switch probIdx
    case 1, p = ZDT1(30);
    case 2, p = DTLZ2(12, 2);
    otherwise, error('bad probIdx');
end
PF = p.ParetoFront(500);
refPt(probIdx, :) = max(PF, [], 1) * 1.1;

if varIdx == 1
    fprintf('HCEA (varIdx=1) reused from metric_disagreement data; nothing to run.\n');
    save(OUTF, 'IGD', 'HV', 'nFE', 'elap', 'errMsg', 'refPt', 'names', '-v7');
    return;
end

vName = names{varIdx};
for s = seeds
    if ~isnan(IGD(probIdx, varIdx, s)), continue; end
    t0 = tic;
    try
        algo = feval(vName, 100, 200, s);
        [Pop, Res] = algo.optimize(p);
        IGD(probIdx, varIdx, s) = IGDm(Pop.objs, PF);
        HV(probIdx, varIdx, s)  = HV2D(Pop.objs, refPt(probIdx, :));
        nFE(probIdx, varIdx, s) = Res.nFE;
        elap(probIdx, varIdx, s) = toc(t0);
        save(OUTF, 'IGD', 'HV', 'nFE', 'elap', 'errMsg', 'refPt', 'names', '-v7');
        fprintf('%s/seed=%02d IGD=%.6f HV=%.6f nFE=%d t=%.1fs\n', vName, s, ...
            IGD(probIdx,varIdx,s), HV(probIdx,varIdx,s), Res.nFE, toc(t0));
    catch e
        errMsg{probIdx, varIdx, s} = e.message;
        elap(probIdx, varIdx, s) = toc(t0);
        save(OUTF, 'IGD', 'HV', 'nFE', 'elap', 'errMsg', 'refPt', 'names', '-v7');
        fprintf('%s/seed=%02d ERROR: %s\n', vName, s, e.message);
    end
end
fprintf('DONE %s on problem %d: %d/30 computed\n', vName, probIdx, ...
    sum(~isnan(IGD(probIdx, varIdx, :))));
end

function v = IGDm(A, PF)
v = mean(min(pdist2(PF, A), [], 2));
end

function hv = HV2D(P, ref)
P = P(all(P <= ref, 2), :);
if isempty(P), hv = 0; return; end
P = sortrows(P, 1);
x = [P(:,1); ref(1)];
hv = 0; ymin = ref(2);
for i = 1:size(P,1)
    if P(i,2) < ymin, ymin = P(i,2); end
    hv = hv + (x(i+1) - x(i)) * (ref(2) - ymin);
end
end
