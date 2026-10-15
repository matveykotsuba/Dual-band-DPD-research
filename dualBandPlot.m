function figures = dualBandPlot(r)
    c=r.configuration; names={'none','independent','wideband','dual'};
    labels={'PA only','Independent GMP','Wideband GMP','Dual-band GMP'};
    paLabel='synthetic PA';
    if isfield(c.pa,'kind') && strcmp(c.pa.kind,'trained-gmp'), paLabel='trained GMP PA'; end
    colors=[0 .45 .74; .85 .33 .1; 0 .5 .2; .5 .1 .65]; figures=zeros(4,1);
    f=figure('Name',['Dual-band Welch spectra | ' paLabel],'Color','w','Position',[50 50 1200 800]); figures(1)=double(f);
    set(f,'PaperPositionMode','auto');
    limits=[-1 1]*(c.carrierSpacingHz/2+2*c.channelBandwidthHz)/1e6;
    spectra=[{r.reference} cellfun(@(n) r.(n).metrics,names,'UniformOutput',false)];
    low=Inf; high=-Inf;
    for k=1:numel(spectra)
        m=spectra{k}; visible=m.frequency/1e6>=limits(1) & m.frequency/1e6<=limits(2);
        db=10*log10(max(m.psd(visible),realmin));
        low=min(low,min(db)); high=max(high,max(db));
    end
    ylimits=[5*floor(low/5) 5*ceil(high/5)+5];
    for k=1:4
        subplot(2,2,k);
        if k==1
            a=r.reference; b=r.none.metrics;
            pairLabels={'TX reference','PA only'}; firstColor=[.35 .35 .35];
            titleText=['Effect of ' paLabel];
        else
            a=r.none.metrics; b=r.(names{k}).metrics;
            pairLabels={'PA only',labels{k}}; firstColor=colors(1,:);
            titleText=labels{k};
        end
        plot(a.frequency/1e6,10*log10(max(a.psd,realmin)),'--','Color',firstColor,'LineWidth',1); hold on;
        plot(b.frequency/1e6,10*log10(max(b.psd,realmin)),'-','Color',colors(k,:),'LineWidth',1.2);
        grid on; xlabel('Frequency, MHz'); ylabel('PSD, dB / Hz (relative units)');
        title(titleText); xlim(limits); ylim(ylimits);
        legend(pairLabels,'Location','southoutside','Orientation','horizontal');
    end
    f=figure('Name',['Held-out dual-band comparison | ' paLabel],'Color','w'); figures(2)=double(f);
    evm=zeros(4,2); aclr=evm;
    for k=1:4, evm(k,:)=r.(names{k}).metrics.evmPercent; aclr(k,:)=r.(names{k}).metrics.aclrWorstDb; end
    subplot(2,1,1); bar(evm); ylabel('EVM, %'); grid on;
    set(gca,'XTick',1:4,'XTickLabel',labels); legend('Band 1','Band 2','Location','best');
    subplot(2,1,2); bar(aclr); ylabel('Worst-side ACLR, dB'); grid on;
    set(gca,'XTick',1:4,'XTickLabel',labels); legend('Band 1','Band 2','Location','best');
    f=figure('Name',['ILA validation history | ' paLabel],'Color','w'); figures(3)=double(f);
    blockMode=isfield(r.independent.history,'blockIndex'); lastPoint=0;
    for k=2:4
        h=r.(names{k}).history; x=(0:numel(h.nmseDb)-1).';
        if isfield(h,'blockIndex'), x=h.blockIndex; end
        plot(x,h.nmseDb,'o-','Color',colors(k,:),'LineWidth',1.3); hold on;
        lastPoint=max(lastPoint,max(x));
    end
    if blockMode, xlabel('Adaptation block'); else, xlabel('ILA iteration'); end
    ylabel('Validation NMSE, dB'); grid on;
    xlim([-0.15 lastPoint+0.15]); set(gca,'XTick',0:lastPoint);
    legend(labels(2:end),'Location','best');
    f=figure('Name',['ACLR by band and adjacent side | ' paLabel],'Color','w','Position',[80 80 1100 700]); figures(4)=double(f);
    set(f,'PaperPositionMode','auto');
    sides=zeros(4,2,2);
    for k=1:4
        m=r.(names{k}).metrics;
        sides(k,:,1)=m.aclrLeftDb; sides(k,:,2)=m.aclrRightDb;
    end
    aclrLimits=[min(0,5*floor(min(sides(:))/5)) 5*ceil(max(sides(:))/5)+5];
    for b=1:2
        subplot(2,1,b); h=bar([sides(:,b,1) sides(:,b,2)]);
        set(h(1),'FaceColor',[0 .45 .74]); set(h(2),'FaceColor',[.85 .33 .1]);
        ylabel('ACLR, dB'); grid on; ylim(aclrLimits);
        title(sprintf('Band %d (%+.2f MHz)',b,(2*b-3)*c.carrierSpacingHz/2e6));
        set(gca,'XTick',1:4,'XTickLabel',labels);
        legend('Left adjacent channel','Right adjacent channel','Location','southoutside','Orientation','horizontal');
    end
    if c.saveResults
        if ~exist(c.outputDirectory,'dir'), mkdir(c.outputDirectory); end
        files={'spectrum','comparison','learning','aclr'};
        for k=1:numel(figures)
            print(figure(figures(k)),fullfile(c.outputDirectory,[files{k} '.png']),'-dpng','-r150');
            savefig(figure(figures(k)),fullfile(c.outputDirectory,[files{k} '.fig']));
        end
    end
end
