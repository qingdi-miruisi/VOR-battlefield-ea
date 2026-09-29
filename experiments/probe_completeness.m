function probe_completeness()
% 探针：14 算法 × 24 题（CF1-10 + MW1-14）中每列是否有 30 种子（Friedman 全齐列）
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    probs = cell(0,1);
    for i = 1:10, probs{end+1} = ['CF' num2str(i)]; end
    for i = 1:14, probs{end+1} = ['MW' num2str(i)]; end
    algs = {
        'EDD_cf',   'results\cf_edd_cf',            'EDD_cf';
        'NSGA2',    'results\cf_baselines\NSGA2',   'NSGA2';
        'NSGA3',    'results\cf_baselines\NSGA3',   'NSGA3';
        'MOEAD',    'results\cf_baselines\MOEAD',   'MOEAD';
        'SPEA2',    'results\cf_baselines\SPEA2',   'SPEA2';
        'SMSEMOA',  'results\cf_baselines\SMSEMOA', 'SMSEMOA';
        'RVEA',     'results\cf_baselines\RVEA',    'RVEA';
        'AGEMOEA',  'results\cf_baselines\AGEMOEA', 'AGEMOEA';
        'MOGWO',    'results\cf_baselines\MOGWO',   'MOGWO';
        'FDSEA',    'results\cf_sota\FDSEA',        'FDSEA';
        'GDVTSF',   'results\cf_sota\GDVTSF',       'GDVTSF';
        'MOEA-IB',  'results\cf_sota\MOEA-IB',      'MOEA-IB'
    };
    fprintf('14 算法完整性（30 种子 = 全齐）：\n');
    for p = 1:numel(probs)
        pn = probs{p};
        okAll = true; missing = cell(0,1);
        for a = 1:size(algs,1)
            f = dir(fullfile(algs{a,2}, [pn '_' algs{a,1} '_s*.mat']));
            if numel(f) < 30
                okAll = false;
                missing{end+1} = [algs{a,1} '(' num2str(numel(f)) ')'];
            end
        end
        if okAll
            fprintf('  %-6s 全齐\n', pn);
        else
            fprintf('  %-6s 缺: %s\n', pn, strjoin(missing, ', '));
        end
    end
end
