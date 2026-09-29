function compute_paper_numbers()
% COMPUTE_PAPER_NUMBERS  Compute all numbers needed by the paper tables and
% export them as JSON (paper_numbers.json) for the Node-based .tex writer.
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\utils');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\problems');

DIR  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\metric_disagreement\';
OUT  = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\paper\scripts\paper_numbers.json';
R = load([DIR 'raw_data.mat']);
ST = load([DIR 'statistical_tests.mat']);
IGD = R.IGD; HV = R.HV; algos = R.algos; probName = R.probName;
[nP, nA, nS] = size(IGD);

mI = mean(IGD, 3, 'omitnan'); sI = std(IGD, 0, 3, 'omitnan');
mH = mean(HV, 3, 'omitnan');  sH = std(HV, 0, 3, 'omitnan');
totT = sum(sum(R.elap, 3, 'omitnan'), 1);   % 1 x nA total time
mnFE = zeros(1, nA);
for ia = 1:nA, mnFE(ia) = mean(reshape(R.nFE(:,ia,:), [], 1), 'omitnan'); end

rI = zeros(nP, nA); rH = zeros(nP, nA);
for ip = 1:nP
    [~,o] = sort(mI(ip,:)); for k=1:nA, rI(ip,o(k)) = k; end
    [~,o] = sort(mH(ip,:),'descend'); for k=1:nA, rH(ip,o(k)) = k; end
end
avgI = mean(rI, 1); avgH = mean(rH, 1);

h = find(strcmp(algos,'HCEA'));
ppI = zeros(nA-1, nP); pcI = zeros(nA-1,1); ppH = zeros(nA-1,nP); pcH = zeros(nA-1,1);
other = algos([1:h-1, h+1:end]);
for k = 1:nA-1
    a = find(strcmp(algos, other{k}));
    ppI(k,:) = ST.PprobI{h,a};
    pcI(k)   = ST.PcombI(h,a);
    ppH(k,:) = ST.PprobH{h,a};
    pcH(k)   = ST.PcombH(h,a);
end

out = struct('algos', {algos}, 'probName', {probName}, 'mI', mI, 'sI', sI, 'mH', mH, 'sH', sH, ...
             'rI', rI, 'rH', rH, 'avgI', avgI, 'avgH', avgH, ...
             'mrI', ST.mrI, 'mrH', ST.mrH, 'chiI', ST.chiI, 'pI', ST.pI, 'chiH', ST.chiH, 'pH', ST.pH, ...
             'other', {other}, 'ppI', ppI, 'pcI', pcI', 'ppH', ppH, 'pcH', pcH', ...
             'totT', totT, 'mnFE', mnFE);
txt = jsonencode(out);
fid = fopen(OUT, 'w'); fprintf(fid, '%s', txt); fclose(fid);
fprintf('wrote %s (%d bytes)\n', OUT, numel(txt));
end
