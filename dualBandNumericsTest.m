function dualBandNumericsTest()
    c=dualBandConfig('synthetic'); c.symbolCount=4; c.showPlots=false; c.saveResults=false; c.learningBlockCount=0;
    w=dbWaveform(c,404);
    tone=exp(2i*pi*0.137*(0:4095).');
    [f,p]=welch(tone,c.sampleRate,1024);
    assert(abs(sum(p)*(f(2)-f(1))-1)<1e-10,'Welch PSD does not integrate to tone power.');
    y=dbPa(w.composite,c); fine=c; fine.pa.oversampling=16; yFine=dbPa(w.composite,fine);
    rows=w.starts(2):w.starts(end)-1;
    error=norm(y(rows)-yFine(rows))/norm(yFine(rows));
    fprintf('PA x8/x16 relative waveform difference = %.9g\n',error);
    assert(error<1e-4,'PA oversampling has not converged.');
    n=numel(w.composite); t=(0:n-1).'/c.sampleRate;
    a=0.3*exp(-2i*pi*c.carrierSpacingHz/2*t); b=0.3*exp(2i*pi*c.carrierSpacingHz/2*t);
    shared=dbPa(a+b,c); separate=dbPa(a,c)+dbPa(b,c);
    coupling=norm(shared(rows)-separate(rows))/norm(shared(rows));
    fprintf('Common-PA cross-band interaction relative difference = %.9g\n',coupling);
    assert(coupling>1e-3,'PA lacks meaningful band interaction.');
    for parameter={'inputBackoffDb','carrierSpacingHz','powerImbalanceDb'}
        name=parameter{1}; value=c.(name);
        s=dualBandStudyRun(name,value,c);
        assert(height(s.summary)==8);
        assert(isequal(s.runs{1}.configuration.seeds,c.seeds));
    end
    fprintf('DUAL_BAND_NUMERICS_TEST_PASS\n');
end
