function run_mogwo200(probIdx, seeds)
% RUN_MOGWO200  MOGWO at maxGen=200 (unified budget) on 2-objective problems.
%   run_mogwo200(probIdx, seeds); probIdx 1..5 = ZDT1..DTLZ7
%   Saves to mogwo_200gen.mat (resumable).
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\utils');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\problems');
DIR  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\metric_disagreement\';
OUTF = [DIR 'mogwo_200gen.mat'];
probName = {'ZDT1','ZDT2','ZDT3','DTLZ2','DTLZ7'};
switch probIdx
    case 1, p = ZDT1(30);  case 2, p = ZDT2(30);  case 3, p = ZDT3(30);
    case 4, p = DTLZ2(12,2); case 5, p = DTLZ7(12,2);
end
PF = p.ParetoFront(500); ref = max(PF,[],1)*1.1;
IGD = nan(5,30); HV = nan(5,30); nFE = nan(5,30); elap = nan(5,30);
errMsg = repmat({''},5,30); refPt = zeros(5,2);
if exist(OUTF,'file'), S = load(OUTF);
    if isfield(S,'IGD'), IGD=S.IGD; HV=S.HV; nFE=S.nFE; elap=S.elap; errMsg=S.errMsg; refPt=S.refPt; end
end
refPt(probIdx,:) = ref;
for s = seeds
    if ~isnan(IGD(probIdx,s)), continue; end
    t0 = tic;
    try
        [Pop, Res] = MOGWO(100, 200, s).optimize(p);
        IGD(probIdx,s) = mean(min(pdist2(PF, Pop.objs), [], 2));
        HV(probIdx,s)  = HV2D(Pop.objs, ref);
        nFE(probIdx,s) = Res.nFE;
        elap(probIdx,s) = toc(t0);
        save(OUTF,'IGD','HV','nFE','elap','errMsg','refPt','probName','-v7');
        fprintf('MOGWO200/%s seed=%02d IGD=%.6f HV=%.6f nFE=%d t=%.1fs\n', probName{probIdx}, s, IGD(probIdx,s), HV(probIdx,s), Res.nFE, toc(t0));
    catch e
        errMsg{probIdx,s} = e.message;
        elap(probIdx,s) = toc(t0);
        save(OUTF,'IGD','HV','nFE','elap','errMsg','refPt','probName','-v7');
        fprintf('MOGWO200/%s seed=%02d ERROR: %s\n', probName{probIdx}, s, e.message);
    end
end
fprintf('DONE MOGWO200 %s: %d/30\n', probName{probIdx}, sum(~isnan(IGD(probIdx,:))));
end
function hv = HV2D(P, ref)
P = P(all(P<=ref,2),:); if isempty(P), hv=0; return; end
P = sortrows(P,1); x=[P(:,1);ref(1)]; hv=0; ymin=ref(2);
for i=1:size(P,1), if P(i,2)<ymin, ymin=P(i,2); end, hv=hv+(x(i+1)-x(i))*(ref(2)-ymin); end
end
