function runPlotVerification(inputFile,outputDirectory)
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(root);
    set(0,'DefaultFigureVisible','off');
    if nargin<1, inputFile=fullfile(root,'results','dualBandResults.mat'); end
    if nargin<2, outputDirectory=fullfile(root,'verification','plots'); end
    s=load(inputFile);
    r=s.results;
    r.configuration.saveResults=true;
    r.configuration.outputDirectory=outputDirectory;
    f=dualBandPlot(r);
    assert(numel(f)==4);
    ax=findall(f(1),'Type','axes'); assert(numel(ax)==4);
    for k=1:4
        assert(numel(findall(ax(k),'Type','line'))==2);
        assert(isequal(get(ax(k),'XLim'),get(ax(1),'XLim')));
        assert(isequal(get(ax(k),'YLim'),get(ax(1),'YLim')));
    end
    ax=findall(f(4),'Type','axes'); assert(numel(ax)==2);
    names={'none','independent','wideband','dual'};
    for j=1:2
        t=get(get(ax(j),'Title'),'String'); b=sscanf(t,'Band %d',1);
        h=findall(ax(j),'Type','bar'); assert(numel(h)==2);
        for k=1:4
            m=r.(names{k}).metrics;
            values=sort([get(h(1),'YData');get(h(2),'YData')],1);
            assert(max(abs(values(:,k)-sort([m.aclrLeftDb(b);m.aclrRightDb(b)])))<1e-12);
        end
    end
    close(f);
    fprintf('DUAL_BAND_PLOT_LAYOUT_PASS\n');
end
