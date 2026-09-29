function diag_edd_vs_new()
% diag_edd_vs_new — 阶段3.1：从 .mat 直接读 30 种子，算 per-problem 中位数 IGD/HV + 差距%
% 输出：控制台表 + docs/EDD_IMPROVEMENT_LOG.md 追加诊断表
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    probs = {'LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9'};
    algs  = {'EDD','FDSEA','GDVTSF','MOEA-IB'};
    dirs  = {'results\new_algo_v12', ...
             'results\largescale_extended\FDSEA', ...
             'results\largescale_extended\GDVTSF', ...
             'results\largescale_extended\MOEA-IB'};
    nP = numel(probs); nA = numel(algs);
    I = nan(nA,nP); H = nan(nA,nP);
    for a = 1:nA
        for p = 1:nP
            pre = algs{a};
            f = dir(fullfile(dirs{a}, [pre '_' probs{p} '_s*.mat']));
            if numel(f) < 30
                fprintf('WARN %s %s: 仅 %d 个 .mat\n', algs{a}, probs{p}, numel(f));
                continue;
            end
            ig = zeros(1,numel(f)); hv = zeros(1,numel(f));
            for k = 1:numel(f)
                L = load(fullfile(f(k).folder, f(k).name));
                ig(k) = L.out.IGD; hv(k) = L.out.HV;
            end
            I(a,p) = median(ig); H(a,p) = median(hv);
        end
    end
    iE = 1; iF = 2; iG = 3; iM = 4;
    fprintf('\n=== per-problem IGD 中位数（小=好）===\n');
    fprintf('%-8s', 'prob');
    for a = 1:nA, fprintf('%12s', algs{a}); end
    fprintf('\n');
    for p = 1:nP
        fprintf('%-8s', probs{p});
        for a = 1:nA, fprintf('%12.4f', I(a,p)); end
        fprintf('\n');
    end
    fprintf('\n=== per-problem HV 中位数（大=好）===\n');
    fprintf('%-8s', 'prob');
    for a = 1:nA, fprintf('%12s', algs{a}); end
    fprintf('\n');
    for p = 1:nP
        fprintf('%-8s', probs{p});
        for a = 1:nA, fprintf('%12.4f', H(a,p)); end
        fprintf('\n');
    end
    fprintf('\n=== IGD 差距%（新算法相对 EDD；正=EDD 好，负=新算法好）===\n');
    fprintf('%-8s', 'prob');
    fprintf('%10s%10s%10s\n', 'FDSEA','GDVTSF','MOEAIB');
    dIgdF = zeros(1,nP); dIgdG = zeros(1,nP); dIgdM = zeros(1,nP);
    for p = 1:nP
        dIgdF(p) = (I(iF,p)-I(iE,p))/I(iE,p)*100;
        dIgdG(p) = (I(iG,p)-I(iE,p))/I(iE,p)*100;
        dIgdM(p) = (I(iM,p)-I(iE,p))/I(iE,p)*100;
        fprintf('%-8s %9.1f%% %9.1f%% %9.1f%%\n', probs{p}, dIgdF(p), dIgdG(p), dIgdM(p));
    end
    [mxF, ixMxF] = max(dIgdF);
    fprintf('\nFDSEA 相对 EDD 差距最大题: %s (%.1f%%)\n', probs{ixMxF}, mxF);
    % HV 差距
    dHvF = (H(iF,:)-H(iE,:))./max(H(iE,:),1e-12)*100;
    dHvG = (H(iG,:)-H(iE,:))./max(H(iE,:),1e-12)*100;
    dHvM = (H(iM,:)-H(iE,:))./max(H(iE,:),1e-12)*100;
    fprintf('\n=== HV 差距%（新算法相对 EDD；正=新算法 HV 更大）===\n');
    fprintf('%-8s', 'prob');
    fprintf('%10s%10s%10s\n', 'FDSEA','GDVTSF','MOEAIB');
    for p = 1:nP
        fprintf('%-8s %9.1f%% %9.1f%% %9.1f%%\n', probs{p}, dHvF(p), dHvG(p), dHvM(p));
    end
    % 写 markdown 诊断表到 log
    logPath = 'docs\EDD_IMPROVEMENT_LOG.md';
    if ~isdir('docs'), mkdir('docs'); end
    fid = fopen(logPath, 'a');
    if fid > 0
        fprintf(fid, '\n\n## 阶段3.1 诊断表（LSMOP1-9, 30 种子中位数）\n\n');
        fprintf(fid, '生成时间: %s\n\n', datestr(now));
        fprintf(fid, '### IGD 中位数（小=好）\n\n| prob |');
        for a = 1:nA, fprintf(fid, ' %s |', algs{a}); end
        fprintf(fid, '\n|---|');
        for a = 1:nA, fprintf(fid, '---|'); end
        fprintf(fid, '\n');
        for p = 1:nP
            fprintf(fid, '| %s |', probs{p});
            for a = 1:nA, fprintf(fid, ' %.4f |', I(a,p)); end
            fprintf(fid, '\n');
        end
        fprintf(fid, '\n### HV 中位数（大=好）\n\n| prob |');
        for a = 1:nA, fprintf(fid, ' %s |', algs{a}); end
        fprintf(fid, '\n|---|');
        for a = 1:nA, fprintf(fid, '---|'); end
        fprintf(fid, '\n');
        for p = 1:nP
            fprintf(fid, '| %s |', probs{p});
            for a = 1:nA, fprintf(fid, ' %.4f |', H(a,p)); end
            fprintf(fid, '\n');
        end
        fprintf(fid, '\n### IGD 差距%%（新算法 - EDD；正=EDD 好，负=新算法好）\n\n| prob | FDSEA | GDVTSF | MOEA-IB |\n|---|---|---|---|\n');
        for p = 1:nP
            fprintf(fid, '| %s | %+.1f%% | %+.1f%% | %+.1f%% |\n', probs{p}, dIgdF(p), dIgdG(p), dIgdM(p));
        end
        fclose(fid);
        fprintf('\n诊断表已追加到 %s\n', logPath);
    end
end
