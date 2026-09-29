function Offspring = OperatorGAhalf(Problem, ParentDecs, Parameter)
% OperatorGAhalf - 从 K 个父代产生 K/2 个子代（取 SBX 的第一个子代）
% 忠实 PlatEMO OperatorGAhalf
    if nargin > 2
        [proC,disC,proM,disM] = deal(Parameter{:});
    else
        [proC,disC,proM,disM] = deal(1, 20, 1, 20);
    end
    [N,D] = size(ParentDecs);
    Parent1   = ParentDecs(1:floor(N/2), :);
    Parent2   = ParentDecs(floor(N/2)+1:floor(N/2)*2, :);
    n1 = size(Parent1,1);
    lower = Problem.lower; upper = Problem.upper;

    %% SBX crossover
    beta  = zeros(n1,D);
    mu    = rand(n1,D);
    beta(mu<=0.5) = (2*mu(mu<=0.5)).^(1/(disC+1));
    beta(mu>0.5)  = (2-2*mu(mu>0.5)).^(-1/(disC+1));
    beta = beta.*(-1).^randi([0,1],n1,D);
    beta(rand(n1,D)<0.5) = 1;
    beta(repmat(rand(n1,1)>proC,1,D)) = 1;
    Offspring = (Parent1+Parent2)/2 + beta.*(Parent1-Parent2)/2;

    %% Polynomial mutation
    Lower = repmat(lower,n1,1);
    Upper = repmat(upper,n1,1);
    Site  = rand(n1,D) < proM/D;
    mu2   = rand(n1,D);
    Offspring = min(max(Offspring,Lower),Upper);
    temp = Site & (mu2<=0.5);
    Offspring(temp) = Offspring(temp)+(Upper(temp)-Lower(temp)).*...
        ((2.*mu2(temp)+(1-2.*mu2(temp)).*(1-(Offspring(temp)-Lower(temp))./...
         (Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1))-1);
    temp = Site & (mu2>0.5);
    Offspring(temp) = Offspring(temp)+(Upper(temp)-Lower(temp)).*...
        (1-(2.*(1-mu2(temp))+2.*(mu2(temp)-0.5).*...
         (1-(Upper(temp)-Offspring(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1)));
end
