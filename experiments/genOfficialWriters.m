function genOfficialWriters()
% 从官方 PlatEMO 源文件生成 OfficialProblem 薄包装子类。
% 官方核心公式（Setting/CalObj/GetOptimum/GetPF + 尾部 local functions）原样保留；
% 仅：classdef 父类改 OfficialProblem；官方 CalObj/GetOptimum/GetPF 改名为
% ...Direct（避免与桥接层同名冲突）。
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    officialRoot = '_tmp_official\PlatEMO-master\PlatEMO\Problems\Multi-objective optimization';
    outDir = 'problems';
    nDone = 0; nSkip = 0;
    for famName = {'UF', 'MaF', 'LSMOP'}
        fn = famName{1};
        if strcmp(fn, 'UF'),    idxs = 1:10; end
        if strcmp(fn, 'MaF'),   idxs = 1:15; end
        if strcmp(fn, 'LSMOP'), idxs = 1:9;  end
        offDir = fullfile(officialRoot, fn);
        for i = idxs
            pName = [fn num2str(i)];
            offFile = fullfile(offDir, [pName '.m']);
            if ~isfile(offFile)
                fprintf('SKIP %s (official file missing)\n', pName);
                nSkip = nSkip + 1;
                continue;
            end
            txt = fileread(offFile);
            txt = strrep(txt, char(13), '');
            txt = strrep(txt, char(9), '    ');
            lines = strsplit(txt, newline);
            out = {};
            out{end+1} = ['classdef ' pName ' < OfficialProblem'];
            out{end+1} = ['% ' pName ' - PlatEMO official formula (bridged via OfficialProblem)'];
            out{end+1} = '% Core CalObj/GetOptimum/local functions copied VERBATIM from official source;';
            out{end+1} = '% official CalObj/GetOptimum/GetPF renamed to ...Direct to avoid bridge-layer collision.';
            out{end+1} = '';
            out{end+1} = '    methods';
            out{end+1} = ['        function obj = ' pName '()'];
            out{end+1} = ['            obj@OfficialProblem(''' pName ''');'];
            out{end+1} = '        end';
            skipPropBlock = false;
            for li = 1:numel(lines)
                L = lines{li};
                Ls = strtrim(L);
                % 跳过官方 classdef 头、注释、methods 声明
                if startsWith(Ls, 'classdef') || startsWith(Ls, '%') || strcmp(Ls, 'methods')
                    continue;
                end
                % properties 块（官方 private properties 由 OfficialProblem 基类统一声明）
                if startsWith(Ls, 'properties')
                    skipPropBlock = true;
                    continue;
                end
                if skipPropBlock
                    if strcmp(Ls, 'end')
                        skipPropBlock = false;
                    end
                    continue;
                end
                % 方法体原样保留（公式零改动），统一 8 空格缩进
                % 方法改名：CalObj→CalObjDirect, GetOptimum→GetOptimumDirect, GetPF→GetPFDirect
                if startsWith(Ls, 'function')
                    L = regexprep(L, 'function (\w+) = CalObj\(', 'function $1 = CalObjDirect(');
                    L = regexprep(L, 'function (\w+) = GetOptimum\(', 'function $1 = GetOptimumDirect(');
                    L = regexprep(L, 'function (\w+) = GetPF\(', 'function $1 = GetPFDirect(');
                end
                % 类内交叉调用同步改名（官方 GetPF 调 obj.GetOptimum(100) 等）
                L = regexprep(L, '\.GetOptimum\s*\(', '.GetOptimumDirect(');
                L = regexprep(L, '\.GetPF\s*\(', '.GetPFDirect(');
                L = regexprep(L, '\.CalObj\s*\(', '.CalObjDirect(');
                if ~isempty(Ls)
                    out{end+1} = ['        ' Ls];
                end
            end
            out{end+1} = '    end';
            out{end+1} = 'end';
            % 尾部 local functions（官方 Sphere/Rosenbrock/Griewank/Rastrigin/hY/Points 等，原样保留）
            inLocal = false;
            localOut = {};
            for li = 1:numel(lines)
                L = lines{li};
                if startsWith(L, 'function') && L(1) ~= ' ' && L(1) ~= '%'
                    inLocal = true;
                end
                if inLocal
                    localOut{end+1} = L;
                end
            end
            if ~isempty(localOut)
                out{end+1} = '';
                for loi = 1:numel(localOut)
                    out{end+1} = localOut{loi};
                end
            end
            outText = strjoin(out, char(10));
            dst = fullfile(outDir, [pName '.m']);
            fid = fopen(dst, 'w');
            fwrite(fid, outText);
            fclose(fid);
            nDone = nDone + 1;
        end
    end
    fprintf('genOfficialWriters: %d written, %d skipped\n', nDone, nSkip);
end
