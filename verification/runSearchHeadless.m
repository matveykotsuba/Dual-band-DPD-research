function runSearchHeadless()
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); cd(root);
    fprintf('DUAL_BAND_HEADLESS_SEARCH_STARTED\n');
    search=dualBandSearchConfig(); search.configuration.showPlots=false;
    study=dualBandSearchRun(search);
    fprintf('DUAL_BAND_HEADLESS_SEARCH_FINISHED\n');
end
