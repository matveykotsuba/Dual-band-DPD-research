function results = dualBandRun(cfg)
    if nargin<1, cfg=dualBandConfig(); end
    if isfield(cfg.pa,'kind') && strcmp(cfg.pa.kind,'trained-gmp'), cfg.pa.inputBackoffDb=cfg.inputBackoffDb; end
    dbValidate(cfg);
    train=dbWaveform(cfg,cfg.seeds(1)); validation=dbWaveform(cfg,cfg.seeds(2));
    test=dbWaveform(cfg,cfg.seeds(3));
    modes={'none','independent','wideband','dual'};
    results.configuration=cfg; results.reference=dbMetrics(test,test.composite,cfg);
    paName='synthetic'; if isfield(cfg.pa,'kind'), paName=cfg.pa.kind; end
    results.description=[paName ' common PA; held-out OFDM seed; fixed unit target gain; per-band gain-corrected QAM EVM'];
    fprintf('PA mode: %s\n',paName);
    if strcmp(paName,'trained-gmp')
        fprintf('Frozen source PA: P=%d, M=%d, d=%d, Fs=%.2f MHz, backoff=%.2f dB. No PA fitting.\n', ...
            max(cfg.pa.orders),max([cfg.pa.signalDelays cfg.pa.envelopeDelays]),cfg.pa.diagonalCount,cfg.pa.modelSampleRate/1e6,cfg.inputBackoffDb);
    end
    mode={}; band=[]; evm=[]; aclr=[]; left=[]; right=[]; nmse=[]; coefficients=[]; applyMs=[]; paInputPower=[]; bandOutputPower=[]; clipped=[];
    for k=1:numel(modes)
        kind=modes{k}; modeCfg=dbModeConfiguration(cfg,kind); start=tic;
        if strcmp(kind,'none'), model=struct('kind',kind,'coefficients',{{}}); history=struct();
        else, [model,history]=dbTrain(train,validation,kind,modeCfg); end
        trainingSeconds=toc(start);
        timings=zeros(3,1);
        for repeat=1:3, start=tic; u=dbApply(test,model,modeCfg); timings(repeat)=toc(start); end
        [u,limitInfo]=dbDriveLimit(u,cfg);
        if limitInfo.clippedFraction>0
            fprintf('%s: fixed drive limit clipped %.6f %% of test samples; raw peak %.5f. No test retuning.\n',kind,100*limitInfo.clippedFraction,limitInfo.rawPeak);
        end
        [y,paInfo]=dbPa(u,cfg,test); metrics=dbMetrics(test,y,cfg);
        if isfield(paInfo,'aboveTrainingMagnitudeFraction') && paInfo.aboveTrainingMagnitudeFraction>0
            warning('dualBandRun:PaExtrapolation','%s: %.4f %% of PA model input samples exceed the training magnitude.',kind,100*paInfo.aboveTrainingMagnitudeFraction);
        end
        count=sum(cellfun(@numel,model.coefficients));
        result=struct('model',model,'history',history,'metrics',metrics,'trainingSeconds',trainingSeconds, ...
            'applicationSeconds',median(timings),'coefficientCount',count, ...
            'drivePower',mean(abs(u).^2),'drivePeak',max(abs(u)),'driveLimit',limitInfo, ...
            'weightedComplexMacPerSecond',count*cfg.sampleRate);
        result.configuration=modeCfg;
        result.paInfo=paInfo;
        results.(kind)=result;
        for b=1:2
            mode{end+1,1}=kind; band(end+1,1)=b; evm(end+1,1)=metrics.evmPercent(b);
            aclr(end+1,1)=metrics.aclrWorstDb(b); left(end+1,1)=metrics.aclrLeftDb(b); right(end+1,1)=metrics.aclrRightDb(b);
            nmse(end+1,1)=metrics.nmseDb(b); coefficients(end+1,1)=count; applyMs(end+1,1)=1e3*median(timings);
            paInputPower(end+1,1)=mean(abs(u).^2); bandOutputPower(end+1,1)=metrics.bandPower(b);
            clipped(end+1,1)=100*limitInfo.clippedFraction;
        end
    end
    results.summary=table(mode,band,evm,aclr,left,right,nmse,coefficients,applyMs,paInputPower,bandOutputPower,clipped, ...
        'VariableNames',{'Mode','Band','EVM_percent','ACLR_worst_dB','ACLR_left_dB','ACLR_right_dB','NMSE_dB','CoefficientsTotal','Apply_ms','PA_input_power','Band_output_power','Drive_clipped_percent'});
    disp(results.summary);
    if cfg.saveResults
        if ~exist(cfg.outputDirectory,'dir'), mkdir(cfg.outputDirectory); end
        save(fullfile(cfg.outputDirectory,'dualBandResults.mat'),'results','-v7');
        writetable(results.summary,fullfile(cfg.outputDirectory,'comparison.csv'));
    end
    if cfg.showPlots, dualBandPlot(results); end
end
