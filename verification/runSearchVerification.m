function runSearchVerification()
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); cd(root);
    fprintf('DUAL_BAND_SEARCH_VERIFICATION_STARTED\n');
    set(0,'DefaultFigureVisible','off');
    maxNumCompThreads(2); % This dedicated test process must not occupy every CPU.
    fprintf('DUAL_BAND_SEARCH_THREADS_READY\n');
    dualBandSearchTest();
    study=dualBandSearchRun();
    fprintf('DUAL_BAND_SEARCH_RUN_FINISHED\n');
end
