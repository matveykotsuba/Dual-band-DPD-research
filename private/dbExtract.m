function bands = dbExtract(x,c)
    x=x(:); t=(0:numel(x)-1).'/c.sampleRate;
    centers=[-1 1]*c.carrierSpacingHz/2;
    bands=dbLowpass(x.*exp(-2i*pi*t*centers),c);
end
