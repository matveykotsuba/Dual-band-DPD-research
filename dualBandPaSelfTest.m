function results = dualBandPaSelfTest()
    root=fileparts(mfilename('fullpath')); sourceRoot=fullfile(fileparts(root),'DPD-research');
    oldPath=path; cleanup=onCleanup(@() path(oldPath));
    addpath(sourceRoot,'-end'); addpath(fullfile(root,'verification'));
    c=dualBandConfig(); c.symbolCount=4; c.learningBlockCount=2; c.showPlots=false; c.saveResults=true;
    c.outputDirectory=fullfile(root,'verification','trained_pa'); dbValidate(c);
    source=load(fullfile(sourceRoot,'paModel.mat'));
    assert(isequal(c.pa.coefficients,source.coefficientsTikhonov));
    assert(isequal(c.pa.orders,source.fitInfo.orders));
    assert(isequal(c.pa.signalDelays,source.fitInfo.signalDelays));
    assert(isequal(c.pa.envelopeDelays,source.fitInfo.envelopeDelays));
    assert(c.pa.diagonalCount==source.fitInfo.diagonalCount);
    w=dbWaveform(c,c.seeds(1));
    [actual,info]=dbPa(w.composite,c,w);
    [expected,expectedInfo]=sourceReferencePa(w.composite,c,sourceRoot);
    relativeError=norm(actual-expected)/norm(expected);
    fprintf('SOURCE_PA_RELATIVE_ERROR %.16g\n',relativeError);
    assert(relativeError<1e-12,'Imported PA differs from the original pipeline.');
    assert(info.inputScale==expectedInfo.inputScale);
    [~,scaledInfo]=dbPa(1.1*w.composite,c,w);
    assert(scaledInfo.inputScale==info.inputScale,'Post-DPD input was renormalized.');
    assert(abs(scaledInfo.modelInputRms/info.modelInputRms-1.1)<1e-12);
    linear=c; linear.pa.coefficients(:)=0; linear.pa.coefficients(1,1)=1;
    linearOut=dbPa(w.composite,linear,w);
    assert(norm(linearOut-w.composite)/norm(w.composite)<1e-3,'Rate conversion distorts the occupied bands.');
    assert(all(isfinite(dbPa(zeros(size(w.composite)),c,w))));
    assert(all(isfinite(dbPa(zeros(size(w.composite)),c))));
    changed=c; changed.inputBackoffDb=c.inputBackoffDb+3; rejected=false;
    try
        dbPa(w.composite,changed,w);
    catch
        rejected=true;
    end
    assert(rejected,'Stale normalization was accepted.');
    synthetic=dualBandConfig('synthetic'); assert(strcmp(synthetic.pa.kind,'synthetic'));
    results=dualBandRun(c);
    for kind={'independent','wideband','dual'}
        entry=results.(kind{1});
        assert(all(diff(entry.history.nmseDb)<=1e-8));
        assert(abs(entry.history.nmseDb(1)-results.independent.history.nmseDb(1))<1e-10);
        assert(isequal(entry.configuration.pa.coefficients,source.coefficientsTikhonov));
    end
    assert(all(isfinite(results.summary.EVM_percent)) && all(isfinite(results.summary.ACLR_worst_dB)));
    assert(results.dual.coefficientCount==76 && results.wideband.coefficientCount==17 && results.independent.coefficientCount==34);
    fprintf('DUAL_BAND_TRAINED_PA_TEST_PASS\n');
end
