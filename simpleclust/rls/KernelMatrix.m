function K = KernelMatrix(X,kernelfun);
[N,d] = size(X);
K=zeros(N);
for i=1:N
    for j=1:N
        K(i,j)=kernelfun(X(i,:),X(j,:));
    end;
end;