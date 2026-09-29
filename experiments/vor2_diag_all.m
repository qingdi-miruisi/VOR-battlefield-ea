cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('experiments');
addpath('problems'); addpath('problems\wfg_toolbox');
addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP');
addpath('problems_official\CF'); addpath('problems_official\MW');
addpath('problems_official\DTLZ');
addpath('algorithms'); addpath('algorithms\utils');
clear classes; clear VOR;

fid = fopen('results/vor2_diag_all.txt','w');
probList = {'MaF14','LSMOP6','CF1','DTLZ2_300D','ZDT1','LSMOP1'};
for pi = 1:numel(probList)
    pName = probList{pi};
    switch pName
        case 'MaF14',      prob = OfficialProblem('MaF14', 3, 30);
        case 'LSMOP6',     prob = OfficialProblem('LSMOP6', 3, 300);
        case 'CF1',        prob = OfficialProblem('CF1', 3, 10);
        case 'DTLZ2_300D', prob = DTLZ2_300D_M3();
        case 'ZDT1',       prob = ZDT1(30);
        case 'LSMOP1',     prob = OfficialProblem('LSMOP1', 3, 300);
    end
    PF = prob.ParetoFront(500);
    alg = VOR(100,200,1);
    [Pop, R] = alg.optimize(prob);
    igd = IGD(R.F, PF);
    ig20 = R.igdHistory(20); ig50 = R.igdHistory(50); ig100 = R.igdHistory(100); ig200 = R.igdHistory(200);
    fprintf(fid, '%s s1: IGD=%.4f PPS=%d fast=%d mech=%s IGD@20=%.4f @50=%.4f @100=%.4f @200=%.4f\n', ...
        pName, igd, size(R.F,1), R.fastPath, R.mechanism, ig20, ig50, ig100, ig200);
end
fclose(fid);
disp('diag_all written');
