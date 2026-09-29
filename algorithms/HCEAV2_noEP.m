classdef HCEAV2_noEP < HCEAV2
% HCEAV2_noEP - 消融变体：关闭端点保护 APD（创新 1 移除）
% 其余机制（收敛感知切换 + 末端多解搜索）与 HCEAV2 完全相同。
% 用于证明端点保护对无界/凹前沿问题的贡献。

    methods
        function Pop = apdGeneration(obj, Problem, Pop, N, M, theta)
            % 忠实 HCEA 原版 APD（无端点保护）
            V = obj.V;
            NV = size(V, 1);
            nCur = size(Pop.objs, 1);

            mp = randi(nCur, 1, N);
            O1 = struct();
            O1.decs = OperatorGA(Problem, Pop.decs(mp, :));
            O1.objs = Problem.CalObj(O1.decs);
            O1.cons = Problem.CalCon(O1.decs);

            M1 = struct();
            M1.decs = [Pop.decs; O1.decs];
            M1.objs = [Pop.objs; O1.objs];
            M1.cons = [Pop.cons; O1.cons];
            nAll = size(M1.objs, 1);

            PopObj = M1.objs - repmat(min(M1.objs,[],1), nAll, 1);
            gamma = min(1 - pdist2(V, V, 'cosine'), [], 2);
            gamma = gamma(:);
            gamma(gamma < 1e-12 | isnan(gamma)) = 1e-6;
            Angle = acos(max(-1, min(1, 1 - pdist2(PopObj, V, 'cosine'))));
            [dmin, assoc] = min(Angle, [], 2);
            APD = (1 + M * theta * dmin ./ gamma(assoc)) .* sqrt(sum(PopObj.^2, 2));

            Keep = false(nAll, 1);
            for i = 1:NV
                cand = find(assoc == i);
                if ~isempty(cand)
                    [~, ii] = min(APD(cand));
                    Keep(cand(ii)) = true;
                end
            end

            idx = find(Keep);
            target = min(N, nAll);
            if numel(idx) < target
                rest = find(~Keep);
                [~, ord] = sort(APD(rest));
                need = target - numel(idx);
                add = rest(ord(1 : min(need, numel(rest))));
                idx = [idx; add];
            end
            idx = idx(1:target);
            Pop.decs = M1.decs(idx, :);
            Pop.objs = M1.objs(idx, :);
            Pop.cons = M1.cons(idx, :);
        end
    end
end
