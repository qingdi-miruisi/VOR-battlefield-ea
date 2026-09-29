function gen_ablation_data()
% GEN_ABLATION_DATA  Compute ablation stats -> ablation_numbers.json + barplot.
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\ablation');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\algorithms\utils');
addpath('D:\harness工作\中国科学：数学(总)\算法\algorithm\problems');

DIR = 'D:\harness工作\中国科学：数学(总)\算法\algorithm\docs\results\ablation\';
S = load([DIR 'raw_ablation.mat']);
IGD = S.IGD; HV = S.HV; names = S.names;
mI = mean(IGD, 3, 'omitnan'); sI = std(IGD, 0, 3, 'omitnan');
mH = mean(HV, 3, 'omitnan');  sH = std(HV, 0, 3, 'omitnan');
bestI = zeros(1,2); bestH = zeros(1,2);
for pidx = 1:2
    [~,o] = min(mI(pidx,:)); bestI(pidx) = o(1);
    [~,o] = max(mH(pidx,:)); bestH(pidx) = o(1);
end
out = struct('names', {names}, 'mI', mI, 'sI', sI, 'mH', mH, 'sH', sH, 'bestI', bestI, 'bestH', bestH);
txt = jsonencode(out);
fid = fopen([DIR 'ablation_numbers.json'], 'w'); fprintf(fid, '%s', txt); fclose(fid);
fprintf('wrote ablation_numbers.json\n');

% console text
labels = {'HCEA (main)', 'HCEA_A1 (tournament mating)', 'HCEA_B1 (HV top-N one-shot)', ...
          'HCEA_C1 (adaptive vectors)', 'HCEA_D1 (0.7G fixed switch)', 'HCEA_D2 (0.5G fixed switch)', ...
          'HCEA_D3 (all-APD)', 'HCEA_D4 (all-SMS)'};
for v = 1:8
    fprintf('%-32s | %.6f +/- %.1e | %.6f | %.6f +/- %.1e | %.6f\n', labels{v}, ...
        mI(1,v), sI(1,v), mH(1,v), mI(2,v), sI(2,v), mH(2,v));
end
fprintf('\nDeltas vs HCEA:\n');
for v = 2:8
    fprintf('%-32s | dIGD1=%+.6f dHV1=%+.6f | dIGD2=%+.6f dHV2=%+.6f\n', labels{v}, ...
        mI(1,v)-mI(1,1), mH(1,v)-mH(1,1), mI(2,v)-mI(2,1), mH(2,v)-mH(2,1));
end

% barplot
groups = {[1 2], [1 3], [1 4], [1 5 6 7 8]};
gname = {'(a) parent selection', '(b) mechanism B', '(c) reference vectors', '(d) switching strategy'};
short = {'HCEA','A1','B1','C1','D1','D2','D3','D4'};
f = figure('Position', [80 80 1500 420], 'Color', 'w');
for g = 1:4
    subplot(1, 4, g); hold on;
    mem = groups{g};
    X = categorical(short(mem), short(mem));
    Y = [mI(1,mem)', mI(2,mem)'];
    b = bar(X, Y);
    b(1).FaceColor = [0.25 0.45 0.75]; b(2).FaceColor = [0.85 0.33 0.33];
    set(gca, 'YScale', 'log');
    title(gname{g}, 'FontSize', 10);
    if g == 1, legend({'ZDT1 IGD', 'DTLZ2 IGD'}, 'Location', 'best'); ylabel('IGD (log)'); end
    grid on;
end
exportgraphics(f, [DIR 'ablation_barplot.png'], 'Resolution', 150);
savefig(f, [DIR 'ablation_barplot.fig']);
close(f);
fprintf('wrote ablation_barplot.png\n');
end
