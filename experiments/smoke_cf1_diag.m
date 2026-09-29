function smoke_cf1_diag()
% 诊断 CF1 上 eedGeneration 的 M=2 越界：打印 F/Fmin/eps/gridIdx 维度
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    wrap = OfficialProblem('CF1', 2, 10);
    N = 100; M = wrap.M;
    Pop = wrap.Initialization(N);
    fprintf('M=%d  Pop.objs size = [%d x %d]\n', M, size(Pop.objs,1), size(Pop.objs,2));
    fprintf('Pop.cons size = [%d x %d]\n', size(Pop.cons,1), size(Pop.cons,2));
    F = Pop.objs;
    fprintf('F size = [%d x %d]  M=%d\n', size(F,1), size(F,2), M);
    Fmin = min(F,[],1); Fmax = max(F,[],1);
    width = Fmax - Fmin; width(width==0)=1;
    epsv = width / 10;
    fprintf('Fmin=[%g %g] Fmax=[%g %g] width=[%g %g] eps=[%g %g]\n', ...
        Fmin(1), Fmin(2), Fmax(1), Fmax(2), width(1), width(2), epsv(1), epsv(2));
    nAll = size(F,1);
    gridIdx = zeros(nAll, M);
    for i = 1:nAll
        for j = 1:M
            v = ceil((F(i,j)-Fmin(j)) / epsv(j));
            if isnan(v) || v < 1, v = 1; end
            if v > 10, v = 10; end
            gridIdx(i,j) = v;
        end
    end
    fprintf('gridIdx OK: size=[%d x %d]\n', size(gridIdx,1), size(gridIdx,2));
    [FrontNo, ~] = NDSort(F, Pop.cons, inf);
    nd = find(FrontNo==1);
    fprintf('NDSort OK: front1 = %d 个\n', numel(nd));
end
