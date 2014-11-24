function K = KernelMatrix(X,kernelfun);
N= numel(X);
K=zeros(N);
for i=1:N
    for j=1:N
        K(i,j)=kernelfun(X(j),X(i));
    end;
end;