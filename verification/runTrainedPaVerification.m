function runTrainedPaVerification()
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); cd(root);
    results=dualBandPaSelfTest();
    fprintf('TRAINED_PA_VERIFICATION_FINISHED\n');
end
