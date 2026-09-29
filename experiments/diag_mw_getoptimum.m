function diag_mw_getoptimum()
% 诊断 MW7/9/10/11/13/14 的官方 GetOptimum 在修复 NDSort(2参) 后是否收敛
% 用官方路径（_platemo_official + problems_official），带超时护栏
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('experiments');
    addpath('algorithms\_platemo_official');
    addpath('problems_official'); addpath('problems_official\MW');
    addpath('problems_official\LSMOP'); addpath('problems_official\UF'); addpath('problems_official\EMO');
    addpath('problems'); addpath('problems\wfg_toolbox');
    clear classes;

    % 确认 NDSort 解析到官方版（varargin 2/3参）
    which NDSort;
    fprintf('NDSort -> %s\n', which('NDSort'));
    which UniformPoint;
    fprintf('UniformPoint -> %s\n', which('UniformPoint'));

    probs = {'MW7','MW9','MW10','MW11','MW13','MW14'};
    for p = 1:numel(probs)
        pn = probs{p};
        offP = feval(pn); offP.Setting();
        fprintf('\n=== %s (M=%d D=%d) GetOptimum(500) ===\n', pn, offP.M, offP.D);
        try
            t0 = tic;
            R = offP.GetOptimum(500);
            el = toc(t0);
            if isempty(R)
                fprintf('  返回空矩阵（无有效点）\n');
            else
                fin = all(isfinite(R(:)));
                fprintf('  点数=%d elap=%.2fs 全finite=%d 范围=[%.4g, %.4g]\n', ...
                    size(R,1), el, fin, min(min(R)), max(max(R)));
            end
        catch err
            fprintf('  FAIL: %s\n', err.message);
            if ~isempty(err.stack) && numel(err.stack) > 1
                fprintf('  位置: %s line %d\n', err.stack{2}.name, err.stack{2}.line);
            end
        end
    end
end
