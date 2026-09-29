function Draw(varargin)
% Draw shim — 空函数，覆盖官方 PlatEMO 的 Draw.m（GUI 绘图）
% 无头跑 baseline 时，NotTerminated 每代调 drawnow('limitrate') + DefaultOutput 调 Draw。
% 本 shim 让 Draw 成为 no-op，使 headless 流程不崩。
% 位置：algorithms/Draw_shim/Draw.m，addpath 顺序保证优先于 _platemo_official/Draw.m
end
