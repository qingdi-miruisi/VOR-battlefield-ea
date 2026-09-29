function stats = rank_with_v4()
% 把 HCEAV4 (results/main_v4/) 并入 HCEA (results/main/) 做 IGD/HV Friedman 排名
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('experiments'); addpath('problems'); addpath('problems\wfg_toolbox');
    addpath('algorithms'); addpath('algorithms\utils');
    clear run_statistics wilcoxon_test;

    % 把 main_v4 的文件复制进一个临时合并目录（只读 main 不动）
    merged = fullfile(pwd, 'results', 'merged_v4');
    if ~exist(merged, 'dir'), mkdir(merged); end
    % 复制 HCEA + 全部基线 + HCEAV4
    srcDirs = {'results\main', 'results\main_v4'};
    copied = 0;
    for d = 1:2
        files = dir(fullfile(pwd, srcDirs{d}));
        for i = 1:numel(files)
            if endsWith(files(i).name, '.mat') && ~startsWith(files(i).name, 'stats_')
                dst = fullfile(merged, files(i).name);
                if ~isfile(dst)
                    copyfile(fullfile(files(i).folder, files(i).name), dst);
                    copied = copied + 1;
                end
            end
        end
    end
    fprintf("merged %d .mat files into %s\n", copied, merged);

    sIGD = run_statistics(merged, 'IGD');
    sHV  = run_statistics(merged, 'HV');
    stats.IGD = sIGD;
    stats.HV  = sHV;

    % 输出 V4 vs 全部排名
    algsIGD = sIGD.meta.algs;
    mrIGD = sIGD.meanRank;
    [~, ord] = sort(mrIGD, 'ascend');
    fprintf("\n=== IGD 完整排名（含 HCEAV4）===\n");
    for r = 1:numel(ord)
        fprintf("  %2d. %-10s meanRank=%.3f\n", r, algsIGD{ord(r)}, mrIGD(ord(r)));
    end
    algsHV = sHV.meta.algs;
    mrHV = sHV.meanRank;
    [~, ordH] = sort(mrHV, 'ascend');
    fprintf("\n=== HV 完整排名（含 HCEAV4）===\n");
    for r = 1:numel(ordH)
        fprintf("  %2d. %-10s meanRank=%.3f\n", r, algsHV{ordH(r)}, mrHV(ordH(r)));
    end

    % 定位 HCEAV4
    iV4 = find(strcmp(algsIGD, 'HCEAV4'), 1);
    iHCEA = find(strcmp(algsIGD, 'HCEA'), 1);
    iV2 = find(strcmp(algsIGD, 'HCEAV2'), 1);
    fprintf("\nHCEAV4 IGD meanRank=%.3f | HCEA=%.3f | HCEAV2=%.3f\n", ...
        mrIGD(iV4), mrIGD(iHCEA), mrIGD(iV2));
end
