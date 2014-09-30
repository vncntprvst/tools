function c = correlation(mat)
tmp = corrcoef(mat(:,1),mat(:,2));
c = tmp(1,2);