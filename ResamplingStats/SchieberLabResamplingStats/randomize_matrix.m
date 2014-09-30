function [table] = randomize_matrix(table)
%
%  Randomize row positions while maintaining column order
%     usage:
%     [matrix] = randomize_matrix( matrix )
%        where:
%        matrix = [m x n] matrix, or
%                 [m x 1] column vector

%seed the random number generator
rand('state',sum(100*clock));
[nrows,ncols] = size(table);
count = 10 * nrows; %number of randomized pair swaps to execute
while (count > 0)
    %randomly select a pair of rows
    %fix() rounds-down to the nearest integer
    pos1 = 1+fix(nrows * rand);  
    pos2 = 1+fix(nrows * rand);
    %swap the randomly selected rows
    temp = table(pos1);
    table(pos1) = table(pos2);
    table(pos2) = temp;
    %decrement swap counter
    count = count - 1;
end

%another approach to creating a randomized list is to use randperm()
%as follows.  However, experimentation with this approach suggests
%that the randomization algorithm appears to "neglect" the early
%items in the list...Anyway, that's my opinion and I'm sticking with it.
%
%rand('state',sum(100 * clock)); %seed random number generator
%order=randperm(10); %create randomized list for numbers 1 thru 10