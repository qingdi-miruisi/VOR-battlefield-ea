function gap_analysis()
    % EDD vs RVEA/SPEA2 逐题 gap 分析（稳健版：全部 11 算法齐的列才入交集）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils');
    addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    [problems, names] = extProbs();
    algsAll = {'NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD','HCEA','HCEAV4','EDD'};
    nA = numel(algsAll); nP = numel(names);
    igdTbl = nan(nA, nP);
    for a = 1:nA
        an = algsAll{a};
        for p = 1:nP
            if strcmp(an,'EDD')
                f = dir(fullfile('results\new_algo_v12', ['EDD_' names{p} '_s*.mat']));
            elseif strcmp(an,'HCEA') || strcmp(an,'HCEAV4')
                f = dir(fullfile('results\new_algo', [an '_' names{p} '_s*.mat']));
            else
                f = dir(fullfile('results\baselines_ext', [an '_' names{p} '_s*.mat']));
            end
            if numel(f) < 30, continue; end
            igdS = zeros(1, numel(f)); ok = true;
            for k = 1:numel(f)
                try
                    L = load(fullfile(f(k).folder, f(k).name));
                    igdS(k) = L.out.IGD;
                catch
                    ok = false; break;
                end
            end
            if ~ok, continue; end
            igdTbl(a, p) = median(igdS);
        end
    end
    validCols = ~any(isnan(igdTbl),1);
    eIdx = find(strcmp(algsAll,'EDD')); rIdx = find(strcmp(algsAll,'RVEA')); sIdx = find(strcmp(algsAll,'SPEA2'));
    nValid = numel(validCols);
    gapR = nan(nValid,1); gapS = nan(nValid,1);
    for j = 1:nValid
        p = validCols(j);
        gapR(j) = igdTbl(eIdx,p) - igdTbl(rIdx,p);
        gapS(j) = igdTbl(eIdx,p) - igdTbl(sIdx,p);
    end
    [~, ordR] = sort(gapR, 'descend');
    fprintf('EDD vs RVEA IGD 落后最大的 15 题（%d 题交集）:\n', nValid);
    for k = 1:min(15, nValid)
        j = ordR(k); p = validCols(j);
        fprintf('  %-12s EDD=%.4g RVEA=%.4g gap=%+.4g\n', names{p}, igdTbl(eIdx,p), igdTbl(rIdx,p), gapR(j));
    end
    [~, ordS] = sort(gapS, 'descend');
    fprintf('\nEDD vs SPEA2 IGD 落后最大的 10 题:\n');
    for k = 1:min(10, nValid)
        j = ordS(k); p = validCols(j);
        fprintf('  %-12s EDD=%.4g SPEA2=%.4g gap=%+.4g\n', names{p}, igdTbl(eIdx,p), igdTbl(sIdx,p), gapS(j));
    end
    fprintf('\nEDD 输 RVEA 的题数: %d/%d，赢: %d\n', sum(gapR>0.01), nValid, sum(gapR<-0.01));
    fprintf('EDD 输 SPEA2 的题数: %d/%d，赢: %d\n', sum(gapS>0.01), nValid, sum(gapS<-0.01));
end
