function choice = dbSelectProfile(values,nmse,threshold,rule)
    values=values(:); nmse=nmse(:);
    assert(numel(values)==numel(nmse) && ~isempty(values));
    assert(all(isfinite(nmse)) && all(diff(values)>0));
    improvement=[NaN;nmse(1:end-1)-nmse(2:end)];
    [best,bestIndex]=min(nmse);
    if strcmp(rule,'increment')
        stop=find(improvement<threshold,1,'first');
        if isempty(stop), index=numel(values); else, index=stop-1; end
        stopped=~isempty(stop);
    else
        assert(strcmp(rule,'tolerance'));
        index=find(nmse<=best+threshold,1,'first'); stopped=true; stop=[];
    end
    choice=struct('values',values,'nmseDb',nmse,'improvementDb',improvement, ...
        'selectedIndex',index,'selectedValue',values(index),'selectedNmseDb',nmse(index), ...
        'bestValue',values(bestIndex),'bestNmseDb',best,'gapToBestDb',nmse(index)-best, ...
        'stoppingIndex',stop,'thresholdReached',stopped,'rule',rule,'thresholdDb',threshold);
end
