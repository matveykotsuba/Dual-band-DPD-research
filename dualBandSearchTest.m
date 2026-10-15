function dualBandSearchTest()
    a=dbSelectProfile([3 5 7],[-20 -21 -21.1],.2,'increment');
    assert(a.selectedValue==5 && a.thresholdReached);
    a=dbSelectProfile([3 5 7],[-20 -20.1 -24],.2,'increment');
    assert(a.selectedValue==3 && a.gapToBestDb==4); % Expose a later rebound.
    a=dbSelectProfile([0 1 2],[-20 -21 -22],.05,'increment');
    assert(~a.thresholdReached && a.selectedValue==2);
    a=dbSelectProfile([0 1 2],[-20 -21 -20.5],.05,'increment');
    assert(a.selectedValue==1);
    a=dbSelectProfile([0 1 2],[-20 -20.98 -21],.05,'tolerance');
    assert(a.selectedValue==1);
    c=dualBandConfig('synthetic'); n=(0:4095).'; x=.4*exp(2i*pi*n/64);
    explicit=c; explicit.pa.memoryDelaySamples=1;
    assert(isequal(dbPa(x,c),dbPa(x,explicit)),'Default PA changed.');
    search=dualBandSearchConfig(); fine=search.configuration;
    assert(fine.fftSize/fine.sampleRate==c.fftSize/c.sampleRate);
    assert(fine.cpLength/fine.sampleRate==c.cpLength/c.sampleRate);
    assert(fine.wolaLength/fine.sampleRate==c.wolaLength/c.sampleRate);
    assert(fine.pa.memoryDelaySamples/fine.sampleRate==1/c.sampleRate);
    search.polynomialOrders=[3 5]; search.memoryOrders=[0 1];
    search.polynomialThresholdDb=1e6; search.memoryThresholdDb=1e6;
    search.resume=false; search.configuration.symbolCount=4;
    search.configuration.iterations=1; search.configuration.showPlots=false;
    search.configuration.saveResults=true;
    search.configuration.outputDirectory=fullfile(fileparts(mfilename('fullpath')),'verification','search_smoke');
    s=dualBandSearchRun(search); assert(s.allCriteriaSatisfied);
    assert(height(s.summary)==3 && all(s.summary.P==3) && all(s.summary.M==0));
    assert(isfield(s,'comparison') && height(s.comparison.summary)==8);
    assert(s.comparison.independent.coefficientCount==4 && s.comparison.wideband.coefficientCount==2 && s.comparison.dual.coefficientCount==6);
    assert(isequal(s.comparison.configuration.pa,search.configuration.pa));
    c=s.comparison.configuration; c.modelParameters.dual.memoryOrder=1;
    dual=dbModeConfiguration(c,'dual'); wide=dbModeConfiguration(c,'wideband');
    assert(dual.memoryOrder==1 && wide.memoryOrder==0);
    bad=c; bad.modelParameters.dual.sampleRate=1; rejected=false;
    try
        dbModeConfiguration(bad,'dual');
    catch
        rejected=true;
    end
    assert(rejected,'A per-mode PA/waveform override was accepted.');
    search.resume=true; again=dualBandSearchRun(search);
    assert(isequaln(s.entries,again.entries),'Resume changed cached candidates.');
    figures=dualBandSearchPlot(s); assert(numel(figures)==3); close(figures);
    fprintf('DUAL_BAND_SEARCH_TEST_PASS\n');
end
