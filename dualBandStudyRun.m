function study = dualBandStudyRun(parameter,values,cfg)
    if nargin<1, parameter='inputBackoffDb'; end
    if nargin<2, values=[3 4 6]; end
    if nargin<3, cfg=dualBandConfig(); end
    allowed={'inputBackoffDb','carrierSpacingHz','powerImbalanceDb'};
    assert(any(strcmp(parameter,allowed)),'Unsupported study parameter.');
    validateattributes(values,{'numeric'},{'vector','nonempty','finite','real'});
    study.parameter=parameter; study.values=values; study.runs=cell(numel(values),1);
    rows=cell(numel(values),1); parent=cfg.outputDirectory;
    for k=1:numel(values)
        point=cfg; point.(parameter)=values(k); point.showPlots=false; point.saveResults=false;
        study.runs{k}=dualBandRun(point);
        row=study.runs{k}.summary; row.ParameterValue=repmat(values(k),height(row),1); rows{k}=row;
    end
    study.summary=vertcat(rows{:}); disp(study.summary);
    if cfg.saveResults
        if ~exist(parent,'dir'), mkdir(parent); end
        save(fullfile(parent,['study_' parameter '.mat']),'study','-v7');
        writetable(study.summary,fullfile(parent,['study_' parameter '.csv']));
    end
    if cfg.showPlots
        f=figure('Name',['Dual-band study: ' parameter],'Color','w'); modes={'none','independent','wideband','dual'};
        for b=1:2
            subplot(2,2,b); hold on;
            for m=1:4
                z=zeros(size(values));
                for k=1:numel(values), z(k)=study.runs{k}.(modes{m}).metrics.evmPercent(b); end
                plot(values,z,'o-');
            end
            grid on; xlabel(parameter,'Interpreter','none'); ylabel(sprintf('Band %d EVM, %%',b)); legend(modes,'Location','best');
            subplot(2,2,b+2); hold on;
            for m=1:4
                z=zeros(size(values));
                for k=1:numel(values), z(k)=study.runs{k}.(modes{m}).metrics.aclrWorstDb(b); end
                plot(values,z,'o-');
            end
            grid on; xlabel(parameter,'Interpreter','none'); ylabel(sprintf('Band %d ACLR, dB',b));
        end
        if cfg.saveResults, print(f,fullfile(parent,['study_' parameter '.png']),'-dpng','-r150'); end
    end
end
