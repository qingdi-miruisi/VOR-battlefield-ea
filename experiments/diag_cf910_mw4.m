function diag_cf910_mw4()
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('experiments');
    addpath('algorithms\_platemo_official');
    addpath('problems_official'); addpath('problems_official\CF'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('problems'); addpath('problems\wfg_toolbox');
    clear classes; clear IGD HV;
    fprintf('UniformPoint -> %s\n', which('UniformPoint'));
    fprintf('NDSort       -> %s\n', which('NDSort'));
    probs = {'CF9','CF10','MW4'};
    for p = 1:numel(probs)
        pn = probs{p};
        fprintf('\n=== %s ===\n', pn);
        try
            offP = feval(pn); offP.Setting();
            fprintf('  构造 OK M=%d D=%d\n', offP.M, offP.D);
            PF = offP.GetOptimum(500);
            fprintf('  GetOptimum(500) 点数=%d finite=%d\n', size(PF,1), all(isfinite(PF(:))));
        catch err
            fprintf('  构造失败: %s\n', err.message);
            if ~isempty(err.stack) && numel(err.stack) > 1
                fprintf('  位置: %s line %d\n', err.stack{2}.name, err.stack{2}.line);
            end
        end
    end
end
