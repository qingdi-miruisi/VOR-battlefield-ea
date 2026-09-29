% CF10 EDDV8 30-seed 分布诊断
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('results');
igds = nan(1,30);
for s = 1:30
    fn = sprintf('results\cf_eddv8\CF10_EDDV8_s%d.mat', s);
    if isfile(fn), L = load(fn); igds(s) = L.out.IGD; end
end
igds = igds(~isnan(igds));
fprintf('CF10 EDDV8 30-seed IGD:\n');
fprintf('median=%.4g mean=%.4g min=%.4g max=%.4g std=%.4g\n', median(igds), mean(igds), min(igds), max(igds), std(igds));
fprintf('values: ');
fprintf('%.3f ', igds);
fprintf('\n');
nBad = sum(igds > 10);
fprintf('seeds with IGD>10: %d/30\n', nBad);
% PPS
ppss = nan(1,30);
for s = 1:30
    fn = sprintf('results\cf_eddv8\CF10_EDDV8_s%d.mat', s);
    if isfile(fn), L = load(fn); ppss(s) = L.out.PPS; end
end
ppss = ppss(~isnan(ppss));
fprintf('PPS median=%.1f min=%.1f max=%.1f\n', median(ppss), min(ppss), max(ppss));
