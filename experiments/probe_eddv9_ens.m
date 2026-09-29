% EDDV9 多内核组合诊断：逐核 IGD（FULL 预算）+ 崩溃定位
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\DTLZ');
addpath('algorithms'); addpath('algorithms\utils');
addpath('algorithms\GDVTSF'); addpath('algorithms\WOF');
addpath('algorithms\FDSEA');
addpath('algorithms\MOEA_IB\WOF'); addpath('algorithms\MOEA_IB\ReMO'); addpath('algorithms\MOEA_IB');
clear classes; clear IGD HV;

tests = {'LSMOP1',3,300,'OfficialProblem'; 'LSMOP2',3,300,'OfficialProblem'; 'LSMOP4',3,300,'OfficialProblem'; 'LSMOP6',3,300,'OfficialProblem'; 'DTLZ2_300D_M3',3,300,'DTLZ2_300D_M3'};
N = 100; G = 200; maxFE = N*(G+1);
kernelList = {'GDVTSF','FDSEA','MOEAIB'};

for t = 1:5
  pn = tests{t,1}; ptype = tests{t,4};
  if strcmp(ptype,'OfficialProblem'), prob = OfficialProblem(pn,3,300); else prob = DTLZ2_300D_M3(); end
  PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
  igdFull = nan(1,3);
  for s = 1:3
    fo = sprintf('results/largescale_extended/GDVTSF/GDVTSF_%s_s%d.mat', pn, s);
    if isfile(fo), L = load(fo); igdFull(s) = L.out.IGD; end
  end
  % DTLZ2 基准：官方 GDVTSF 结果
  if strcmp(pn,'DTLZ2_300D_M3')
    fo2 = 'results/largescale_extended/GDVTSF/GDVTSF_DTLZ2_300D_M3_s1.mat';
    if isfile(fo2), L = load(fo2); igdFull(1) = L.out.IGD; end
  end
  offProb = prob.officialObj;
  igdG = nan(1,3); igdF = nan(1,3); igdM = nan(1,3);
  for s = 1:3
    rng(s);
    for k = 1:3
      kc = kernelList{k};
      offProb.N = N; offProb.maxFE = maxFE; offProb.FE = 0;
      try
        kk = feval(kc, 'save',-1, 'outputFcn', @noop2);
        kk.main(kk, offProb);
        if ~isempty(kk.result)
          PS = kk.result{end,2};
          [fnK,~] = NDSort(PS.objs, PS.cons, 1); ndK = find(fnK==1);
          if isempty(ndK), ndK = 1:size(PS.objs,1); end
          F = PS.objs(ndK,:);
          igdG(s) = IGD(F, PF); igdF(s) = IGD(F, PF); igdM(s) = IGD(F, PF);
          switch k
            case 1, igdG(s) = IGD(F, PF);
            case 2, igdF(s) = IGD(F, PF);
            case 3, igdM(s) = IGD(F, PF);
          end
        end
      catch eK
        m = eK.message;
        fprintf('%s s%d %s FAIL: %s\n', pn, s, kc, m(1:min(60,numel(m))));
      end
    end
  end
  fprintf('%-16s GDVTSF基准=%.4g | FULL逐核 IGD med: GDVTSF=%.4g FDSEA=%.4g MOEAIB=%.4g\n', ...
      pn, median(igdFull), median(igdG), median(igdF), median(igdM));
end

function noop2(a,b)
end
