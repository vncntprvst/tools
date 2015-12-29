%function to calculate area under ROC curve.

%inputs as follows:
%data: spike density functions in the form of an m x n matrix, m = trials,
%n = time, for ONE neuron. PLEASE make window range a number divisible by 100
%baselinewindow: vector in the form [o p] showing which columns of data matrix are defined as baseline period
%please make baseline window a number divisible by 100. (ie. if first 200
%ms of sdf are your baseline period, baselinewindow = [1 200];


function [AUC] = calcAUROC(data,baselinewindow)
n = size(data,2);

if rem(n,100) > 0
    error('Please make the columns of your data matrix a number divisible by 100')
end

if rem(baselinewindow(2),100)>0
    error('Please make size of baseline window a number divisible by 100')
end

iteraterange = reshape(1:n,[],n/100);
colval = baselinewindow(2)/100;
base = data(:,reshape(iteraterange(:,1:colval),1,[]));
base = reshape(base,1,[]);

% compute AUC over 100ms epochs
AUC = zeros(1,size(iteraterange,2)-colval);
for j = colval+1:size(iteraterange,2)
    fr = reshape(data(:,iteraterange(:,j)),1,[]);
    if max(fr)==0 & max(base)==0
        AUC(j-(colval))=0;
    else
        [~,~,AUC(j-(colval))] = simpleROC(base,fr);
    end
end
end