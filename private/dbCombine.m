function x = dbCombine(bands,c)
    t=(0:size(bands,1)-1).'/c.sampleRate;
    centers=[-1 1]*c.carrierSpacingHz/2;
    x=sum(bands.*exp(2i*pi*t*centers),2);
end
