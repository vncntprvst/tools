function m=nonanstd(y)
%m=nonanstd(y)
%Calculates std of matrix m, ignoring nans.

for i=1:size(y,2)
	m(i)=std(y(~isnan(y(:,i)),i));
end