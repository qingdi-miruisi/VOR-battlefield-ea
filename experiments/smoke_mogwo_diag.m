function smoke_mogwo_diag()
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    wrap = OfficialProblem('CF1', 2, 10);
    fprintf('CF1 wrap.M=%d wrap.D=%d\n', wrap.M, wrap.D);
    X0 = wrap.lower + rand(1, wrap.D).*(wrap.upper-wrap.lower);
    F = wrap.CalObj(X0);
    fprintf('CalObj 1解: size=[%d x %d] 值=[%s]\n', size(F,1), size(F,2), mat2str(F,4));
    F2 = wrap.CalObj(wrap.lower + rand(10, wrap.D).*(wrap.upper-wrap.lower));
    fprintf('CalObj 10解: size=[%d x %d]\n', size(F2,1), size(F2,2));
    % MOGWO 期望：Problem.F 返回 [M] 向量（单解）或 [N x M]
    % 灰狼 Cost = Problem.F(Position)  Position=[1 x D] → 期望 [1 x M]
    M = wrap.M;
    fprintf('M=%d: MOGWO 需 Cost 长度=%d\n', M, M);
    % 试 MOGWO 全量
    try
        rng(1); alg = MOGWO(100,200,1);
        [Pop, Res] = alg.run(wrap);
        fprintf('MOGWO CF1 s1 OK: PPS=%d\n', size(Pop.objs,1));
    catch err
        fprintf('MOGWO CF1 s1 FAIL: %s\n', err.message);
        fprintf('堆栈: %s\n', err.stack{1}.name);
    end
end
