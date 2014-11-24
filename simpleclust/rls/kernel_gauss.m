function d = kernel_gauss(a,b);
sigma = 500000;

N=size(a,1);
if N==1
    d=exp(-( (sum((a-b).^2)) ./ (sigma^2) ));
else
   d=exp(-(      sum(  ( a-repmat(b,[N 1]))'.^2  )   ./ (sigma^2)     ))';
end;
