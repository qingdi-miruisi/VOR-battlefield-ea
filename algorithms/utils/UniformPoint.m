function [W,N] = UniformPoint(N,M,method)
% UniformPoint - 在单位超平面上生成约 N 个均匀分布的参考点
%
%   [W,N] = UniformPoint(N,M)         NBI（默认，忠实移植自 PlatEMO）
%   [W,N] = UniformPoint(N,M,'grid')  网格采样
%   W = UniformPoint(N,M,'MUD')       混合均匀设计

    if nargin < 3
        method = 'NBI';
    end
    [W,N] = feval(method,N,M);
end

function [W,N] = NBI(N,M)
    H1 = 1;
    while nchoosek(H1+M,M-1) <= N
        H1 = H1 + 1;
    end
    W = nchoosek(1:H1+M-1,M-1) - repmat(0:M-2,nchoosek(H1+M-1,M-1),1) - 1;
    W = ([W,zeros(size(W,1),1)+H1]-[zeros(size(W,1),1),W])/H1;
    if H1 < M
        H2 = 0;
        while nchoosek(H1+M-1,M-1)+nchoosek(H2+M,M-1) <= N
            H2 = H2 + 1;
        end
        if H2 > 0
            W2 = nchoosek(1:H2+M-1,M-1) - repmat(0:M-2,nchoosek(H2+M-1,M-1),1) - 1;
            W2 = ([W2,zeros(size(W2,1),1)+H2]-[zeros(size(W2,1),1),W2])/H2;
            W  = [W;W2/2+1/(2*M)];
        end
    end
    W = max(W,1e-6);
    N = size(W,1);
end

function [W,N] = grid(N,M)
    gap = linspace(0,1,ceil(N^(1/M)));
    eval(sprintf('[%s]=ndgrid(gap);',sprintf('c%d,',1:M)))
    eval(sprintf('W=[%s];',sprintf('c%d(:),',1:M)))
    N = size(W,1);
end

function W = MUD(N,M)
    X = GoodLatticePoint(N,M-1).^(1./repmat(M-1:-1:1,N,1));
    X = max(X,1e-6);
    W = zeros(N,M);
    W(:,1:end-1) = (1-X).*cumprod(X,2)./X;
    W(:,end)     = prod(X,2);
end

function Data = GoodLatticePoint(N,M)
    hm           = find(gcd(1:N,N)==1);
    udt          = mod((1:N)'*hm,N);
    udt(udt==0)  = N;
    nCombination = nchoosek(length(hm),M);
    if nCombination < 1e4
        Combination = nchoosek(1:length(hm),M);
        CD2 = zeros(nCombination,1);
        for i = 1 : nCombination
            UT     = udt(:,Combination(i,:));
            CD2(i) = CalCD2(UT);
        end
        [~,minIndex] = min(CD2);
        Data = udt(:,Combination(minIndex,:));
    else
        CD2 = zeros(N,1);
        for i = 1 : N
            UT     = mod((1:N)'*i.^(0:M-1),N);
            CD2(i) = CalCD2(UT);
        end
        [~,minIndex] = min(CD2);
        Data = mod((1:N)'*minIndex.^(0:M-1),N);
        Data(Data==0) = N;
    end
    Data = (Data-1)/(N-1);
end

function CD2 = CalCD2(UT)
    [N,S] = size(UT);
    X     = (2*UT-1)/(2*N);
    CS1 = sum(prod(2+abs(X-1/2)-(X-1/2).^2,2));
    CS2 = zeros(N,1);
    for i = 1 : N
        CS2(i) = sum(prod((1+1/2*abs(repmat(X(i,:),N,1)-1/2)+1/2*abs(X-1/2)-...
            1/2*abs(repmat(X(i,:),N,1)-X)),2));
    end
    CS2 = sum(CS2);
    CD2 = (13/12)^S-2^(1-S)/N*CS1+1/(N^2)*CS2;
end
