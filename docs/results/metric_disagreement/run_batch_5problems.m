function run_batch_5problems(probIdx, algIdx, seeds)
% RUN_BATCH_5PROBLEMS  Batch runner for the IGD/HV metric-disagreement study.
%   run_batch_5problems(probIdx, algIdx, seeds)
%   probIdx : 1..5  (ZDT1, ZDT2, ZDT3, DTLZ2, DTLZ7)
%   algIdx  : 1..9  (NSGA2, NSGA3, MOEAD, SPEA2, SMSEMOA, RVEA, AGEMOEA, MOGWO, HCEA)
%   seeds   : vector of seeds to run (resumable: already-computed seeds are skipped)
%
% Config: popSize=100, maxGen=200 (MOGWO=500), seeds 1..30
% Metrics per run:
%   IGD = IGD(objs, problem.ParetoFront(500))
%   HV  = HV2D(objs, max(problem.ParetoFront(500))*1.1)   % exact 2D, ref fixed per problem
% Data saved to raw_data.mat in this directory after each run.

addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\utils');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\problems');

DIR  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\metric_disagreement\';
RAWF = [DIR 'raw_data.mat'];

algos    = {'NSGA2','NSGA3','MOEAD','SPEA2','SMSEMOA','RVEA','AGEMOEA','MOGWO','HCEA'};
probName = {'ZDT1','ZDT2','ZDT3','DTLZ2','DTLZ7'};
nP = 5; nA = 9; nS = 30;

%% ---- load existing progress (resume) ----
IGD = nan(nP, nA, nS); HV = IGD; nFE = IGD; elap = IGD;
errMsg = repmat({''}, nP, nA, nS);
refPt = zeros(nP, 2);
if exist(RAWF, 'file')
    S = load(RAWF);
    if isfield(S, 'IGD'), IGD = S.IGD; end
    if isfield(S, 'HV'),  HV  = S.HV;  end
    if isfield(S, 'nFE'), nFE = S.nFE; end
    if isfield(S, 'elap'), elap = S.elap; end
    if isfield(S, 'errMsg'), errMsg = S.errMsg; end
    if isfield(S, 'refPt'), refPt = S.refPt; end
end

%% ---- per (problem, algorithm) ----
p  = makeProblem(probIdx, probName);
PF = p.ParetoFront(500);
refPt(probIdx, :) = max(PF, [], 1) * 1.1;   % adaptive per-problem reference, fixed across algorithms

aName = algos{algIdx};
maxGen = 200; if strcmp(aName, 'MOGWO'), maxGen = 500; end

for s = seeds
    if ~isnan(IGD(probIdx, algIdx, s)), continue; end
    t0 = tic;
    ok = false;
    try
        algo = makeAlgo(aName, maxGen, s);
        [Pop, Res] = algo.optimize(p);
        IGD(probIdx, algIdx, s) = IGDmetric(Pop.objs, PF);
        HV(probIdx, algIdx, s)  = HV2D(Pop.objs, refPt(probIdx, :));
        nFE(probIdx, algIdx, s) = Res.nFE;
        elap(probIdx, algIdx, s) = toc(t0);
        ok = true;
    catch e
        errMsg{probIdx, algIdx, s} = e.message;
        elap(probIdx, algIdx, s) = toc(t0);
    end
    save(RAWF, 'IGD', 'HV', 'nFE', 'elap', 'errMsg', 'refPt', 'algos', 'probName', '-v7');
    if ok
        fprintf('%s/%s seed=%02d IGD=%.6f HV=%.6f nFE=%d t=%.1fs\n', ...
            aName, probName{probIdx}, s, IGD(probIdx,algIdx,s), HV(probIdx,algIdx,s), nFE(probIdx,algIdx,s), elap(probIdx,algIdx,s));
    else
        fprintf('%s/%s seed=%02d ERROR: %s\n', aName, probName{probIdx}, s, errMsg{probIdx,algIdx,s});
    end
end
fprintf('DONE %s on %s: %d/%d seeds computed\n', aName, probName{probIdx}, ...
    sum(~isnan(IGD(probIdx,algIdx,:))), nS);
end

%% ==================== local functions ====================
function p = makeProblem(probIdx, probName)
switch probIdx
    case 1, p = ZDT1(30);
    case 2, p = ZDT2(30);
    case 3, p = ZDT3(30);
    case 4, p = DTLZ2(12, 2);
    case 5, p = DTLZ7(12, 2);
    otherwise, error('bad problem index');
end
end

function algo = makeAlgo(aName, maxGen, s)
switch lower(aName)
    case 'nsga2',   algo = NSGA2(100, maxGen, s);
    case 'nsga3',   algo = NSGA3(100, maxGen, s);
    case 'moead',   algo = MOEAD(100, maxGen, s);
    case 'spea2',   algo = SPEA2(100, maxGen, s);
    case 'smsemoa', algo = SMSEMOA(100, maxGen, s);
    case 'rvea',    algo = RVEA(100, maxGen, s);
    case 'agemoea', algo = AGEMOEA(100, maxGen, s);
    case 'mogwo',   algo = MOGWO(100, maxGen, s);
    case 'hcea',    algo = HCEA(100, maxGen, s);
    otherwise, error('unknown algorithm %s', aName);
end
end

function v = IGDmetric(A, PF)
% Workspace IGD (PlatEMO official): mean over PF rows of min distance to A
v = mean(min(pdist2(PF, A), [], 2));
end

function hv = HV2D(P, ref)
% Exact 2D hypervolume (minimization) w.r.t. reference point ref.
% Standard staircase: sort by f1, each slice [f1(i), f1(i+1)] has height
% ref(2) - (running minimum f2). Points outside the box contribute nothing.
P = P(all(P <= ref, 2), :);
if isempty(P)
    hv = 0; return;
end
P = sortrows(P, 1);
x = [P(:,1); ref(1)];
hv = 0; ymin = ref(2);
for i = 1:size(P, 1)
    if P(i,2) < ymin
        ymin = P(i,2);
    end
    hv = hv + (x(i+1) - x(i)) * (ref(2) - ymin);
end
end
