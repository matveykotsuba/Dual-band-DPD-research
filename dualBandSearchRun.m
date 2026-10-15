function study = dualBandSearchRun(search)
    if nargin<1, search=dualBandSearchConfig(); end
    c=search.configuration; dbValidate(c);
    assert(~isfield(c,'modelParameters'),'Start search with an unselected base configuration.');
    p=search.polynomialOrders(:).'; memories=search.memoryOrders(:).';
    assert(numel(p)>=2 && all(p>=3) && all(mod(p,2)==1) && all(diff(p)==2));
    assert(numel(memories)>=2 && memories(1)==0 && all(diff(memories)==1));
    for field={'polynomialThresholdDb','memoryThresholdDb','diagonalToleranceDb'}
        validateattributes(search.(field{1}),{'numeric'},{'scalar','positive','finite'});
    end
    validateattributes(search.maximumCoordinateIterations,{'numeric'},{'scalar','integer','positive'});
    extreme=c; extreme.orders=1:2:max(p); extreme.memoryOrder=max(memories); extreme.diagonalCount=max(memories);
    dbValidate(extreme); % Fail before training if the requested basis may alias.
    directory=c.outputDirectory; if ~exist(directory,'dir'), mkdir(directory); end
    checkpoint=fullfile(directory,'searchCheckpoint.mat');
    signature=rmfield(c,{'showPlots','saveResults','outputDirectory'});
    methodVersion=1; entries=struct([]); profiles=struct(); selected=struct();
    if search.resume && exist(checkpoint,'file')
        saved=load(checkpoint,'state');
        assert(saved.state.methodVersion==methodVersion && isequaln(saved.state.signature,signature), ...
            'Checkpoint settings differ. Use a new outputDirectory or resume=false.');
        entries=saved.state.entries;
        fprintf('Resuming %d cached candidates.\n',numel(entries));
    end
    train=dbWaveform(c,c.seeds(1)); validation=dbWaveform(c,c.seeds(2));
    kinds={'independent','wideband','dual'};
    status=struct();
    for k=1:numel(kinds)
        kind=kinds{k}; currentP=p(1); currentM=0; history=zeros(0,2); stable=false;
        for iteration=1:search.maximumCoordinateIterations
            polynomial=profile(kind,'P',p,currentP,currentM,0,search.polynomialThresholdDb,'increment');
            nextP=polynomial.selectedValue;
            memory=profile(kind,'M',memories,nextP,currentM,0,search.memoryThresholdDb,'increment');
            nextM=memory.selectedValue;
            history(end+1,:)=[nextP nextM];
            if nextP==currentP && nextM==currentM, stable=true; break; end
            if size(history,1)>1 && any(all(bsxfun(@eq,history(1:end-1,:),[nextP nextM]),2))
                break; % Explicit nonconvergence, not silent selection on a cycle.
            end
            currentP=nextP; currentM=nextM;
        end
        diagonal=profile(kind,'d',0:nextM,nextP,nextM,0,search.diagonalToleranceDb,'tolerance');
        parameters=struct('orders',1:2:nextP,'memoryOrder',nextM,'diagonalCount',diagonal.selectedValue);
        selected.(kind)=parameters;
        profiles.(kind)=struct('polynomial',polynomial,'memory',memory,'diagonal',diagonal,'coordinateHistory',history);
        status.(kind)=struct('coordinateConverged',stable, ...
            'polynomialThresholdReached',polynomial.thresholdReached,'memoryThresholdReached',memory.thresholdReached, ...
            'criteriaSatisfied',stable && polynomial.thresholdReached && memory.thresholdReached);
        fprintf('SELECTED %s: P=%d M=%d d=%d; criteria satisfied=%d\n',kind,nextP,nextM,diagonal.selectedValue,status.(kind).criteriaSatisfied);
    end
    mode=kinds(:); P=zeros(3,1); M=P; d=P; K=P; nmse=P; gap=P; criteria=false(3,1);
    for k=1:3
        param=selected.(kinds{k}); entry=evaluate(kinds{k},param.orders(end),param.memoryOrder,param.diagonalCount);
        P(k)=param.orders(end); M(k)=param.memoryOrder; d(k)=param.diagonalCount;
        K(k)=entry.coefficientCount; nmse(k)=entry.validationNmseDb;
        criteria(k)=status.(kinds{k}).criteriaSatisfied;
        same=strcmp({entries.kind},kinds{k}); gap(k)=nmse(k)-min([entries(same).validationNmseDb]);
    end
    summary=table(mode,P,M,d,K,nmse,gap,criteria,'VariableNames', ...
        {'Mode','P','M','d','Coefficients','ValidationNMSE_dB','GapToBestVisited_dB','CriteriaSatisfied'});
    configured=c; configured.modelParameters=selected;
    study=struct('search',search,'methodVersion',methodVersion,'profiles',profiles,'entries',entries, ...
        'selectedParameters',selected,'status',status,'summary',summary,'selectedConfiguration',configured, ...
        'allCriteriaSatisfied',all(criteria));
    study.selectionRule='P/M first improvement below 0.20/0.05 dB on d=0, then smallest d within 0.05 dB of best; configured thresholds stored in search';
    save(fullfile(directory,'parameterSearch.mat'),'study','-v7');
    writetable(summary,fullfile(directory,'selectedParameters.csv')); disp(summary);
    candidateTable=table({entries.kind}.',[entries.P].',[entries.M].',[entries.d].', ...
        [entries.coefficientCount].',[entries.validationNmseDb].', ...
        'VariableNames',{'Mode','P','M','d','Coefficients','ValidationNMSE_dB'});
    writetable(candidateTable,fullfile(directory,'visitedCandidates.csv'));
    if c.showPlots, dualBandSearchPlot(study); end
    if ~study.allCriteriaSatisfied
        warning('dualBandSearchRun:Incomplete','Boundary or coordinate convergence not resolved. Saved profiles; no final test comparison. Extend the search.');
        return;
    end
    configured.outputDirectory=fullfile(directory,'selected_comparison');
    study.comparison=dualBandRun(configured);
    save(fullfile(directory,'parameterSearch.mat'),'study','-v7');
    fprintf('DUAL_BAND_PARAMETER_SEARCH_PASS\n');

    function result=profile(kind,axisName,values,P0,M0,d0,threshold,rule)
        scores=zeros(numel(values),1); counts=scores;
        for j=1:numel(values)
            P1=P0; M1=M0; d1=d0;
            switch axisName
                case 'P', P1=values(j);
                case 'M', M1=values(j);
                case 'd', d1=values(j);
            end
            item=evaluate(kind,P1,M1,d1); scores(j)=item.validationNmseDb; counts(j)=item.coefficientCount;
        end
        result=dbSelectProfile(values,scores,threshold,rule);
        result.coefficientCount=counts; result.fixedP=P0; result.fixedM=M0; result.fixedD=d0;
    end

    function entry=evaluate(kind,P0,M0,d0)
        index=[];
        if ~isempty(entries)
            index=find(strcmp({entries.kind},kind) & [entries.P]==P0 & [entries.M]==M0 & [entries.d]==d0,1);
        end
        if ~isempty(index), entry=entries(index); return; end
        candidate=c; candidate.orders=1:2:P0; candidate.memoryOrder=M0; candidate.diagonalCount=d0; dbValidate(candidate);
        fprintf('SEARCH %s P=%d M=%d d=%d\n',kind,P0,M0,d0); started=tic;
        [model,h]=dbTrain(train,validation,kind,candidate);
        drive=dbApply(validation,model,candidate); [drive,limit]=dbDriveLimit(drive,candidate);
        metrics=dbMetrics(validation,dbPa(drive,candidate,validation),candidate);
        entry=struct('kind',kind,'P',P0,'M',M0,'d',d0,'coefficientCount',sum(cellfun(@numel,model.coefficients)), ...
            'validationNmseDb',h.nmseDb(end),'validationMetrics',metrics,'history',h, ...
            'model',model,'validationClippedFraction',limit.clippedFraction,'seconds',toc(started));
        if isempty(entries), entries=entry; else, entries(end+1)=entry; end
        state=struct('methodVersion',methodVersion,'signature',signature,'entries',entries);
        temporary=[checkpoint '.tmp.mat']; save(temporary,'state','-v7'); movefile(temporary,checkpoint,'f');
    end
end
