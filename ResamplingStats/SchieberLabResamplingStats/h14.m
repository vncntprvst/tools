%Hesterberg - Example 18.14
%Permutation Test of Verizon (ILEC) versus CLEC Service Times

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read Customer Service Times (hours) %
% N_Verizon=1665  N_CLEC = 23         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
fid=fopen([pwd,'\data\eg18_014.txt']);
fgetl(fid);  %skip header line
AoA=textscan(fid,'%d%s'); %read Numeric and Text columns from data file
stimes=AoA{1};   %extract service time data
providers=AoA{2}; %extract Service Provider labels
fclose(fid);

%build ILEC and CLEC samples
ilec=double(stimes(1:1664));
clec=double(stimes(1665:1687));

%seed the random number generator
rand('state',sum(100*clock));

% traditional 1-tailed t-test
[h,p,ci,stats]=ttest2(ilec,clec,0.01,'left');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use Resampling to generate Permutation Distribution %
% of Difference between Means                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
samplesize1=1664;
samplesize2=23;
n_resamples=10000;
stimes=randomize_matrix(stimes); %shuffle pseudo-population first
for i=1:n_resamples
    %generate permutation samples
    [s1,s2]=randperm2(stimes,samplesize1);
    %compute/save difference between permutation sample means
    remdiff(i)=mean(s1)-mean(s2);
end
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
display('Permutation Test Summary statistics:');
display(['Mean (BIAS): ',num2str(remean)]);
display(['Std. Error:  ',num2str(restderr)]);
display(['1st  %ile:   ',num2str(p1)]);
display(['2.5  %ile:   ',num2str(p25)]);
display(['5th  %ile:   ',num2str(p5)]);
display(['95th %ile:   ',num2str(p95)]);
display(['97.5 %ile:   ',num2str(p975)]);
display(['99th %ile:   ',num2str(p99)]);
display(' ');
delta=mean(ilec)-mean(clec);
display(['Difference between Observed Means = ',num2str(delta)]);
display(['t-test:  ',num2str(stats.tstat)])
display(['p-level: ',num2str(p)])
display(['df:      ',num2str(stats.df)])
display(['sd:      ',num2str(stats.sd)])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot permutation distribution with parametric overlay %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear n; clear hours;
hours=[min(remdiff):1.0:max(remdiff)]; %data bins
n=histc(remdiff,hours);
figure(1); clf;
subplot(2,1,1);
set(gcf,'PaperPositionMode','auto');
set(gcf,'Position',[650 100 600 800]);
bar(hours,n,'k');
hold on;
axis([-20 10 0 max(n)+50]);
xlabel('Repair Time (hours)');
ylabel('Frequency');
title_str(1)={['Permutation Distribution of Differences between Sample Means']};
title_str(2)={'Hesterberg Example 18.14 (Permutation Test)'};
title_str(3)={['(Number of Resamples = ',num2str(n_resamples),')']};
title(title_str);
%annotate randomization distribution
f11str(1)={['Mean (BIAS): ',num2str(remean)]};
f11str(2)={['Std. Error:  ',num2str(restderr)]};
f11str(3)={['1st  %ile:   ',num2str(p1)]};
f11str(4)={['99th %ile:   ',num2str(p99)]};
text(-15,max(n)/2,f11str);
%generate normal-quantile plot to assess normality
subplot(2,1,2);
qqplot(remdiff);
hold on;
ylabel('Repair Time (hours)');
title('');
hold off;
