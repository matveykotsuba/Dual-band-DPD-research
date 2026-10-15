function runBlockPlotVerification()
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(root);
    folder=fullfile(root,'verification','block_learning');
    runPlotVerification(fullfile(folder,'dualBandResults.mat'),folder);
    f=openfig(fullfile(folder,'learning.fig'),'invisible');
    ax=findall(f,'Type','axes'); lines=findall(ax,'Type','line');
    assert(numel(lines)==3 && strcmp(get(get(ax,'XLabel'),'String'),'Adaptation block'));
    for k=1:3
        x=get(lines(k),'XData'); assert(isequal(x(:).',0:10));
    end
    close(f); fprintf('TEN_BLOCK_PLOT_PASS\n');
end
