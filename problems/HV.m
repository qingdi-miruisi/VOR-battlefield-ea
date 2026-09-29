function val = HV(F, refPoint)
% HV - 超体积指标（最小化假设；refPoint 为逐目标参考点向量 [1 x M]）
% M = 2 精确计算；M >= 3 蒙特卡洛估算（固定种子，可复现）。
M = size(F, 2);
if any(refPoint <= 0), val = 0; return; end   % 参考点某维退化（PF 该维最大<=0），HV 无定义，合法返回 0
F = F(all(F <= refPoint, 2), :);
F = F(all(F >= 0, 2), :);
if isempty(F)
    val = 0; return;
end
if M == 2
    F = sortrows(F, 1);
    x = [F(:,1); refPoint(1)];
    hv = 0; ymin = refPoint(2);
    for i = 1:size(F,1)
        if F(i,2) < ymin
            ymin = F(i,2);
        end
        hv = hv + (x(i+1) - x(i)) * (refPoint(2) - ymin);
    end
    val = hv;
else
    rng(2026);
    nSample = 2000;
    Fmin = min(F, [], 1);
    S = unifrnd(repmat(Fmin, nSample, 1), repmat(refPoint, nSample, 1));
    % S(s,j) 被 F(i,:) 支配？
    val = 0;
    % 简化：每样本数被任何解支配的样本数（union 体积 = 样本中至少被一个解支配的比例 * 总框体积）
    dominated = false(1, nSample);
    for i = 1:size(F,1)
        dominated = dominated | (all(repmat(F(i,:), nSample, 1) <= S, 2));
    end
    totalVol = prod(refPoint - min([Fmin; refPoint]));
    val = sum(dominated) / nSample * totalVol;
    val = val(1);   % 强制标量
end
end
