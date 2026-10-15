function search = dualBandSearchConfig()
    c=dualBandConfig('synthetic'); % Optional legacy experiment; never part of normal runs.
    c=rmfield(c,'learningBlockCount'); c.iterations=4;
    c.lambdaValues=[1e-7 1e-5 1e-3 1e-1]; c.stepSizes=[1 .5 .25 .125 .0625 .03125];
    c.sampleRate=2*c.sampleRate; c.fftSize=2*c.fftSize;
    c.cpLength=2*c.cpLength; c.wolaLength=2*c.wolaLength;
    c.psdSegmentLength=2*c.psdSegmentLength;
    c.pa.memoryDelaySamples=2;
    c.seeds=[1101 1202 1303];
    c.outputDirectory=fullfile(fileparts(mfilename('fullpath')),'results','parameter_search');
    search.configuration=c;
    search.polynomialOrders=3:2:11;
    search.memoryOrders=0:6;
    search.polynomialThresholdDb=0.20;
    search.memoryThresholdDb=0.05;
    search.diagonalToleranceDb=0.05;
    search.maximumCoordinateIterations=10;
    search.resume=true;
end
