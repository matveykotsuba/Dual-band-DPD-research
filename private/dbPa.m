function [y,info] = dbPa(x,c,reference)
    if isfield(c.pa,'kind') && strcmp(c.pa.kind,'trained-gmp')
        source=dbSourcePaConfiguration(c);
        if nargin>=3
            assert(isfield(reference,'paInputScale'),'Missing pre-DPD PA normalization.');
            scale=reference.paInputScale;
            filter=reference.paInputInfo.rateFilter;
            assert(reference.paInputInfo.systemSampleRate==c.sampleRate && reference.paInputInfo.modelSampleRate==c.pa.modelSampleRate);
            assert(abs(reference.paInputInfo.modelInputRms-source.pa.referenceInputRms*10^(-c.inputBackoffDb/20))<1e-12, ...
                'PA backoff/reference RMS changed after the reference waveform was prepared.');
            modelInput=paInterpolate(x,source.pa.rateFactor,filter)*scale;
        else
            [modelInput,inputInfo]=paModelInput(x,source);
            scale=inputInfo.inputScale; filter=inputInfo.rateFilter;
        end
        modelOutput=gmpCore(modelInput,source.pa);
        [y,outputInfo]=paSystemOutput(modelOutput,numel(x),scale,filter,source);
        assert(all(isfinite(y)),'The trained PA produced a nonfinite output. Check drive level.');
        info=struct('kind','trained-gmp','inputScale',scale,'modelInputRms',sqrt(mean(abs(modelInput).^2)), ...
            'modelInputPeak',max(abs(modelInput)),'aboveTrainingMagnitudeFraction',mean(abs(modelInput)>source.pa.maximumInputMagnitude), ...
            'output',outputInfo);
        return;
    end
    info=struct('kind','synthetic');
    x=x(:); n=numel(x); l=c.pa.oversampling;
    assert(mod(n,2)==0,'PA FFT rate conversion requires an even frame length.');
    pad=(l-1)*n/2;
    z=ifft(ifftshift([zeros(pad,1);fftshift(fft(x));zeros(pad,1)]))*l;
    delay=l;
    if isfield(c.pa,'memoryDelaySamples'), delay=l*c.pa.memoryDelaySamples; end
    delayed=[zeros(delay,1);z(1:end-delay)];
    v=z+c.pa.cubic*z.*abs(z).^2+c.pa.quintic*z.*abs(z).^4 ...
        +c.pa.memoryCubic*delayed.*abs(delayed).^2+c.pa.crossMemory*z.*abs(delayed).^2;
    spectrum=fftshift(fft(v));
    y=ifft(ifftshift(spectrum(pad+(1:n))))/l;
end
