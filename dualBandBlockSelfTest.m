function results = dualBandBlockSelfTest()
    c=dualBandConfig(); assert(c.learningBlockCount==10 && ~isfield(c,'iterations'));
    state=rng; cleanup=onCleanup(@() rng(state)); rng(998,'twister');
    x=(randn(600,1)+1i*randn(600,1))/3; z=.9*x+.08*x.*abs(x).^2;
    f=struct('orders',[1 3],'signalDelays',0:1,'envelopeDelays',0:1, ...
        'diagonalCount',1,'memoryOrder',1,'bandIndex',1,'regularizationLambdaValues',1e-5);
    [scalar,si]=dpdBatchFit(z,x,f);
    [dual,di]=dbDualBatchFit(z,[x zeros(size(x))],f);
    a=gmpBasis(x,f,si.coefficientMask); b=dbBasis([x zeros(size(x))],'dual',1,f);
    b=b(2:end,:);
    assert(norm(a*scalar(si.activeIndices)-b*dual)/norm(a*scalar(si.activeIndices))<1e-10);
    assert(si.bestLambda==di.bestLambda && numel(si.trainingRows)==numel(di.trainingRows));
    fprintf('DUAL_BATCH_SCALAR_LIMIT_PASS\n');
    c.showPlots=false; c.saveResults=true;
    c.outputDirectory=fullfile(fileparts(mfilename('fullpath')),'verification','block_learning');
    results=dualBandRun(c);
    train=dbWaveform(c,c.seeds(1));
    for kind={'independent','wideband','dual'}
        entry=results.(kind{1}); h=entry.history;
        assert(h.blockCount==10 && isequal(h.blockIndex,(0:10).') && numel(h.nmseDb)==11);
        assert(h.firstSample(1)==train.starts(2) && h.lastSample(end)==train.starts(end)-1);
        assert(all(h.firstSample(2:end)==h.lastSample(1:end-1)+1));
        assert(all(h.fitFirstSample>=h.firstSample) && all(h.fitLastSample<=h.lastSample));
        assert(all(diff(h.nmseDb)<=1e-8));
        assert(abs(h.nmseDb(1)-results.independent.history.nmseDb(1))<1e-10);
        for block=1:10
            before=struct('kind',kind{1},'coefficients',{h.coefficientHistory(block,:)});
            predicted=dbDriveLimit(dbApply(train,before,c),c);
            rows=h.firstSample(block):h.lastSample(block);
            assert(norm(predicted(rows)-h.emittedDrive(rows))<1e-10,'A block was recomputed with later coefficients.');
            for branch=1:size(h.coefficientHistory,2)
                info=h.fitInfo{block,branch};
                assert(info.sampleCount==h.fitLastSample(block)-h.fitFirstSample(block)+1);
                assert(isempty(intersect(info.trainingRows,info.validationRows)));
                if ~h.accepted(block)
                    assert(isequal(h.coefficientHistory{block,branch},h.coefficientHistory{block+1,branch}));
                end
            end
        end
        assert(isequal(entry.model.coefficients,h.coefficientHistory(end,:)));
        assert(isequal(entry.configuration.pa.coefficients,c.pa.coefficients));
    end
    assert(all(isfinite(results.summary.EVM_percent)) && all(isfinite(results.summary.ACLR_worst_dB)));
    fprintf('DUAL_BAND_TEN_BLOCK_TEST_PASS\n');
end
