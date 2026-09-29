% batch_run_main - 后台批处理入口（无界面）
% 用法：matlab -batch "cd(root); addpath('experiments'); batch_run_main"
% 增量落盘：run_main 会跳过 results/main/ 下已有 .mat，可分批调用。

root = 'D:\harness工作\中国科学：数学(总)\算法\algorithm';
cd(root);
if ~exist('experiments', 'dir'), mkdir('experiments'); end
addpath(fullfile(root, 'experiments'));
addpath(fullfile(root, 'problems'));
addpath(fullfile(root, 'problems', 'wfg_toolbox'));
addpath(fullfile(root, 'algorithms'));
addpath(fullfile(root, 'algorithms', 'utils'));

try
    % 分 5 批，每批 6~7 个问题（1 批 ≈ 1800 次运行）
    for batch = 1:5
        p1 = 1 + (batch-1)*6;
        p2 = min(33, p1 + 5);
        fprintf('--- batch %d: problems %d-%d ---\n', batch, p1, p2);
        run_main(p1, p2);
        nMat = length(dir(fullfile(root, 'results', 'main', '*.mat')));
        fprintf('batch %d done, total .mat = %d\n', batch, nMat);
    end
    fprintf('batch_run_main finished\n');
catch ME
    fprintf('ERROR: %s\n%s\n', ME.message, ME.stack);
end
