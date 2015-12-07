function [FPR,TPR,AUC] = simpleROC(baseline,fr)
a = max(baseline);
b = max(fr);
maxcrit = max([a b]);
FPR = zeros(1,length(0:ceil(maxcrit)));
TPR = FPR;
range = fliplr(0:ceil(maxcrit));

for i = 1:length(range)
    crit = range(i);
    temp1 = length(find(baseline>crit))/length(baseline);
    temp2 = length(find(fr>crit))/length(fr);
    FPR(i) = temp1;
    TPR(i) = temp2;
end
   
AUC = trapz(FPR,TPR);
end
