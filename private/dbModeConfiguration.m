function c = dbModeConfiguration(c,kind)
    if strcmp(kind,'none') || ~isfield(c,'modelParameters'), return; end
    assert(isfield(c.modelParameters,kind),'Missing selected parameters for %s.',kind);
    p=c.modelParameters.(kind);
    assert(isequal(sort(fieldnames(p)),sort({'orders';'memoryOrder';'diagonalCount'})), ...
        'Per-mode configuration must contain only orders, memoryOrder and diagonalCount.');
    c.orders=p.orders; c.memoryOrder=p.memoryOrder; c.diagonalCount=p.diagonalCount;
    dbValidate(c);
end
