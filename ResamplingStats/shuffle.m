function [Y,index] = shuffle(X) 
% [Y,index] = shuffle(X) 
% 
% Randomly sorts X. 
% If X is a vector, sorts all of X, so Y = X(index). 
% If X is an m-by-n matrix, sorts each column of X, so 
% for j=1:n, Y(:,j)=X(index(:,j),j). 
% 
% Also see SORT, Sample, and Randi. 
% 
% xx/xx/92 dh Brainard Wrote it. 
% 10/25/93 dhb Return index. 
% 5/25/96 dgp Made consistent with sort and "for i=Shuffle(1:10)" 
% 6/29/96 dgp Edited comments above. 
[~,index] = sort(rand(size(X))); 
Y = X(index); 