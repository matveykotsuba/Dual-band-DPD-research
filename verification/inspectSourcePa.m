function inspectSourcePa()
    root=fileparts(fileparts(mfilename('fullpath')));
    s=load(fullfile(root,'private','paModel.mat'));
    disp(s.fitInfo);
    fprintf('COEFFICIENT_MATRIX %d %d\n',size(s.coefficientsTikhonov));
    fprintf('SOURCE_PA_INSPECT_PASS\n');
end
