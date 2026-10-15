function u = dbApply(w,model,c)
    if strcmp(model.kind,'none'), u=w.composite; return; end
    if strcmp(model.kind,'wideband')
        u=dbBasis(w.composite,model.kind,1,c)*model.coefficients{1};
    else
        bands=complex(zeros(size(w.bands)));
        for b=1:2, bands(:,b)=dbBasis(w.bands,model.kind,b,c)*model.coefficients{b}; end
        u=dbCombine(w.bands+dbLowpass(bands-w.bands,c),c);
    end
end
