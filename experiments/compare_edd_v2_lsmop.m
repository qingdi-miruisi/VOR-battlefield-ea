function compare_edd_v2_lsmop()
% 阶段3.3 对照：EDDV2 vs 旧EDD（LSMOP1-3 × 30种子）
% EDDV2 数据已存 results/largescale_edd_v2/；旧 EDD 用 results/new_algo_v12/
% 全程局部函数自含 addpath，避免 clear classes 清掉工作区变量
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');

    igdV1 = loadV2IGD('LSMOP1'); hvV1 = loadV2HV('LSMOP1');
    igdV2 = loadV2IGD('LSMOP2'); hvV2 = loadV2HV('LSMOP2');
    igdV3 = loadV2IGD('LSMOP3'); hvV3 = loadV2HV('LSMOP3');

    igdO1 = loadOldIGD('LSMOP1'); hvO1 = loadOldHV('LSMOP1');
    igdO2 = loadOldIGD('LSMOP2'); hvO2 = loadOldHV('LSMOP2');
    igdO3 = loadOldIGD('LSMOP3'); hvO3 = loadOldHV('LSMOP3');

    mV1 = median(igdV1); mO1 = median(igdO1);
    mV2 = median(igdV2); mO2 = median(igdO2);
    mV3 = median(igdV3); mO3 = median(igdO3);
    hvV1m = median(hvV1); hvO1m = median(hvO1);
    hvV2m = median(hvV2); hvO2m = median(hvO2);
    hvV3m = median(hvV3); hvO3m = median(hvO3);

    fprintf('=== LSMOP1: EDDV2 IGD中位=%.4f vs 旧EDD IGD中位=%.4f (%.1f%%)  HV %.4f->%.4f ===\n', ...
        mV1, mO1, (mO1-mV1)/mO1*100, hvO1m, hvV1m);
    w1 = sum(igdV1<igdO1); l1 = sum(igdV1>igdO1);
    fprintf('  胜负 EDDV2<旧EDD: %d,  旧EDD<EDDV2: %d,  平: %d\n', w1, l1, 30-w1-l1);

    fprintf('\n=== LSMOP2: EDDV2 IGD中位=%.4f vs 旧EDD IGD中位=%.4f (%.1f%%)  HV %.4f->%.4f ===\n', ...
        mV2, mO2, (mO2-mV2)/mO2*100, hvO2m, hvV2m);
    w2 = sum(igdV2<igdO2); l2 = sum(igdV2>igdO2);
    fprintf('  胜负 EDDV2<旧EDD: %d,  旧EDD<EDDV2: %d,  平: %d\n', w2, l2, 30-w2-l2);

    fprintf('\n=== LSMOP3: EDDV2 IGD中位=%.4f vs 旧EDD IGD中位=%.4f (%.1f%%)  HV %.4f->%.4f ===\n', ...
        mV3, mO3, (mO3-mV3)/mO3*100, hvO3m, hvV3m);
    w3 = sum(igdV3<igdO3); l3 = sum(igdV3>igdO3);
    fprintf('  胜负 EDDV2<旧EDD: %d,  旧EDD<EDDV2: %d,  平: %d\n', w3, l3, 30-w3-l3);

    nWin = sum([mV1<mO1, mV2<mO2, mV3<mO3]);
    fprintf('\n总体: LSMOP1-3 EDDV2 IGD中位=[%.4f %.4f %.4f]  旧EDD=[%.4f %.4f %.4f]  EDDV2全胜题数: %d/3\n', ...
        mV1, mV2, mV3, mO1, mO2, mO3, nWin);
end

function [v] = loadV2IGD(pn)
    outDir = 'results\largescale_edd_v2';
    v = zeros(1,30);
    for s = 1:30
        L = load(fullfile(outDir, [pn '_EDDV2_s' num2str(s) '.mat']));
        v(s) = L.out.IGD;
    end
end

function [v] = loadV2HV(pn)
    outDir = 'results\largescale_edd_v2';
    v = zeros(1,30);
    for s = 1:30
        L = load(fullfile(outDir, [pn '_EDDV2_s' num2str(s) '.mat']));
        v(s) = L.out.HV;
    end
end

function [v] = loadOldIGD(pn)
    % 旧 EDD v12 结果（new_algo_v12 目录，命名 EDD_LSMOP1_s1.mat）
    outDir = 'results\new_algo_v12';
    v = zeros(1,30);
    for s = 1:30
        L = load(fullfile(outDir, ['EDD_' pn '_s' num2str(s) '.mat']));
        v(s) = L.out.IGD;
    end
end

function [v] = loadOldHV(pn)
    outDir = 'results\new_algo_v12';
    v = zeros(1,30);
    for s = 1:30
        L = load(fullfile(outDir, ['EDD_' pn '_s' num2str(s) '.mat']));
        v(s) = L.out.HV;
    end
end
