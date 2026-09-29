function smoke_cf1_calobj_diag()
% 诊断 CF1 官方类 CalObj 的返回维度（M=2 时是否折叠成列向量）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    wrap = OfficialProblem('CF1', 2, 10);
    X0 = wrap.lower + rand(1, wrap.D) .* (wrap.upper - wrap.lower);
    F = wrap.CalObj(X0);
    fprintf('CF1 CalObj 返回 size = [%d x %d]（M 应为 2）\n', size(F,1), size(F,2));
    % 直接看官方类
    off = feval('CF1');
    off.Setting();
    X1 = rand(1, off.D);
    Pop = off.Evaluation(X1);
    fprintf('CF1 官方 Evaluation 返回：\n');
    if isstruct(Pop)
        fprintf('  Pop.decs=[%d x %d]  Pop.objs=[%d x %d]  Pop.cons=[%d x %d]\n', ...
            size(Pop.decs,1), size(Pop.decs,2), ...
            size(Pop.objs,1), size(Pop.objs,2), ...
            size(Pop.cons,1), size(Pop.cons,2));
    elseif isa(Pop, 'SOLUTION')
        fprintf('  Pop.decs=[%d x %d]  Pop.objs=[%d x %d]  Pop.cons=[%d x %d]\n', ...
            size(Pop.decs,1), size(Pop.decs,2), ...
            size(Pop.objs,1), size(Pop.objs,2), ...
            size(Pop.cons,1), size(Pop.cons,2));
    end
end
