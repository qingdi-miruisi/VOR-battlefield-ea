% 2× 预算快速验证：EDDV8 (N=100 G=400) vs EDDV8 旧预算对比
% 仅跑 EDDV8 本地循环（无 SOTA 类依赖，无 OOM 风险）
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\DTLZ');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear IGD HV;

% 收敛实例 + 困难实例各 2 个
tests = {'LSMOP2',3,300,'OfficialProblem'; 'LSMOP4',3,300,'OfficialProblem';
         'LSMOP8',3,300,'OfficialProblem'; 'DTLZ2_300D_M3',3,300,'DTLZ2_300D_M3'};
N = 100;
for t = 1:4
  pn = tests{t,1}; ptype = tests{t,4};
  if strcmp(ptype,'OfficialProblem'), prob = OfficialProblem(pn,3,300); else prob = DTLZ2_300D_M3(); end
  PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
  for Gx = [200, 400]
    igd = nan(1,3); hv = nan(1,3);
    for s = 1:3
      rng(s);
      alg = EDDV7(N, Gx, s);   % EDDV8 = EDDV7 file current state
      [Pop, Res] = alg.run(prob);
      [fn,~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn==1);
      if isempty(nd), nd = 1:size(Pop.objs,1); end
      F = Pop.objs(nd,:);
      igd(s) = IGD(F, PF); hv(s) = HV(F, ref);
    end
    fprintf('%-16s G=%d IGD med=%.4g HV med=%.4g\n', pn, Gx, median(igd), median(hv));
  end
end
