function make_edd_abl()
    % 从 EDD.m（v12 锁定版）生成消融变体 EDD_ABL.m
    %   ablMode = 0 : 完整 EDD（对照）
    %   ablMode = 1 : no-EED    —— D>=100 时强制走 APD/SMS 路径（等价 HCEAV4 路径）
    %   ablMode = 2 : no-DSG    —— 高维路径保留 EED 选择，但用 OperatorGA(SBX) 替换 dsgOperator
    %   ablMode = 3 : no-polish —— 关闭末端 polishHV
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    src = fileread('algorithms\EDD.m');
    t = src;

    % 1. classdef 名
    t = strrep(t, 'classdef EDD < ALGORITHM', 'classdef EDD_ABL < ALGORITHM');

    % 2. 构造函数名 + 新增 ablMode 参数
    t = strrep(t, 'function obj = EDD(popSize, maxGen, seed)', ...
                  'function obj = EDD_ABL(popSize, maxGen, seed, ablMode)');
    t = strrep(t, 'obj@ALGORITHM(popSize, maxGen, seed);', ...
                  sprintf('obj@ALGORITHM(popSize, maxGen, seed);\n            if nargin < 4, ablMode = 0; end\n            obj.ablMode = ablMode;'));

    % 3. 新增 ablMode 属性
    t = strrep(t, 'epsGrid;      % D>=100 epsilon 网格数', ...
                  sprintf('epsGrid;      %% D>=100 epsilon 网格数\n        ablMode;      %% 消融模式 0=full 1=noEED 2=noDSG 3=noPolish'));

    % 4. highDim 门控：ablMode==1 时禁用 EED（强制 APD 路径）
    t = strrep(t, 'highDim = (D >= 100) || (M >= 10);', ...
                  sprintf('highDim = (D >= 100) || (M >= 10);\n            if obj.ablMode == 1, highDim = (M >= 10); end   %% no-EED：D>=100 也走 APD'));

    % 5. 子代算子：ablMode==2 时用 OperatorGA 替换 dsgOperator
    t = strrep(t, 'O1.decs = obj.dsgOperator(Problem, Pop.decs(mp,:));', ...
                  sprintf('if obj.ablMode == 2\n                O1.decs = OperatorGA(Problem, Pop.decs(mp,:));   %% no-DSG：SBX 替换\n            else\n                O1.decs = obj.dsgOperator(Problem, Pop.decs(mp,:));\n            end'));

    % 6. polishHV 门控：ablMode==3 关闭
    t = strrep(t, 'if gen >= polishFrom && mod(gen-polishFrom+1,5)==1', ...
                  'if obj.ablMode ~= 3 && gen >= polishFrom && mod(gen-polishFrom+1,5)==1');

    fid = fopen('algorithms\EDD_ABL.m', 'w', 'n', 'UTF-8');
    fwrite(fid, t, 'char'); fclose(fid);

    % 校验 6 处替换是否都生效
    checks = {'classdef EDD_ABL', 'function obj = EDD_ABL(popSize, maxGen, seed, ablMode)', ...
              'obj.ablMode = ablMode;', 'ablMode;      % 消融模式', ...
              'if obj.ablMode == 1, highDim', 'if obj.ablMode == 2', 'if obj.ablMode ~= 3 && gen >= polishFrom'};
    fprintf('校验（应全部为 1）:\n');
    for i = 1:numel(checks)
        fprintf('  %-55s %.0f\n', checks{i}, ~isempty(strfind(t, checks{i})));
    end
    fprintf('EDD_ABL.m 已生成 (%d bytes)\n', numel(t));
end
