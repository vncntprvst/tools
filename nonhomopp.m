function x=nonhomopp(intens,T)
%generate a nonhomogeneousl poisson process on [0,T] with intensity function intens
% e.g. t=7+nonhomopp('100-10*',5)
x=0:.1:T;
l=eval([intens 'x']);
lam0=max(l);  % this is used to generate homogeneouos poisson process
u=rand(1,ceil(1.5*T*lam0));  
x=cumsum(-(1/lam0)*log(u));    %points of homogeneous pp
x=x(x<T);  n=length(x);   % select those points less than T
l=eval([intens 'x']);      % evaluates intensity function
x=x(rand(1,n)<l/lam0);     % filter out some points
 hist(x,10)