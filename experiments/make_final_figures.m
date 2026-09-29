function make_final_figures()
    % M>=3 定位出图：Friedman 排名 / IGD 箱线 / 代表问题对比 / 热力图
    cd('D:\harness工作\中国科学：数学(总)\算法\algorithm');
    addpath('problems'); addpath('algorithms\utils'); addpath('algorithms'); addpath('algorithms\utils');
    addpath('problems_official'); addpath('problems_official\MaF'); addpath('problems_official\LSMOP'); addpath('problems_official\EMO'); addpath('problems_official\UF');
    clear classes; clear IGD HV;
    % 优先用 M>=3 的 friedman_m3.mat；缺失则用 combined
    if exist('results\friedman_m3.mat','file')
        C = load('results\friedman_m3.mat').out;
        allProbs = C.m3_29; tag = 'M>=3';
    else
        C = load('results\friedman_combined.mat').out;
        allProbs = C.allProbs; tag = 'combined';
    end
    algs = C.algs; igdMed = C.igdMed; hvMed = C.hvMed;
    nA = numel(algs); nP = numel(allProbs);
    figdir = 'results\figures'; if ~isdir(figdir), mkdir(figdir); end
    % HCEAV4 红色高亮
    colors = lines(nA); iV4 = find(strcmp(algs,'HCEAV4'));
    if ~isempty(iV4), colors(iV4,:) = [1 0 0]; end
    % --- 图1: Friedman 平均秩条形图（IGD + HV）---
    fig1 = figure('Visible','off','Position',[100 100 1000 400]);
    subplot(1,2,1); b=bar(C.avgRankIGD,'HorizontalAlignment','left'); b.ItemLabel=algs;
    ylabel('平均秩（小者优）'); title(sprintf('IGD Friedman 排名（%s %d 问题）', tag, nP));
    set(gca,'FontSize',8,'XTick',1:nA,'XTickLabelRotation',45);
    subplot(1,2,2); b=bar(C.avgRankHV,'HorizontalAlignment','left'); b.ItemLabel=algs;
    ylabel('平均秩（小者优）'); title(sprintf('HV Friedman 排名（%s %d 问题）', tag, nP));
    set(gca,'FontSize',8,'XTick',1:nA,'XTickLabelRotation',45);
    saveas(fig1, fullfile(figdir,'fig1_friedman_rank.png'));
    % --- 图2: IGD 箱线图（每算法在全部问题上的 IGD 中位分布）---
    fig2 = figure('Visible','off','Position',[100 100 900 450]);
    boxplot(igdMed','Labels',algs);
    ylabel('IGD（30 种子中位）'); title(sprintf('10 算法 IGD 分布（%s %d 问题）', tag, nP));
    set(gca,'FontSize',9,'XTickLabelRotation',45);
    saveas(fig2, fullfile(figdir,'fig2_igd_box.png'));
    % --- 图3: 代表性问题 IGD 对比（MaF14 + LSMOP6，含 HCEAV4/HCEA）---
    algsPick = {'HCEAV4','HCEA','NSGA2','SMSEMOA','MOEAD'};
    ii = ismember(algsPick, algs);
    fig3 = figure('Visible','off','Position',[100 100 1000 450]);
    pMaF14 = find(strcmp(allProbs,'MaF14'),1);
    pLSMOP6 = find(strcmp(allProbs,'LSMOP6'),1);
    if pMaF14
        subplot(1,2,1);
        bar(igdMed(ii,pMaF14)); set(gca,'XTickLabel',algsPick(ii));
        ylabel('IGD 中位'); title(sprintf('MaF14 IGD 对比（M>=3）'));
    end
    if pLSMOP6
        subplot(1,2,2);
        bar(igdMed(ii,pLSMOP6)); set(gca,'XTickLabel',algsPick(ii));
        ylabel('IGD 中位'); title(sprintf('LSMOP6 IGD 对比（M>=3 D=300）'));
    end
    saveas(fig3, fullfile(figdir,'fig3_igd_compare.png'));
    % --- 图4: 问题级 IGD 中位热力图（10 算法 x 全部问题）---
    fig4 = figure('Visible','off','Position',[100 100 1400 400]);
    imagesc(igdMed); colorbar;
    set(gca,'XTick',1:nP,'XTickLabel',allProbs,'FontSize',6,'XTickLabelRotation',90);
    set(gca,'YTick',1:nA,'YTickLabel',algs);
    title(sprintf('IGD 中位热力图（10 算法 x %s %d 问题）', tag, nP));
    saveas(fig4, fullfile(figdir,'fig4_igd_heatmap.png'));
    fprintf('4 张图已存 results/figures/\n');
end
