function cfg = dualBandConfig(paMode)
    if nargin<1, paMode='trained-gmp'; end
    assert(any(strcmp(paMode,{'trained-gmp','synthetic'})),'Unknown PA mode.');
    cfg.sampleRate = 122.88e6;
    cfg.fftSize = 2048;
    cfg.activeSubcarriers = 60;
    cfg.cpLength = 144;
    cfg.wolaLength = 32;
    cfg.symbolCount = 16;
    cfg.carrierSpacingHz = 15e6;
    cfg.channelBandwidthHz = 5e6;
    cfg.feedbackHalfBandwidthHz = 6e6;
    cfg.powerImbalanceDb = 0;
    cfg.inputBackoffDb = 4; % TX RMS relative to unity, NOT a measured P1dB
    cfg.seeds = [101 202 303]; % train, validation, test
    cfg.orders = [1 3 5];
    cfg.memoryOrder = 2;
    cfg.diagonalCount = 1;
    cfg.learningBlockCount = 10;
    cfg.lambdaValues = logspace(-12,2,200);
    cfg.stepSizes = [1 0.5 0.25 0.125 0.0625];
    cfg.maximumCoefficientNorm = 1e3;
    cfg.maximumDrivePeak = 3;
    cfg.pa.oversampling = 8;
    cfg.pa.cubic = -0.12 + 0.025i;
    cfg.pa.quintic = 0.009 - 0.003i;
    cfg.pa.memoryCubic = -0.025 + 0.012i;
    cfg.pa.crossMemory = 0.018 - 0.008i;
    cfg.pa.kind = 'synthetic';
    cfg.psdSegmentLength = 8192;
    cfg.showPlots = true;
    cfg.saveResults = true;
    cfg.outputDirectory = fullfile(fileparts(mfilename('fullpath')),'results','synthetic_pa');
    if strcmp(paMode,'trained-gmp')
        cfg.pa=paConfig(true);
        cfg.pa.kind='trained-gmp';
        cfg.inputBackoffDb=cfg.pa.inputBackoffDb;
        cfg.outputDirectory=fullfile(fileparts(mfilename('fullpath')),'results','trained_pa');
    end
end
