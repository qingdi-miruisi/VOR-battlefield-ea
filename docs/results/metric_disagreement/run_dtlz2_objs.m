function run_dtlz2_objs(algIdx, seeds)
% RUN_DTLZ2_OBJS  Re-run DTLZ2 for one algorithm, saving final Population.objs.
%   run_dtlz2_objs(algIdx, seeds)
%   algIdx: 1..9 (NSGA2, NSGA3, MOEAD, SPEA2, SMSEMOA, RVEA, AGEMOEA, MOGWO, HCEA)
%   Config: popSize=100, maxGen=200 (MOGWO=500). Resumable.
%   Saves to dtlz2_objs.mat: objs{9,30} ([N x 2] each), algos, seeds, nFE, elapsed, errMsg.

addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\utils');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\problems');

DIR  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\metric_disagreement\';
OBJF = [DIR 'dtlz2_objs.mat'];

algos = {'NSGA2','NSGA3','MOEAD','SPEA2','SMSEMOA','RVEA','AGEMOEA','MOGWO','HCEA'};
seedsAll = 1:30;
nA = 9; nS = 30;

objs = cell(nA, nS); nFE = nan(nA, nS); elapsed = nan(nA, nS); errMsg = repmat({''}, nA, nS);
if exist(OBJF, 'file')
    S = load(OBJF);
    if isfield(S, 'objs'), objs = S.objs; end
    if isfield(S, 'nFE'), nFE = S.nFE; end
    if isfield(S, 'elapsed'), elapsed = S.elapsed; end
    if isfield(S, 'errMsg'), errMsg = S.errMsg; end
end

aName = algos{algIdx};
maxGen = 200; if strcmp(aName, 'MOGWO'), maxGen = 500; end
p = DTLZ2(12, 2);

for s = seeds
    if ~isempty(objs{algIdx, s}), continue; end
    t0 = tic;
    try
        algo = makeAlgo(aName, maxGen, s);
        [Pop, Res] = algo.optimize(p);
        objs{algIdx, s} = Pop.objs;
        nFE(algIdx, s)     = Res.nFE;
        elapsed(algIdx, s) = toc(t0);
        save(OBJF, 'objs', 'nFE', 'elapsed', 'errMsg', 'algos', 'seedsAll', '-v7');
        fprintf('%s/DTLZ2 seed=%02d |objs|=%d t=%.1fs\n', aName, s, size(Pop.objs,1), toc(t0));
    catch e
        errMsg{algIdx, s} = e.message;
        elapsed(algIdx, s) = toc(t0);
        save(OBJF, 'objs', 'nFE', 'elapsed', 'errMsg', 'algos', 'seedsAll', '-v7');
        fprintf('%s/DTLZ2 seed=%02d ERROR: %s\n', aName, s, e.message);
    end
end
fprintf('DONE %s on DTLZ2: %d/30 computed\n', aName, sum(~cellfun(@isempty, objs(algIdx,:))));
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
