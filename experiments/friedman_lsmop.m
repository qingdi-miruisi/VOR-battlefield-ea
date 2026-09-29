function friedman_lsmop()
    % LSMOP1-9 Friedman 排名（D=300 M=3，用 baselines_ext + new_algo_v12(EDD) + m3_focus/EDD16）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems\wfg_toolbox');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO');
    addpath('problems_official\UF'); addpath('problems_official\CF');
    addpath('problems_ext');
    clear classes; clear IGD HV;
    probs = OfficialProblem('LSMOP1');
    problems = cell(0); names = cell(0);
    for i = 1:9
        problems{i} = OfficialProblem(['LSMOP' num2str(i)], 3, 300);
        names{i} = ['LSMOP' num2str(i)];
    end
    algs = {'NSGA2','NSGA3','SPEA2','AGEMOEA','SMSEMOA','MOGWO','RVEA','MOEAD','HCEA','HCEAV4','EDD','EDD16'};
    nA = numel(algs); nP = numel(names);
    igdTbl = nan(nA, nP); hvTbl = nan(nA, nP);
    for a = 1:nA
        an = algs{a};
        for p = 1:nP
            pn = names{p};
            if strcmp(an,'EDD')
                f = dir(fullfile('results\new_algo_v12', ['EDD_' pn '_s*.mat']));
            elseif strcmp(an,'EDD16')
                f = dir(fullfile('results\m3_focus\EDD16', ['EDD16_' pn '_s*.mat']));
            elseif strcmp(an,'HCEA') || strcmp(an,'HCEAV4')
                f = dir(fullfile('results\new_algo', [an '_' pn '_s*.mat']));
            else
                f = dir(fullfile('results\baselines_ext', [an '_' pn '_s*.mat']));
            end
            if numel(f) < 30
                fprintf('%s %s: 缺数据 (%d/30)\n', an, pn, numel(f));
                continue;
            end
            igdS = zeros(1, numel(f)); hvS = zeros(1, numel(f));
            for k = 1:numel(f)
                L = load(fullfile(f(k).folder, f(k).name));
                igdS(k) = L.out.IGD; hvS(k) = L.out.HV;
            end
            igdTbl(a, p) = median(igdS); hvTbl(a, p) = median(hvS);
        end
    end
    validCols = ~any(isnan(igdTbl), 1);
    nAvail = sum(validCols);
    fprintf('\nLSMOP1-9 全算法齐的题: %d/9\n', nAvail);
    igdTbl2 = igdTbl(:, validCols); hvTbl2 = hvTbl(:, validCols);
    igdRank = friedmanRank(igdTbl2, nA, nAvail);
    hvRank = friedmanRank(-hvTbl2, nA, nAvail);
    fprintf('\n=== IGD Friedman（LSMOP1-9，12 算法，小=好）===\n');
    [~, iOrd] = sort(igdRank);
    for k = 1:nA
        fprintf('  %-8s 秩=%.3f\n', algs{iOrd(k)}, igdRank(iOrd(k)));
    end
    fprintf('\n=== HV Friedman（LSMOP1-9，12 算法，大=好）===\n');
    [~, hOrd] = sort(hvRank);
    for k = 1:nA
        fprintf('  %-8s 秩=%.3f\n', algs{hOrd(k)}, hvRank(hOrd(k)));
    end
    combined = (igdRank + hvRank)/2;
    [~, cOrd] = sort(combined);
    fprintf('\n=== 综合 ===\n');
    for k = 1:nA
        fprintf('  %-8s 综合=%.3f\n', algs{cOrd(k)}, combined(cOrd(k)));
    end
    %% EDD / EDD16 vs RVEA 逐题 gap
    eIdx = find(strcmp(algs,'EDD')); e16 = find(strcmp(algs,'EDD16')); rIdx = find(strcmp(algs,'RVEA'));
    sIdx = find(strcmp(algs,'SMSEMOA')); gIdx = find(strcmp(algs,'MOGWO'));
    fprintf('\n=== 逐题 IGD（LSMOP1-9）===\n');
    for p = 1:nAvail
        col = validCols; col = col; % logical
        pp = find(col); pidx = pp(p);
        pn = names{pidx};
        fprintf('%-9s EDD=%.4g EDD16=%.4g RVEA=%.4g SMSEMOA=%.4g MOGWO=%.4g\n', ...
            pn, igdTbl(eIdx,pidx), igdTbl(e16,pidx), igdTbl(rIdx,pidx), igdTbl(sIdx,pidx), igdTbl(gIdx,pidx));
    end
    save('results\friedman_lsmop.mat', 'algs','names','igdTbl','hvTbl','igdRank','hvRank');
    fprintf('\nsaved results\friedman_lsmop.mat\n');
end

function rank = friedmanRank(tbl, nA, nP)
    rankTab = zeros(nA, nP);
    for p = 1:nP
        v = tbl(:, p);
        [v, ord] = sort(v);
        r = zeros(numel(v),1);
        i = 1;
        while i <= numel(v)
            j = i;
            while j < numel(v) && v(j) == v(i), j = j+1; end
            r(ord(i:j)) = mean(i:j);
            i = j+1;
        end
        rankTab(:,p) = r;
    end
    rank = mean(rankTab, 2);
end
