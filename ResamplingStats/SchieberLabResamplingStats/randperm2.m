function [s1,s2]=randperm2(universe,n1)
%
% [s1,s2] = randperm2(universe,n1)
% Generates two permutation samples taken from 'universe'.
% Sample 's1' has a size equal to 'n1'.
% The size of 's2' = length(universe)-n1.

%make sure to previously seed the random number generator as per:
%rand('state',sum(100*clock));

n=numel(universe);
n2=n-n1;
rp=randperm(n);
y=rp(1:n1);
s1=universe(y);
y2=rp(n1+1:n);
s2=universe(y2);
