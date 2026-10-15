function runBlockVerification()
    root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); cd(root);
    results=dualBandBlockSelfTest();
    fprintf('BLOCK_VERIFICATION_FINISHED\n');
end
