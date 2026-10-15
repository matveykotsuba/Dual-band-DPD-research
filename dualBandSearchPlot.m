function figures = dualBandSearchPlot(study)
    kinds={'independent','wideband','dual'};
    labels={'Independent GMP','Wideband GMP','Dual-band GMP'};
    fields={'polynomial','memory','diagonal'};
    axesLabels={'Polynomial order P','Memory order M','Side diagonals d'};
    c=study.search.configuration; figures=zeros(3,1);
    for k=1:3
        f=figure('Name',[labels{k} ' parameter search'],'Color','w','Position',[50 50 1200 440]);
        figures(k)=double(f); set(f,'PaperPositionMode','auto');
        for j=1:3
            v=study.profiles.(kinds{k}).(fields{j}); subplot(1,3,j);
            plot(v.values,v.nmseDb,'o-','LineWidth',1.4); grid on;
            xlabel(axesLabels{j}); ylabel('NMSE, dB'); set(gca,'XTick',v.values);
            title(sprintf('%s: selected %g',labels{k},v.selectedValue));
            if numel(v.values)==1, xlim(v.values+[-.5 .5]); end
        end
        if c.saveResults
            path=fullfile(c.outputDirectory,['search_' kinds{k}]);
            print(f,[path '.png'],'-dpng','-r150'); savefig(f,[path '.fig']);
        end
    end
end
