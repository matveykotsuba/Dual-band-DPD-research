function w = dbWaveform(c,seed)
    previous=rng; cleanup=onCleanup(@() rng(previous));
    rng(seed,'twister'); n=c.activeSubcarriers;
    indices=c.fftSize/2+1+[-n/2:-1 1:n/2];
    s=struct('fftSize',c.fftSize,'numOfdmSymbols',c.symbolCount, ...
        'cpLengths',c.cpLength*ones(c.symbolCount,1),'wolaLength',c.wolaLength, ...
        'sampleRate',c.sampleRate,'normalCpFirst',c.cpLength,'normalCpOther',c.cpLength);
    power=[1 10^(c.powerImbalanceDb/10)]; power=power/sum(power);
    for b=1:2
        qam=reshape(mapping(randi([0 1],4*n*c.symbolCount,1)),n,[]);
        grid=complex(zeros(c.fftSize,c.symbolCount)); grid(indices,:)=qam;
        time=ifft(ifftshift(grid,1),[],1)*c.fftSize/sqrt(n);
        [x,starts]=wola(time,s);
        scale=10^(-c.inputBackoffDb/20)*sqrt(power(b))/sqrt(mean(abs(x).^2));
        w.bands(:,b)=scale*x; w.qam(:,:,b)=qam; w.scales(b)=scale;
    end
    w.starts=starts; w.activeIndices=indices;
    w.composite=dbCombine(w.bands,c); w.seed=seed;
    if isfield(c.pa,'kind') && strcmp(c.pa.kind,'trained-gmp')
        [~,info]=paModelInput(w.composite,dbSourcePaConfiguration(c));
        w.paInputScale=info.inputScale;
        w.paInputInfo=info;
    end
end
