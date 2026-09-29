function run_m3(algIdx, probIdx, seeds)
% RUN_M3  9 algorithms x 3-objective problems (DTLZ1/DTLZ2/DTLZ7 @ 12,3), 30 seeds.
%   run_m3(algIdx, probIdx, seeds); algIdx 1..9, probIdx 1..3
%   Saves to m3_raw_data.mat: IGD_M3(3,9,30), HV_M3(3,9,30), nFE_M3, elap_M3,
%   errMsg_M3, uniqueRows_M3, mechM3(3,30) for HCEA, refPt_M3 (cell, 3-dim).
%   HV: baselines = HYPE Monte Carlo nSample=10000 (SMSEMOA.calHV style);
%       HCEA = HCEA.calHV (internal calHVM, nSample=1000).
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\ablation');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\utils');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\problems');
DIR  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\metric_disagreement\';
OUTF = [DIR 'm3_raw_data.mat'];
algos = {'NSGA2','NSGA3','MOEAD','SPEA2','SMSEMOA','RVEA','AGEMOEA','MOGWO','HCEA'};
probName_M3 = {'DTLZ1_M3','DTLZ2_M3','DTLZ7_M3'};
seedsAll = 1:30;
IGD_M3 = nan(3,9,30); HV_M3 = IGD_M3; nFE_M3 = IGD_M3; elap_M3 = IGD_M3; uniqueRows_M3 = IGD_M3;
errMsg_M3 = repmat({''},3,9,30);
mechM3 = repmat({''},3,30); switchGenM3 = nan(3,30);
refPt_M3 = cell(3,1);
if exist(OUTF,'file'), S=load(OUTF);
    for f={'IGD_M3','HV_M3','nFE_M3','elap_M3','uniqueRows_M3','errMsg_M3','mechM3','switchGenM3','refPt_M3'}
        if isfield(S,f{1}), eval([f{1} '=S.' f{1} ';']); end
    end
end
switch probIdx
    case 1, p = DTLZ1(12,3); case 2, p = DTLZ2(12,3); case 3, p = DTLZ7(12,3);
end
PF = p.ParetoFront(500);
refPt_M3{probIdx} = max(PF,[],1)*1.1;
aName = algos{algIdx};
for s = seeds
    if ~isnan(IGD_M3(probIdx,algIdx,s)), continue; end
    t0 = tic;
    try
        algo = makeAlgo(aName, s);
        [Pop, Res] = algo.optimize(p);
        IGD_M3(probIdx,algIdx,s) = mean(min(pdist2(PF, Pop.objs), [], 2));
        if algIdx == 9
            hobj = HCEA(100,200,1);
            HV_M3(probIdx,algIdx,s) = hobj.calHV(Pop.objs, refPt_M3{probIdx}, 3);
            mechM3{probIdx,s} = Res.mechanism;
            switchGenM3(probIdx,s) = Res.switchGen;
        else
            HV_M3(probIdx,algIdx,s) = HVMC(Pop.objs, refPt_M3{probIdx}, 10000);
        end
        nFE_M3(probIdx,algIdx,s) = Res.nFE;
        uniqueRows_M3(probIdx,algIdx,s) = size(unique(Pop.objs,'rows'),1);
        elap_M3(probIdx,algIdx,s) = toc(t0);
        save(OUTF,'IGD_M3','HV_M3','nFE_M3','elap_M3','errMsg_M3','uniqueRows_M3','mechM3','switchGenM3','refPt_M3','algos','probName_M3','seedsAll','-v7');
        fprintf('%s/%s seed=%02d IGD=%.6f HV=%.6f t=%.1fs uniq=%d\n', aName, probName_M3{probIdx}, s, IGD_M3(probIdx,algIdx,s), HV_M3(probIdx,algIdx,s), toc(t0), uniqueRows_M3(probIdx,algIdx,s));
    catch e
        errMsg_M3{probIdx,algIdx,s} = e.message;
        elap_M3(probIdx,algIdx,s) = toc(t0);
        save(OUTF,'IGD_M3','HV_M3','nFE_M3','elap_M3','errMsg_M3','uniqueRows_M3','mechM3','switchGenM3','refPt_M3','algos','probName_M3','seedsAll','-v7');
        fprintf('%s/%s seed=%02d ERROR: %s\n', aName, probName_M3{probIdx}, s, e.message);
    end
end
fprintf('DONE %s %s: %d/30\n', aName, probName_M3{probIdx}, sum(~isnan(IGD_M3(probIdx,algIdx,:))));
end
function algo = makeAlgo(aName, s)
switch lower(aName)
    case 'nsga2',   algo = NSGA2(100,200,s);
    case 'nsga3',   algo = NSGA3(100,200,s);
    case 'moead',   algo = MOEAD(100,200,s);
    case 'spea2',   algo = SPEA2(100,200,s);
    case 'smsemoa', algo = SMSEMOA(100,200,s);
    case 'rvea',    algo = RVEA(100,200,s);
    case 'agemoea', algo = AGEMOEA(100,200,s);
    case 'mogwo',   algo = MOGWO(100,200,s);
    case 'hcea',    algo = HCEA(100,200,s);
    otherwise, error('unknown %s', aName);
end
end
function hv = HVMC(P, ref, nSamp)
% HYPE Monte Carlo HV (k=1), same as SMSEMOA.calHV but nSample parameterized.
P = P(all(P<=ref,2),:); [N,M] = size(P);
if N==0, hv=0; return; end
k=1;
alpha = zeros(1,N);   % SMSEMOA 原版：alpha 长度为 N
for i=1:min(k,N), alpha(i) = prod((k-[1:i-1])./(N-[1:i-1]))/i; end
Fmin = min(P,[],1);
S = unifrnd(repmat(Fmin,nSamp,1), repmat(ref,nSamp,1));
PdS = false(N,nSamp); dS = zeros(1,nSamp);
for i=1:N
    x = sum(repmat(P(i,:),nSamp,1)-S<=0,2)==M;
    PdS(i,x)=true; dS(x)=dS(x)+1;
end
F = zeros(1,N);
for i=1:N, F(i)=sum(alpha(dS(PdS(i,:)))); end
hv = sum(F.*prod(ref-Fmin)/nSamp);
end
