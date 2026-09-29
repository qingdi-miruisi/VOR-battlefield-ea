% EDDV8 CF/MW 全量 30 seeds 运行
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear IGD HV;

testSet = {'CF1','CF2','CF3','CF4','CF5','CF6','CF7','CF8','CF9','CF10','MW1','MW2','MW3','MW4','MW5','MW6','MW7','MW8','MW9','MW10','MW11','MW12','MW13','MW14'};
nT = numel(testSet);
outDir = 'results\cf_eddv8';
if ~isdir(outDir), mkdir(outDir); end

N = 100; G = 200;
for p = 1:nT
  pn = testSet{p};
  prob = OfficialProblem(pn, 3, 10);   % D 由官方类决定（CF/MW D=10-15）
  PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
  igd = nan(1,30); hv = nan(1,30);
  for s = 1:30
    fn = sprintf('%s/%s_EDDV8_s%d.mat', outDir, pn, s);
    if isfile(fn)
      L = load(fn); igd(s) = L.out.IGD; hv(s) = L.out.HV;
      continue;
    end
    rng(s); alg = EDDV7(N, G, s);   % EDDV8 = EDDV7 file
    [Pop, Res] = alg.run(prob);
    [fno,~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fno==1);
    if isempty(nd), nd = 1:size(Pop.objs,1); end
    F = Pop.objs(nd,:);
    out.IGD = IGD(F, PF); out.HV = HV(F, ref); out.nFE = Res.nFE; out.PPS = numel(nd);
    save(fn, 'out', '-v7.3');
    igd(s) = out.IGD; hv(s) = out.HV;
  end
  fprintf('%-8s IGD med=%.4g HV med=%.4g\n', pn, median(igd), median(hv));
end
fprintf('DONE cf_eddv8\n');
