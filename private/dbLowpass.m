function y = dbLowpass(x,c)
    n=size(x,1); f=(-floor(n/2):ceil(n/2)-1).'*c.sampleRate/n;
    mask=abs(f)<=c.feedbackHalfBandwidthHz;
    y=ifft(ifftshift(bsxfun(@times,fftshift(fft(x),1),mask),1));
end
