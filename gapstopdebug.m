
%debugging code for gapstop analysis

%load('S116L4A6_15431.mat')
%load('S117L4A6_12741.mat') 
load('S118L4A5_13081.mat'); %four ssd : 80, 160, 210, 320.


%% early/late saccade trials
earlysactrials=find(allcodes(:,8)==17385); %finds mostly no-stop signal trials, but also stop trials (typically one)
wrongdelay=nan(length(earlysactrials),1);
for esactr=1:length(earlysactrials)
earlysactimes=(cell2mat({saccadeInfo(earlysactrials(esactr),:).starttime}));
earlysacstart=earlysactimes(find(earlysactimes>alltimes(earlysactrials(esactr),7),1));
wrongdelay(esactr)=earlysacstart-alltimes(earlysactrials(esactr),7);
end

minwrong=find(wrongdelay==min(wrongdelay))
mindelwrongsactrl=earlysactrials(minwrong);
mindelwrongsaccodes=allcodes(mindelwrongsactrl,:);

figure(21)
plot(allh(mindelwrongsactrl,:))
hold on
plot(allv(mindelwrongsactrl,:),'r')
plot(alltimes(mindelwrongsactrl,4:7),[0 0 0 0],'db')
plot(alltimes(mindelwrongsactrl,8),0,'dk')
earlysactimes=cell2mat({saccadeInfo(mindelwrongsactrl,:).starttime})
plot(earlysactimes,zeros(1,length(earlysactimes)),'dr')

% good saccade trials
goodsactrials=find(((allcodes(:,8)==7042) | (allcodes(:,8)==7046)) & (allcodes(:,9)~=17385));
goodsacdelay=nan(length(goodsactrials),1);
for gsactr=1:length(goodsactrials)
try
    goodsacdelay(gsactr)=cell2mat({saccadeInfo(goodsactrials(gsactr),:).latency});
catch %somehow, this is a bad trial
    goodsactrials(gsactr)
end
end
goodsacdelay=goodsacdelay(~isnan(goodsacdelay));

figure(21)

subplot(2,1,1)
hist(wrongdelay)
title('wrong delays')
subplot(2,1,2)
hist(goodsacdelay)
title('good delays')

%% with test code 1503 all over

% load('Rtestdelay1.mat') 
% trialtoconsider=find(allcodes(:,9)==1503);
% state1=alltimes(trialtoconsider,9)-alltimes(trialtoconsider,8);
% %min=1 max=1 %OK
% state2=alltimes(trialtoconsider,10)-alltimes(trialtoconsider,9);
% %min=1 max=1 %OK
% 
% %looking at saccades only
% onlysactrials=trialtoconsider(allcodes(trialtoconsider,8)==6846 | allcodes(trialtoconsider,8)==6842);
% state3=alltimes(onlysactrials,11)-alltimes(onlysactrials,10);
% %min=50 max=50 %OK
% state4=alltimes(onlysactrials,12)-alltimes(onlysactrials,11);
% %min=1 max=1 %OK
% 
% goodsactrials=onlysactrials(allcodes(onlysactrials,13)~=17385);
% state5=alltimes(goodsactrials,13)-alltimes(goodsactrials,12);
% badsactrials=onlysactrials(allcodes(onlysactrials,13)==17385);
% state5bis=alltimes(badsactrials,13)-alltimes(badsactrials,12)
% goodsacdelay=alltimes(goodsactrials,13)-alltimes(goodsactrials,8);
% wrongdelay=alltimes(badsactrials,13)-alltimes(badsactrials,8)

% saved as debug1

% now with the 50ms delay removed
% load('Rtestdelay2.mat') 
% trialtoconsider=find(allcodes(:,9)==1503);
% state1=alltimes(trialtoconsider,9)-alltimes(trialtoconsider,8);
% %min=1 max=1 %OK
% state2=alltimes(trialtoconsider,10)-alltimes(trialtoconsider,9);
% %min=1 max=1 %OK
% 
% %looking at saccades only
% onlysactrials=trialtoconsider(allcodes(trialtoconsider,8)==6846 | allcodes(trialtoconsider,8)==6842);
% state3=alltimes(onlysactrials,11)-alltimes(onlysactrials,10);
% %min=50 max=50 %OK
% % state4=alltimes(onlysactrials,12)-alltimes(onlysactrials,11);
% 
% goodsactrials=onlysactrials(allcodes(onlysactrials,12)~=17385);
% state4=alltimes(goodsactrials,12)-alltimes(goodsactrials,11);
% badsactrials=onlysactrials(allcodes(onlysactrials,12)==17385);
% state4bis=alltimes(badsactrials,12)-alltimes(badsactrials,11);
% goodsacdelay=alltimes(goodsactrials,12)-alltimes(goodsactrials,8);
% wrongdelay=alltimes(badsactrials,12)-alltimes(badsactrials,8);

% saved as debug2
% 
% subplot(2,1,1)
% hist(wrongdelay)
% title('wrong delays')
% subplot(2,1,2)
% hist(goodsacdelay)
% title('good delays')
