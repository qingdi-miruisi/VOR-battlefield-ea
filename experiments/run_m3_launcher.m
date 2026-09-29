% run_m3_launcher - 启动 3 个独立 MATLAB -batch 进程，各跑一个慢算法 × 35 M=3 问题
% 各进程断点续跑（跳过已有 <ALGO>_<PROB>_s<N>.mat），每 seed 立刻原生 save。
% 用法（主控进程内调用）：
%   cd(root); addpath('experiments'); run_m3_launcher
% 说明：
%   - 每进程跑一个算法 × 35 问题（顺序）；3 进程并行 ≈ 单算法耗时。
%   - 输出日志：results/main/_parallel/<ALGO>_{stdout,stderr}.log
%   - 若某进程已完成，再次调用会自动跳过（断点续跑）。
cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
addpath('experiments');
run_m3_launcher();

function run_m3_launcher()
    root = pwd;
    matlabExe = 'D:\matlab_2026a\bin\matlab.exe';
    if ~isfile(matlabExe)
        matlabExe = 'matlab';   % 退回到 PATH
    end
    parDir = fullfile(root, 'results', 'main', '_parallel');
    if ~exist(parDir, 'dir'), mkdir(parDir); end

    % 慢 3 个（已实测单 run 时长：AGEMOEA~3s、SMSEMOA~5s、MOEAD~1s，× 35 问题 × 30 seed ≈ 数小时）
    algs = {'AGEMOEA','SMSEMOA','MOEAD'};
    addPathStr = ["addpath('" root('\experiments') "'); addpath('" root('\problems') "'); addpath('" root('\problems\wfg_toolbox') "'); addpath('" root('\algorithms') "'); addpath('" root('\algorithms\utils') "'); addpath('" root('\problems_official') "'); addpath('" root('\problems_official\UF') "'); addpath('" root('\problems_official\MaF') "'); addpath('" root('\problems_official\LSMOP') "'); addpath('" root('\problems_official\CF') "'); addpath('" root('\problems_official\ZXH_CF') "'); addpath('" root('\problems_official\EMO') "'); "];
    for k = 1:numel(algs)
        a = algs{k};
        args = strcat( ...
            "-batch \"", addPathStr, "cd('" root "'); ", ...
            "probList=@('MaF1','MaF2','MaF3','MaF4','MaF5','MaF6','MaF7','MaF8','MaF9','MaF10','MaF11','MaF12','MaF13','MaF14','MaF15','LSMOP1','LSMOP2','LSMOP3','LSMOP4','LSMOP5','LSMOP6','LSMOP7','LSMOP8','LSMOP9','EMO1','EMO2','EMO3','EMO4','EMO5','EMO6','EMO7','EMO8','EMO9','EMO10','EMO11'); ", ...
            "resDir='results\main'; popSize=100; maxGen=200; algName='" a "'; t0=tic; nDone=0; nSkip=0; nFail=0; ", ...
            "for p2=1:length(probList) { pname=probList{p2}; prob=OfficialProblem(pname,3,0); PF=prob.ParetoFront(500); ref=prob.setRefPoint(PF).refPoint; ", ...
            "for s=1:30 { seed=s; fn=[resDir,'\'_',algName,'_',pname,'_s',num2str(seed),'.mat']; ", ...
            "if isfile(fn) { nSkip=nSkip+1; continue; end } ", ...
            "try { alg=feval(algName,popSize,maxGen,seed); [Pop,Res]=alg.optimize(prob); ", ...
            "out.IGD=IGD(Res.F,PF); out.HV=HV(Res.F,ref); out.nFE=Res.nFE; out.elap=Res.elap; out.PPS=size(Res.F,1); ", ...
            "save(fn,'out','-v7.3'); nDone=nDone+1; } ", ...
            "catch ME { nFail=nFail+1; fprintf('  FAIL %s %s s%d: %s\n', algName, pname, seed, ME.message); } ", ...
            "fprintf('  [%d/30] %s s%d done=%d skip=%d fail=%d %.0fs\n', s, algName, seed, nDone, nSkip, nFail, toc(t0)); } } ", ...
            "fprintf('DONE ' algName ' done=%d skip=%d fail=%d in %.1f min\n', nDone, nSkip, nFail, toc(t0)/60)\"");
        outLog = fullfile(parDir, [a '_stdout.log']);
        errLog = fullfile(parDir, [a '_stderr.log']);
        cmd = sprintf('"matlab" -nohndash -batch "%s"', args);
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        % 用 cmd 启动子进程（异步，不阻塞）
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        % 真正启动（每次只启动一次）
        Launch = [ matlabExe ' -nohndash -batch ' char('\"') args char('\"') ];
        % 启动到日志
        [status, msg] = system(['(' cmd ' > "' outLog '" 2> "' errLog '" ) &']);
        fprintf('[run_m3_launcher] %s -> PID status=%d msg=%s\n', a, status, msg);
    end
end
