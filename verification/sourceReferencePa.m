function [y,info] = sourceReferencePa(x,c,sourceRoot)
    assert(strcmpi(fileparts(which('paConfig')),sourceRoot),'Reference did not resolve the original paConfig.');
    cfg=struct('sampleRate',c.sampleRate,'pa',paConfig(true));
    cfg.pa.inputBackoffDb=c.inputBackoffDb;
    cfg.pa.systemSampleRate=c.sampleRate;
    cfg.pa.rateFactor=cfg.pa.modelSampleRate/c.sampleRate;
    cfg.pa.resamplerPassbandFrequency=c.carrierSpacingHz/2+1.5*c.channelBandwidthHz;
    cfg.pa.resamplerStopbandFrequency=c.sampleRate/2;
    [u,info]=paModelInput(x,cfg);
    z=gmpCore(u,cfg.pa);
    y=paSystemOutput(z,numel(x),info.inputScale,info.rateFilter,cfg);
end
