function gen_nonhomoPoissonProc

% % homogeneous poisson coeff
% y=poissrnd(0.5,1,100);
% y(y>0)=1;
% X=1:100; 
% coeff = glmfit(X, y,'poisson')

%**************************************************************************
%This is the matlab program of non homogeneous Poisson Process.
%Using the Algorithm:-
%(1)Set T(0)=0 and i=1.
%(2)Gnerate an independent random variable U(i)~U(0,1).
%(3)Set T(i+1)=T(i)-(1/lambda)ln(U(i)).
%(4)if T(i)>Tmax, Stop. 
%(5)set lambdat =a*(T(i+1))^(-b); a>0, b<1.
%(6)Gnerate an independent random variable u(i)~U(0,1).
%(7)If u(i)<=lambdat/lambda, set i=i+1 and S(i)=T(i)and go to Step (2).
% i: number of event at time T and S(1),...,S(i): the event times.
% Program is written by Mr. Jitendra Singh (M.Tech student).
%**************************************************************************

lambda=input('Enter The arrival Rate:');   % arrival rate
Tmax=input('Enter maximum time:');         % maximum time
clear T;
T(1)= 0;
a=input('Enter constant a>0:');
b=input('Enter constant b<1:');
S(1)=0;
i=1;

while T(i) < Tmax,
  U(i)=rand(1,1);
  T(i+1)=T(i)-(1/lambda)*(log(U(i)));
  lambdat=a*(T(i+1))^(-b);
  u(i)=rand(1,1);
  if u(i)<=lambdat/lambda
  i=i+1;
  S(i)=T(i);
  end
end
plot(S(1:(i)), 0:(i-1));
title(['A Sample path of the non homogeneous Poisson process']);
xlabel(['Time interval']);
ylabel([' Number of event ']);

%**************************************************************************