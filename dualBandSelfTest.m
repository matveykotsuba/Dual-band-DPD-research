function dualBandSelfTest()
    c=dualBandConfig('synthetic'); c.symbolCount=4; c.learningBlockCount=2; c.showPlots=false; c.saveResults=false;
    dbValidate(c); before=rng; w=dbWaveform(c,101); after=rng; assert(isequal(before,after));
    same=dbWaveform(c,101); other=dbWaveform(c,102);
    assert(isequal(w.bands,same.bands) && ~isequal(w.bands,other.bands));
    z=c; z.pa.cubic=0; z.pa.quintic=0; z.pa.memoryCubic=0; z.pa.crossMemory=0;
    assert(norm(dbPa(w.composite,z)-w.composite)/norm(w.composite)<1e-12,'Linear PA is not identity.');
    for kind={'independent','wideband','dual'}
        a=dbBasis(w.bands,'dual',1,c); assert(size(a,2)==38);
        if strcmp(kind{1},'wideband'), x=w.composite; outputs=1; else, x=w.bands; outputs=2; end
        model=struct('kind',kind{1},'coefficients',{{}});
        for b=1:outputs
            a=dbBasis(x,kind{1},b,c); model.coefficients{b}=zeros(size(a,2),1); model.coefficients{b}(1)=1;
            assert(norm(a(:,1)-x(:,min(b,size(x,2))))<1e-12);
        end
        assert(norm(dbApply(w,model,c)-w.composite)<1e-11,'Identity starts differ.');
    end
    a=dbBasis(zeros(size(w.bands)),'dual',1,c); assert(all(a(:)==0));
    phase=exp(0.31i); a=dbBasis(w.bands,'dual',1,c); rotated=w.bands; rotated(:,1)=phase*rotated(:,1);
    ar=dbBasis(rotated,'dual',1,c); assert(norm(ar-phase*a,'fro')/norm(a,'fro')<1e-12);
    ref=dbMetrics(w,w.composite,c); assert(max(ref.evmPercent)<0.1,'OFDM reference EVM unexpectedly high.');
    bad=c; bad.seeds=[1 1 2]; rejected=false;
    try
        dbValidate(bad);
    catch
        rejected=true;
    end
    assert(rejected,'Repeated seeds were accepted.');
    [limited,info]=dbDriveLimit([1;4i],c);
    assert(isequal(limited,[1;3i]) && info.clippedFraction==0.5);
    r=dualBandRun(c);
    for kind={'independent','wideband','dual'}
        h=r.(kind{1}).history; assert(all(diff(h.nmseDb)<=1e-8));
        assert(abs(h.nmseDb(1)-r.independent.history.nmseDb(1))<1e-10);
    end
    assert(r.dual.coefficientCount==76 && r.wideband.coefficientCount==17 && r.independent.coefficientCount==34);
    assert(all(isfinite(r.summary.EVM_percent)) && all(isfinite(r.summary.ACLR_worst_dB)));
    assert(mean(r.dual.metrics.evmPercent)<mean(r.none.metrics.evmPercent));
    assert(mean(r.wideband.metrics.evmPercent)<mean(r.none.metrics.evmPercent));
    fprintf('DUAL_BAND_SELF_TEST_PASS\n');
end
