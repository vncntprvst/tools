function classification=ShuffledClassification(trialsData)
% counted the fraction of trials during which a particular time bin had calcium events
numTrials=size(trialsData,1);  
caEventFraction=sum(logical(trialsData))/numTrials;
% figure; plot(caEventFraction);

% shuffle calcium events in time to build null distribution.
trialsData=num2cell(trialsData',1);
nullDdistrib=nan(10000,1);
% shuffle 10,000 times 
for shuffleNum=1:10000    
    nullDdistrib(shuffleNum)=max(sum(logical(cell2mat(cellfun(@(x) x(randperm(10)),...
        trialsData,'UniformOutput', false))'))/numTrials);
end

%much faster shuffle: http://www.mathworks.com/matlabcentral/fileexchange/27076-shuffle

% Find 95th percentile 
sem = std(nullDdistrib)/sqrt(10000);
confidenceInterval = mean(nullDdistrib) + sem*1.96;                      

% compare actual peak to 95th percentile of the shuffled peaks
if max(caEventFraction(16:end))>confidenceInterval
    classification=1;
else
    classification=0;
end

