function index = TournamentSelection(K,N,varargin)
% TournamentSelection - K 轮锦标赛选择（忠实移植自 PlatEMO）
%
%   index = TournamentSelection(K,N,fitness1,fitness2,...)
%   每次选择中，按 fitness1 最小选择；若相同则按 fitness2，依此类推

    varargin    = cellfun(@(S)reshape(S,[],1),varargin,'UniformOutput',false);
    [Fit,~,Loc] = unique([varargin{:}],'rows');
    [~,rank]    = sortrows(Fit);
    [~,rank]    = sort(rank);
    Parents     = randi(length(varargin{1}),K,N);
    [~,best]    = min(rank(Loc(Parents)),[],1);
    index       = Parents(best+(0:N-1)*K);
end
