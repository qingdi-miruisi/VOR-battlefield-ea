function diag_mw_construct()
% 诊断：MW1-14 哪些题 OfficialProblem 构造会崩（GetOptimum 内 NDSort 冲突）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('algorithms'); addpath('algorithms\utils');
    clear classes; clear IGD HV;

    ok = cell(0,1); fail = cell(0,1);
    for i = 1:14
        pn = ['MW' num2str(i)];
        try
            wrap = OfficialProblem(pn, 2, 15);
            PF = wrap.ParetoFront(500);
            ok{end+1} = [pn ' (PF点数=' num2str(size(PF,1)) ')'];
        catch err
            fail{end+1} = [pn ': ' err.message];
        end
    end
    fprintf('=== 构造成功 %d 题 ===\n', numel(ok));
    fprintf('%s\n', ok{:});
    fprintf('=== 构造失败 %d 题 ===\n', numel(fail));
    fprintf('%s\n', fail{:});
end
