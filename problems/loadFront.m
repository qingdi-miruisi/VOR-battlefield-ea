function S = loadFront(name, M, D)
% LOADFRONT - fixed pre-generated reference front (problems/fronts/PF_<name>_<M>_<D>.mat)
% Deterministic: seed 2026; 20000 random candidates -> NDSortAll -> 500 subsampled points.
% All algorithms share the identical reference set (academic fairness, reproducible).
base = fileparts(mfilename('fullpath'));
fn = sprintf('PF_%s_%d_%d.mat', name, M, D);
path = fullfile(base, 'fronts', fn);
if ~isfile(path)
    try
        obj = feval(name, M);       % problems whose constructor takes M
        if ismethod(obj, 'Setting')
            obj.Setting();          % 官方 PlatEMO 类：同步 D/M/lower/upper
        end
    catch
        obj = feval(name);          % problems with fixed D/M (no-arg constructor)
        if ismethod(obj, 'Setting')
            obj.Setting();
        end
    end
    rng(2026);
    Nbig = 20000;
    X = rand(Nbig, obj.D) .* (obj.upper - obj.lower) + obj.lower;
    F = obj.CalObj(X);
    nd = NDSortAll(F);
    Fnd = sortrows(F(nd, :));
    if size(Fnd,1) >= 500
        idx = round(linspace(1, size(Fnd,1), 500));
        PF = Fnd(idx, :);
    else
        PF = Fnd;
    end
    S = struct('objs', PF, 'M', obj.M, 'D', obj.D, 'genSeed', 2026, 'nCandidates', Nbig);
    d = fileparts(path);
    if ~exist(d, 'dir'), mkdir(d); end
    save(path, 'S');
else
    load(path, 'S');
end
end