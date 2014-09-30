%Permutation Test for Matched Pairs
%Before vs After Treatment Scores frpm Moore, et al. (2003), page 18-61

% clear all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% correlated Before/After treatment performance scores eg18_015 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
before = [32 31 29 10 30 33 22 25 32 20 30 20 24 24 31 30 15 32 23 23];
after =  [34 31 35 16 33 36 24 28 26 26 36 26 27 24 32 31 15 34 26 26];
bivariate = [before',after'];

%seed the random number generator
rand('state',sum(100*clock));

% traditional 1-tailed correlated t-test
[h,p,ci,stats]=ttest(after,before,0.01,'right');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use Resampling to generate Permutation Distribution           %
% of Difference between Correlated Means                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                               %
% 1. Generate list of subjects to resample (with replacement)   %
% 2. Randomly assign each resampled subject's bivariate data to %
%       the before vs. after treatment pool (null hypothesis)   %
% 3. Compute the means for the before vs. after pools           %
% 4. Compute difference between after-before resampled means    %
% 5. Repeat steps 1-4 for 1000 iterations                       %
% 6. Generate and apply the permutation distribution            %
%                                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
samplesize = length(before);
subjects = [1:samplesize];
n_resamples=20000;
for i=1:n_resamples
    %clean-up
    clear s1; clear before_pool; clear after_pool;
    %resample N subjects (with replacement)
    s1 = randsample(samplesize, samplesize, true);
    %randomly assign subjects' bivariate sample pairs to before vs. after pool
    before_assignments = randsample(2, samplesize, true);
    after_assignments = 2-floor(before_assignments/2);
    for n=1:samplesize
        before_pool(n) = bivariate(s1(n),before_assignments(n));
        after_pool(n)  = bivariate(s1(n),after_assignments(n));
    end
    %compute difference between after-before means
    %and add it to the accummulating permutation distribution
    remdiff(i)=mean(after_pool)-mean(before_pool);
end
%
%
%
%compute and display summary statistics
remean=mean(remdiff);  %permutation distribution mean
restderr=std(remdiff); %permutation distribution standard error
remdiff=remdiff';
%percentile cutoffs
p1=prctile(remdiff,1);
p25=prctile(remdiff,2.5);
p5=prctile(remdiff,5);
p95=prctile(remdiff,95);
p975=prctile(remdiff,97.5);
p99=prctile(remdiff,99);
%results of traditional t-test
delta=mean(after)-mean(before);
display(['Difference between Observed Means']);
display(['t-test:  ',num2str(stats.tstat)])
display(['p-level: ',num2str(p)])
display(['df:      ',num2str(stats.df)])
display(['sd:      ',num2str(stats.sd)])
%determine exact probability of mean1-mean2 sampling distribution
[cumprob,statval]=ecdf(remdiff);
temp=abs(statval-delta);
index=find(temp==min(temp));
exactp=cumprob(index);
%annotate figure
display('Permutation Distribution Summary statistics:');
display(['Mean:        ',num2str(remean)]);
display(['Std. Error:  ',num2str(restderr)]);
display(['Mt-Mc:       ',num2str(delta)]);
display(['exact-prob:  ',num2str(1-exactp(1))]);
display(['1st  %ile:   ',num2str(p1)]);
display(['2.5  %ile:   ',num2str(p25)]);
display(['5th  %ile:   ',num2str(p5)]);
display(['95th %ile:   ',num2str(p95)]);
display(['97.5 %ile:   ',num2str(p975)]);
display(['99th %ile:   ',num2str(p99)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot bootstrap distribution with parametric overlay %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear n; clear gains;
gains=[min(remdiff):0.2:max(remdiff)]; %data bins
n=histc(remdiff,gains);
figure(1); clf;
subplot(1,2,1);
set(gcf,'PaperPositionMode','auto');
set(gcf,'Position',[30 100 1000 600]);
bar(gains,n,'k');
hold on;
axis([-5 5 0 max(n)+2]);
xlabel('delta Permutation Means');
ylabel('Frequency');
title_str(1)={['Permutation Distribution of Difference between Correlated Means']};
title_str(2)={'Hesterberg Example 18.15  [MATLAB: h15.m]'};
title_str(3)={['(Number of Resamples = ',num2str(n_resamples),')']};
title(title_str);
%annotate randomization distribution
f11str(1)={['Mean     : ',num2str(remean)]};
f11str(2)={['Std. Err:  ',num2str(restderr)]};
f11str(3)={['Mt-Mc:     ',num2str(delta)]};
f11str(4)={['exact prob ',num2str(1-exactp(1))]};
%f11str(3)={['1st  %ile:   ',num2str(p1)]};
%f11str(4)={['5th  %ile:   ',num2str(p5)]};
%f11str(5)={['95th %ile:   ',num2str(p95)]};
%f11str(6)={['99th %ile:   ',num2str(p99)]};
text(-4.5,max(n)*.85,f11str);
%generate normal-quantile plot to assess normality
subplot(1,2,2);
qqplot(remdiff);
hold on;
ylabel('delta Permutation Means');
title('');
hold off;
