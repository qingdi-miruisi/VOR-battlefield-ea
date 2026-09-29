function [problems, names] = extProbs()
    % 扩展 M>=3 标准测试集（七大系列，M=3/5/8 全覆盖，>=60 问题）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;

    % 1) 核心 29 M>=3（经 OfficialProblem）
    coreNames = {'MaF7','MaF8','MaF9','MaF10','MaF11','MaF12','MaF13','MaF14','MaF15','LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9','EMO1','EMO2','EMO3','EMO4','EMO5','EMO6','EMO7','EMO8','EMO9','EMO10','EMO11'};
    coreProbs = cell(0);
    for i = 1:numel(coreNames)
        coreProbs{i} = OfficialProblem(coreNames{i});
    end

    % 2) DTLZ1-7 M=3/5/8（本地 problems/ 类直接构造，官方 PlatEMO 公式）
    extNames = {}; extProbs = cell(0);
    for Mv = [3 5 8]
        for i = 1:7
            extNames{end+1} = sprintf('DTLZ%d_M%d', i, Mv);
            p = eval(['DTLZ' num2str(i) '(' num2str(Mv) ')']);
            extProbs{end+1} = p;
        end
    end
    % 3) WFG1-9 M=3/5/8（本地 problems/ 类直接构造）
    for Mv = [3 5 8]
        for i = 1:9
            extNames{end+1} = sprintf('WFG%d_M%d', i, Mv);
            p = eval(['WFG' num2str(i) '(' num2str(Mv) ')']);
            extProbs{end+1} = p;
        end
    end
    % 4) UF8-10 M=3（PlatEMOAdapter 桥接 GetPF 接口）
    for i = 8:10
        extNames{end+1} = sprintf('UF%d_M3', i);
        p = PlatEMOAdapter(sprintf('UF%d', i), 3);
        extProbs{end+1} = p;
    end
    % 5) CF8-10 M=3（约束问题，PlatEMO 官方类用 Evaluation 而非 CalObj，接口不匹配无约束算法族；
    %    本轮移除，记录到 docs/CRT_STRENGTHEN_PLAN.md limitations，测试集仍 6 系列 77 问题 >60）

    problems = [coreProbs, extProbs];
    names = [coreNames, extNames];
end