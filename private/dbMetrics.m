function v = dbMetrics(w,y,c)
    [v.frequency,v.psd]=welch(y(w.starts(2):w.starts(end)-1),c.sampleRate,c.psdSegmentLength);
    centers=[-1 1]*c.carrierSpacingHz/2; bw=c.channelBandwidthHz;
    bands=dbExtract(y,c); rows=w.starts(2):w.starts(end)-1;
    for b=1:2
        reference=w.bands(rows,b); measured=bands(rows,b);
        v.nmseDb(b)=10*log10(max(sum(abs(measured-reference).^2)/sum(abs(reference).^2),realmin));
        recovered=complex(zeros(c.activeSubcarriers,c.symbolCount-2));
        for s=2:c.symbolCount-1
            start=w.starts(s)+c.cpLength;
            z=bands(start:start+c.fftSize-1,b);
            grid=fftshift(fft(z))*sqrt(c.activeSubcarriers)/c.fftSize/w.scales(b);
            recovered(:,s-1)=grid(w.activeIndices);
        end
        q=w.qam(:,2:end-1,b); q=q(:); r=recovered(:);
        gain=(q'*r)/(q'*q);
        if abs(gain)<eps, v.evmPercent(b)=Inf;
        else, v.evmPercent(b)=100*sqrt(sum(abs(r/gain-q).^2)/sum(abs(q).^2)); end
        v.equalizerGain(b)=gain;
        main=abs(v.frequency-centers(b))<bw/2;
        left=abs(v.frequency-(centers(b)-bw))<bw/2;
        right=abs(v.frequency-(centers(b)+bw))<bw/2;
        p=sum(v.psd(main));
        v.aclrLeftDb(b)=10*log10(max(p,realmin)/max(sum(v.psd(left)),realmin));
        v.aclrRightDb(b)=10*log10(max(p,realmin)/max(sum(v.psd(right)),realmin));
        v.aclrWorstDb(b)=min(v.aclrLeftDb(b),v.aclrRightDb(b));
        v.bandPower(b)=p*(v.frequency(2)-v.frequency(1));
    end
    v.totalPower=mean(abs(y(rows)).^2);
    v.paprDb=10*log10(max(abs(y(rows)).^2)/v.totalPower);
end
