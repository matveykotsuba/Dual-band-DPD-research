function runVerification()
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); cd(root);
    set(0,'DefaultFigureVisible','off');
    dualBandSelfTest();
    dualBandNumericsTest();
    results=dualBandRun();
    fprintf('DUAL_BAND_DEFAULT_RUN_PASS\n');
end
