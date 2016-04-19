function [dprime,crit] = SigDetecPerformance(hitRate,falseAlarm)
[dprime,crit]=deal(nan(max(size(hitRate)),1));
for perfNum=1:max(size(hitRate))
    % Evaluate performance using a measure of discriminability (d') and
    % the estimated Decision Criterion c.
    % In the context of behavioral training, d' should reach or surpass
    % 1.5 for six consecutive sessions
    
    % Discriminability may be computed from the observed Hit Rate and
    % False Alarm pairs of conditional probability:
    %   hitRate = hit rate (0 < hitRate < 1)
    %   falseAlarm = false alarm rate (0 < falseAlarm < 1)
    dprime(perfNum) = norminv(hitRate(perfNum))-norminv(falseAlarm(perfNum));
    
    % The decision criterion may be expressed in terms of a critical output
    % of the sensory process:
    crit(perfNum) = (norminv(hitRate(perfNum))+ norminv(falseAlarm(perfNum)))./-2;
end
end