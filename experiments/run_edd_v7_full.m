% EDDV7 全量 30 seeds：LSMOP1-9 + DTLZ2_300D_M3（M=3 D=300）
% 数据落盘 results/largescale_edd_v7/<PN>_EDDV7_s<k>.mat（断点续跑）
% 跑完自动对比 旧EDD / FDSEA / GDVTSF / MOEA-IB 的中位 IGD/HV
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear IGD HV;

probNames = cell(0); probObjs = cell(0);
for i = 1:9
    pn = ['LSMOP' num2str(i)];
    probNames{end+1} = pn;
    probObjs{end+1} = OfficialProblem(pn, 3, 300);
end
probNames{end+1} = 'DTLZ2_300D_M3';
probObjs{end+1} = DTLZ2_300D_M3();

nP = numel(probNames);
outDir = 'results\largascale_edd_v7';
if ~isdir(outDir), mkdir(outDir); end

% 对比数据目录
oldDir = 'results\largescale_final\EDD';
sotaDirs = {'results\largescale_extended\FDSEA','results\largescale_extended\GDVTSF','results\largescale_extended\MOEA-IB'};
sotaNames = {'FDSEA','GDVTSF','MOEA-IB'};

t0 = tic;
for p = 1:nP
    pn = probNames{p}; prob = probObjs{p};
    PF = prob.ParetoFront(500); ref = prob.setRefPoint(PF).refPoint;
    igdV7 = nan(1,30); hvV7 = nan(1,30);
    done = 0;
    for s = 1:30
        fn = fullfile(outDir, [pn '_EDDV7_s' num2str(s) '.mat']);
        if isfile(fn)
            L = load(fn); igdV7(s)=L.out.IGD; hvV7(s)=L.out.HV; done=done+1; continue;
        end
        rng(s); alg = EDDV7(100, 200, s);
        [Pop, Res] = alg.run(prob);
        [fn2, ~] = NDSort(Pop.objs, Pop.cons, 1); nd = find(fn2==1);
        if isempty(nd), nd = 1:size(Pop.objs,1); end
        F = Pop.objs(nd,:);
        out.IGD = IGD(F, PF); out.HV = HV(F, ref); out.nFE = Res.nFE; out.PPS = numel(nd);
        save(fn, 'out', '-v7.3');
        igdV7(s)=out.IGD; hvV7(s)=out.HV; done=done+1;
    end
    igdMed = median(igdV7(~isnan(igdV7))); hvMed = median(hvV7(~isnan(hvV7)));
    % 对比旧 EDD
    igdOld = nan(1,30); hvOld = nan(1,30);
    for s = 1:30
        fo = fullfile(oldDir, [pn '_EDD_s' num2str(s) '.mat']);
        if isfile(fo), Lo = load(fo); igdOld(s)=Lo.out.IGD; hvOld(s)=Lo.out.HV; end
    end
    cmp = sprintf('  旧EDD IGD=%.4g HV=%.4g', median(igdOld), median(hvOld));
    % SOTA 对比
    sotaStr = '';
    for a = 1:3
        fa = fullfile(sotaDirs{a}, [pn '_' sotaNames{a} '_s1.mat']);
        if ~isfile(fa), fa = fullfile(sotaDirs{a}, [sotaNames{a} '_' pn '_s1.mat']); end
        if isfile(fa)
            La = load(fa);
            sotaStr = [sotaStr sprintf('  %s IGD=%.4g HV=%.4g', sotaNames{a}, La.out.IGD, La.out.HV)];
        end
    end
    fprintf('%s V7 IGD=%.4g HV=%.4g |%s%s\n', pn, igdMed, hvMed, cmp, sotaStr);
end
fprintf('=== EDDV7 LSMOP 全量 30 seeds 完成，耗时 %.1f min ===\n', toc(t0)/60);
