function score = dbScore(w,y,c)
    bands=dbExtract(y,c); rows=(w.starts(2):w.starts(end)-1).';
    score=mean(sum(abs(bands(rows,:)-w.bands(rows,:)).^2,1)./sum(abs(w.bands(rows,:)).^2,1));
end
