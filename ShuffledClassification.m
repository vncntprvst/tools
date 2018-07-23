function [classification, timing]=ShuffledClassification(trialsData,numShuffles)
if nargin<2
    numShuffles=10000;
end

%% count the fraction of trials during which a particular time bin had calcium events
numTrials=size(trialsData,1);  
caEventFraction=sum(logical(trialsData))/numTrials;
% figure; plot(caEventFraction);

%% shuffle calcium events in time to build null distribution.
trialsData=num2cell(trialsData',1);
nullDdistrib=nan(numShuffles,1);
% shuffle numShuffles times, find max value
for shuffleNum=1:numShuffles    
    nullDdistrib(shuffleNum)=max(sum(logical(cell2mat(cellfun(@(x) x(randperm(10)),...
        trialsData,'UniformOutput', false))'))/numTrials);
end

%much faster shuffle: http://www.mathworks.com/matlabcentral/fileexchange/27076-shuffle

%% Find 95th percentile 
sem = std(nullDdistrib)/sqrt(numShuffles);
confidenceInterval = mean(nullDdistrib) + sem*1.96;                      

%% compare actual peak to 95th percentile of the shuffled peaks
if max(caEventFraction(16:end))>confidenceInterval %restricted to pre-post movement
    classification=1;
    timing=[find(caEventFraction>confidenceInterval,1);... % (16:end)
        find(caEventFraction>=max(caEventFraction(16:end)),1)]; % (16:end)
else
    classification=0;
    timing=[NaN;NaN];
end

