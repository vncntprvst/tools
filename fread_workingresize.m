function mnWav1 = fread_workingresize(fid_bin, dimm, vcDataType)
% obsolete for Matlab 2017+, if not earlier 
% Get around fread bug (matlab) where built-in fread resize doesn't work
% From JRCLUST v3
% James Jun
try
    if isempty(dimm)
        mnWav1 = fread(fid_bin, inf, ['*', vcDataType]);
    else
        mnWav1 = fread(fid_bin, prod(dimm), ['*', vcDataType]);
        if numel(mnWav1) == prod(dimm)
            mnWav1 = reshape(mnWav1, dimm);
        else
            dimm2 = floor(numel(mnWav1) / dimm(1));
            if dimm2 >= 1
                mnWav1 = reshape(mnWav1, dimm(1), dimm2);
            else
                mnWav1 = [];
            end
        end
    end
catch
    disperr_();
end
end %func