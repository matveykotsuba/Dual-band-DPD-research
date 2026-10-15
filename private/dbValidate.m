function dbValidate(c)
    validateattributes(c.sampleRate,{'numeric'},{'scalar','positive','finite'});
    for name = {'fftSize','activeSubcarriers','cpLength','symbolCount'}
        validateattributes(c.(name{1}),{'numeric'},{'scalar','integer','positive','finite'});
    end
    assert(mod(c.fftSize,2)==0 && mod(c.activeSubcarriers,2)==0,'Use even FFT and carrier counts.');
    assert(c.activeSubcarriers<c.fftSize && c.cpLength<c.fftSize);
    assert(c.symbolCount>=4,'At least four OFDM symbols are needed.');
    validateattributes(c.wolaLength,{'numeric'},{'scalar','integer','nonnegative'});
    assert(c.wolaLength<c.cpLength);
    validateattributes(c.memoryOrder,{'numeric'},{'scalar','integer','nonnegative'});
    validateattributes(c.diagonalCount,{'numeric'},{'scalar','integer','nonnegative'});
    assert(c.memoryOrder<c.cpLength-c.wolaLength);
    assert(c.orders(1)==1 && all(mod(c.orders,2)==1) && all(diff(c.orders)>0));
    assert(numel(c.seeds)==3 && numel(unique(c.seeds))==3,'Train/validation/test seeds must differ.');
    if isfield(c,'learningBlockCount')
        validateattributes(c.learningBlockCount,{'numeric'},{'scalar','integer','nonnegative'});
        validateattributes(c.maximumCoefficientNorm,{'numeric'},{'scalar','positive','finite'});
    else
        validateattributes(c.iterations,{'numeric'},{'scalar','integer','nonnegative'});
    end
    validateattributes(c.lambdaValues,{'numeric'},{'vector','positive','finite','nonempty'});
    validateattributes(c.stepSizes,{'numeric'},{'vector','positive','finite','nonempty'});
    assert(all(c.stepSizes<=1));
    validateattributes(c.maximumDrivePeak,{'numeric'},{'scalar','positive','finite'});
    validateattributes(c.inputBackoffDb,{'numeric'},{'scalar','real','finite'});
    validateattributes(c.powerImbalanceDb,{'numeric'},{'scalar','real','finite'});
    trained=isfield(c.pa,'kind') && strcmp(c.pa.kind,'trained-gmp');
    if isfield(c.pa,'kind'), assert(any(strcmp(c.pa.kind,{'trained-gmp','synthetic'})),'Unknown PA kind.'); end
    if trained
        dbSourcePaConfiguration(c);
        validateattributes(c.pa.referenceInputRms,{'numeric'},{'scalar','positive','finite'});
        validateattributes(c.pa.inputBackoffDb,{'numeric'},{'scalar','real','finite'});
        validateattributes(c.pa.coefficients,{'numeric'},{'2d','finite'});
        assert(isequal(size(c.pa.coefficients),[numel(c.pa.signalDelays),1+(numel(c.pa.orders)-1)*numel(c.pa.envelopeDelays)]));
    else
        validateattributes(c.pa.oversampling,{'numeric'},{'scalar','integer','positive'});
    end
    if isfield(c.pa,'memoryDelaySamples')
        validateattributes(c.pa.memoryDelaySamples,{'numeric'},{'scalar','integer','positive','<',c.fftSize});
    end
    for name={'carrierSpacingHz','channelBandwidthHz','feedbackHalfBandwidthHz'}
        validateattributes(c.(name{1}),{'numeric'},{'scalar','real','positive','finite'});
    end
    validateattributes(c.orders,{'numeric'},{'vector','integer','positive','finite','nonempty'});
    validateattributes(c.seeds,{'numeric'},{'vector','integer','nonnegative','finite'});
    validateattributes(c.psdSegmentLength,{'numeric'},{'scalar','integer','>=',2,'finite'});
    if ~trained
        for name={'cubic','quintic','memoryCubic','crossMemory'}
            validateattributes(c.pa.(name{1}),{'numeric'},{'scalar','finite'});
        end
    end
    assert(c.maximumDrivePeak>10^(-c.inputBackoffDb/20),'Drive limit is below TX RMS.');
    occupiedHalf=c.activeSubcarriers/2*c.sampleRate/c.fftSize;
    assert(c.channelBandwidthHz>2*occupiedHalf,'Channel must cover active carriers.');
    assert(c.feedbackHalfBandwidthHz>occupiedHalf);
    assert(2*c.feedbackHalfBandwidthHz<c.carrierSpacingHz,'Feedback bands overlap.');
    assert(c.carrierSpacingHz>2*c.channelBandwidthHz,'ACLR windows overlap a useful band.');
    assert(c.carrierSpacingHz/2+1.5*c.channelBandwidthHz<c.sampleRate/2);
    assert(max(c.orders)*(c.carrierSpacingHz/2+occupiedHalf)<c.sampleRate/2,'DPD basis may alias: increase sampleRate.');
    if ~trained, assert(c.pa.oversampling>=5,'Fifth-order PA needs at least 5x oversampling for arbitrary base-rate drive.'); end
end
