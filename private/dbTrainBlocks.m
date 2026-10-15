function [model,h] = dbTrainBlocks(train,validation,kind,c)
    outputs=2; if strcmp(kind,'wideband'), outputs=1; end
    model=struct('kind',kind,'coefficients',{{}});
    for b=1:outputs
        x=train.bands; if outputs==1, x=train.composite; end
        a=dbBasis(x,kind,b,c); model.coefficients{b}=zeros(size(a,2),1); model.coefficients{b}(1)=1;
    end
    count=c.learningBlockCount;
    h=struct('mode','block','blockCount',count,'blockIndex',(0:count).', ...
        'nmseDb',zeros(count+1,1),'accepted',false(count,1),'step',zeros(count,1), ...
        'lambda',NaN(count,outputs),'rejectedByPeak',zeros(count,1), ...
        'firstSample',zeros(count,1),'lastSample',zeros(count,1), ...
        'fitFirstSample',zeros(count,1),'fitLastSample',zeros(count,1));
    h.coefficientHistory=cell(count+1,outputs); h.coefficientHistory(1,:)=model.coefficients;
    h.fitInfo=cell(count,outputs);
    current=dbScore(validation,dbPa(dbDriveLimit(dbApply(validation,model,c),c),c,validation),c);
    h.nmseDb(1)=10*log10(max(current,realmin));
    first=train.starts(2); last=train.starts(end)-1;
    edges=first+floor((0:count)*(last-first+1)/max(count,1));
    guard=c.memoryOrder;
    if isfield(c.pa,'kind') && strcmp(c.pa.kind,'trained-gmp')
        rate=c.pa.modelSampleRate/c.sampleRate;
        guard=guard+ceil(max([c.pa.signalDelays c.pa.envelopeDelays])/rate)+2*c.pa.resamplerNeighbors;
    else
        guard=guard+1;
        if isfield(c.pa,'memoryDelaySamples'), guard=guard+c.pa.memoryDelaySamples-1; end
    end
    h.guardSamples=guard;
    assert(count==0 || min(diff(edges))-2*guard-c.memoryOrder>=5,'Learning blocks are too short for model/filter memory.');
    emitted=train.composite;
    fitCfg=struct('orders',c.orders,'signalDelays',0:c.memoryOrder,'envelopeDelays',0:c.memoryOrder, ...
        'diagonalCount',c.diagonalCount,'regularizationLambdaValues',c.lambdaValues, ...
        'memoryOrder',c.memoryOrder,'batchCorrelationChunkRows',2048);
    for block=1:count
        lo=edges(block); hi=edges(block+1)-1;
        h.firstSample(block)=lo; h.lastSample(block)=hi;
        drive=dbDriveLimit(dbApply(train,model,c),c);
        drive(1:lo-1)=emitted(1:lo-1);
        emitted(lo:hi)=drive(lo:hi);
        feedback=dbPa(drive,c,train);
        if outputs==2, input=dbExtract(feedback,c); target=dbExtract(drive,c);
        else, input=feedback; target=drive; end
        rows=(lo+guard:hi-guard).';
        h.fitFirstSample(block)=rows(1)+c.memoryOrder; h.fitLastSample(block)=rows(end);
        proposal=model;
        for b=1:outputs
            if strcmp(kind,'dual')
                fitCfg.bandIndex=b;
                [proposal.coefficients{b},info]=dbDualBatchFit(target(rows,b),input(rows,:),fitCfg);
            else
                [coefficients,info]=dpdBatchFit(target(rows,b),input(rows,b),fitCfg);
                proposal.coefficients{b}=coefficients(info.activeIndices);
            end
            h.lambda(block,b)=info.bestLambda; h.fitInfo{block,b}=info;
        end
        best=model; bestScore=current; selectedStep=0;
        for step=c.stepSizes
            candidate=model;
            for b=1:outputs
                candidate.coefficients{b}=(1-step)*model.coefficients{b}+step*proposal.coefficients{b};
            end
            if any(cellfun(@(z) any(~isfinite(z)) || norm(z)>c.maximumCoefficientNorm,candidate.coefficients)), continue; end
            u=dbApply(validation,candidate,c);
            if any(~isfinite(u)) || max(abs(u))>c.maximumDrivePeak
                h.rejectedByPeak(block)=h.rejectedByPeak(block)+1; continue;
            end
            score=dbScore(validation,dbPa(u,c,validation),c);
            if isfinite(score) && score<bestScore
                best=candidate; bestScore=score; selectedStep=step;
            end
        end
        model=best; current=bestScore;
        h.accepted(block)=selectedStep>0; h.step(block)=selectedStep;
        h.nmseDb(block+1)=10*log10(max(current,realmin));
        h.coefficientHistory(block+1,:)=model.coefficients;
        fprintf('%s ILA block %d/%d [%d:%d]: monitor NMSE %.3f dB; step=%.5g\n',kind,block,count,lo,hi,h.nmseDb(block+1),selectedStep);
    end
    h.emittedDrive=emitted;
end
