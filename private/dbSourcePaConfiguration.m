function source = dbSourcePaConfiguration(c)
    source=struct('sampleRate',c.sampleRate,'pa',c.pa);
    source.pa.inputBackoffDb=c.inputBackoffDb;
    source.pa.systemSampleRate=c.sampleRate;
    source.pa.rateFactor=c.pa.modelSampleRate/c.sampleRate;
    assert(abs(source.pa.rateFactor-round(source.pa.rateFactor))<1e-10 && source.pa.rateFactor>=1, ...
        'The trained PA needs an integer modelSampleRate/sampleRate ratio.');
    source.pa.resamplerPassbandFrequency=c.carrierSpacingHz/2+1.5*c.channelBandwidthHz;
    source.pa.resamplerStopbandFrequency=c.sampleRate/2;
    assert(source.pa.resamplerPassbandFrequency<source.pa.resamplerStopbandFrequency);
end
