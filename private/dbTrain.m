function [model,h] = dbTrain(train,validation,kind,c)
    if isfield(c,'learningBlockCount')
        [model,h]=dbTrainBlocks(train,validation,kind,c); return;
    end
    model.kind=kind; model.coefficients={};
    outputs=2; if strcmp(kind,'wideband'), outputs=1; end
    for b=1:outputs
        x=train.bands; if outputs==1, x=train.composite; end
        a=dbBasis(x,kind,b,c); model.coefficients{b}=zeros(size(a,2),1); model.coefficients{b}(1)=1;
    end
    h.nmseDb=zeros(c.iterations+1,1); h.accepted=false(c.iterations,1);
    h.lambda=NaN(c.iterations,1); h.step=zeros(c.iterations,1);
    h.rejectedByPeak=zeros(c.iterations,1);
    current=dbScore(validation,dbPa(dbDriveLimit(dbApply(validation,model,c),c),c,validation),c);
    h.nmseDb(1)=10*log10(max(current,realmin));
    rows=train.starts(2):train.starts(end)-1;
    for iteration=1:c.iterations
        drive=dbDriveLimit(dbApply(train,model,c),c); feedback=dbPa(drive,c,train);
        if outputs==2, input=dbExtract(feedback,c); target=dbExtract(drive,c);
        else, input=feedback; target=drive; end
        fits=cell(1,outputs);
        for b=1:outputs
            basis=dbBasis(input,kind,b,c); a=basis(rows,:); z=target(rows,b);
            scale=sqrt(mean(abs(a).^2,1)); scale(scale<eps)=1;
            a=bsxfun(@rdivide,a,scale);
            gram=a'*a/size(a,1); gram=(gram+gram')/2; rhs=a'*z/size(a,1);
            fits{b}=complex(zeros(size(a,2),numel(c.lambdaValues)));
            for k=1:numel(c.lambdaValues)
                fits{b}(:,k)=((gram+c.lambdaValues(k)*eye(size(gram)))\rhs)./scale.';
            end
        end
        best=model; bestScore=current; selectedLambda=NaN; selectedStep=0;
        for k=1:numel(c.lambdaValues)
            for step=c.stepSizes
                candidate=model;
                for b=1:outputs
                    candidate.coefficients{b}=(1-step)*model.coefficients{b}+step*fits{b}(:,k);
                end
                u=dbApply(validation,candidate,c);
                if any(~isfinite(u)) || max(abs(u))>c.maximumDrivePeak
                    h.rejectedByPeak(iteration)=h.rejectedByPeak(iteration)+1;
                    continue
                end
                score=dbScore(validation,dbPa(u,c,validation),c);
                if isfinite(score) && score<bestScore*(1-1e-9)
                    best=candidate; bestScore=score; selectedLambda=c.lambdaValues(k); selectedStep=step;
                end
            end
        end
        model=best; current=bestScore;
        h.accepted(iteration)=selectedStep>0; h.lambda(iteration)=selectedLambda; h.step(iteration)=selectedStep;
        h.nmseDb(iteration+1)=10*log10(max(current,realmin));
        fprintf('%s ILA %d/%d: validation NMSE %.3f dB; step=%.5g; peak rejects=%d\n',kind,iteration,c.iterations,h.nmseDb(iteration+1),selectedStep,h.rejectedByPeak(iteration));
    end
end
