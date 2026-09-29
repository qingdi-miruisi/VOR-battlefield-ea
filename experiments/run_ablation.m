function run_ablation(startP, endP, nSeeds)
% RUN_ABLATION - 消融实验：HCEAV2 关闭各项创新
% 消融变体（通过环境变量/参数控制）：
%   HCEA_V2_full      - 完整 HCEAV2（对照）
%   HCEA_V2_noEP      - 关闭端点保护 APD（创新 1）
%   HCEA_V2_noPolish  - 关闭末端多解搜索（创新 2）
%   HCEA_V2_origSwitch- 使用 HCEA 原始 3 检查点切换（创新 3 还原）
%
% 实现：直接用 HCEAV2 类但通过属性控制（若类不支持则复制修改版类）
% 当前策略：跑 4 组 × nSeeds 种子 × 核心 6 问题（ZDT1/DTLZ2/DTLZ3/WFG1/WFG2/UF2）

    if nargin < 1, startP = 1; end
    if nargin < 2, endP = 6; end
    if nargin < 3, nSeeds = 10; end

    cd(fileparts(fileparts(mfilename('fullpath'))));  % 到 algorithm/
    addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('algorithms'); addpath('algorithms\utils');

    resDir = fullfile(pwd, 'results', 'ablation');
    if ~exist(resDir, 'dir'), mkdir(resDir); end

    algs = {'HCEA_V2_full','HCEA_V2_noEP','HCEA_V2_noPolish','HCEA_V2_origSwitch'};
    problems = {'ZDT1','DTLZ2','DTLZ3','WFG1','WFG2','UF2'};
    popSize = 100; maxGen = 200;

    for p = 1:numel(problems)
        pname = problems{p};
        prob = feval(pname);
        PF = prob.ParetoFront(500);
        ref = prob.setRefPoint(PF).refPoint;
        for a = 1:numel(algs)
            aname = algs{a};
            for s = 1:nSeeds
                fn = fullfile(resDir, sprintf('%s_%s_s%d.mat', aname, pname, s));
                if isfile(fn), continue; end
                try
                    % 根据消融标签选择不同构造
                    switch aname
                        case 'HCEA_V2_full'
                            alg = HCEAV2(popSize, maxGen, s);
                        case 'HCEA_V2_noEP'
                            alg = HCEAV2_noEP(popSize, maxGen, s);
                        case 'HCEA_V2_noPolish'
                            alg = HCEAV2_noPolish(popSize, maxGen, s);
                        case 'HCEA_V2_origSwitch'
                            alg = HCEAV2_origSwitch(popSize, maxGen, s);
                    end
                    [Pop, Res] = alg.optimize(prob);
                    out.IGD = IGD(Res.F, PF);
                    out.HV  = HV(Res.F, ref);
                    save(fn, 'out', '-v7.3');
                    fprintf('  %s/%s s%d done\n', aname, pname, s);
                catch ME
                    fprintf('  FAIL %s/%s s%d: %s\n', aname, pname, s, ME.message);
                end
            end
        end
    end
end
