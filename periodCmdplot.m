% plotting eye traces and sdf from periodicCmd_stop recording
% three parts: 
% - superposed traces of the first iterations (select trials with >
% iterations)
% - superposed traces of all canceled trials (adjusted for direction) over
% last three iterations
% - superposed traces of all non-cancelled trials (adjusted for direction)
% over last three iterations
clear all
load('S190L6A1_10834_REX.mat', 'allcodes', 'allh', 'allspk', 'alltimes', 'allv', 'saccadeInfo')

% AllLats=reshape({saccadeInfo.latency},size(saccadeInfo));
% NonAbortTrials= sum(AllLats{:},2)
% 
%     alllats=alllats';%needs to be transposed because the logical indexing below will be done column by column, not row by row
%     allgoodsacs=~cellfun('isempty',reshape({saccadeInfo.latency},size(saccadeInfo)));

[ctrialrow,ctrialscol]=ind2sub(size(allcodes),find(allcodes==1030));
[ctrialrow,ctidx]=sort(ctrialrow);
ctrialscol=ctrialscol(ctidx);
[nctrialrow,nctrialscol]=ind2sub(size(allcodes),find(allcodes==16386));
[nctrialrow,nctidx]=sort(nctrialrow);
nctrialscol=nctrialscol(nctidx);

% get info for each type of trial
% canceled trials
ctcodes=allcodes(ctrialrow,:);
cttimes=alltimes(ctrialrow,:);
ctrasters=allspk(ctrialrow,:);
% ctrasters(isnan(ctrasters))=0;
cth=allh(ctrialrow,:);
ctv=allv(ctrialrow,:);
csacinfo=saccadeInfo(ctrialrow);
% non-canceled trials
nctcodes=allcodes(nctrialrow,:);
ncttimes=alltimes(nctrialrow,:);
nctrasters=allspk(nctrialrow,:);
% nctrasters(isnan(nctrasters))=0;
ncth=allh(nctrialrow,:);
nctv=allv(nctrialrow,:);
ncsacinfo=saccadeInfo(nctrialrow);

% plot longest trial's eye position and sdf
% max([ctrialscol;nctrialscol]) -> trial #1
figure(1)
% subplot(2,1,1)
plot(allh(nctrialrow(1),ncttimes(1,6):ncttimes(1,max(nctrialscol)-1)),'color',[0 0.4 0])
hold on
plot(allv(nctrialrow(1),ncttimes(1,6):ncttimes(1,max(nctrialscol)-1)),'color',[0 0.6 0])
% inter target interval for that trial
tgttimes=ncttimes(nctrialrow(1),7:4:max(nctrialscol))-ncttimes(nctrialrow(1),6);
diff(tgttimes); %1s exactly
sactimes=[saccadeInfo(1,:).starttime]-ncttimes(nctrialrow(1),6);
sacamp=[saccadeInfo(1,:).amplitude];
sactimes=sactimes(abs(sacamp)>2.5);
sactimes=sactimes(sactimes>0);
sacinter=diff(sactimes);
if ~mod(length(sacinter),2) %if even length
    predictsaclat=mean(sacinter(2:2:length(sacinter)-2));
    predictsaclatstd=std(sacinter(2:2:length(sacinter)-2));
end
plot(tgttimes,zeros(length(tgttimes),1),'*k');
plot(sactimes,ones(length(sactimes),1),'db');
plot(sactimes(end-1)+predictsaclat,1,'dk');
% subplot(2,1,2)


%% plot cancelled trials
figure(2); 
subplot(2,2,1)
hold on;
%plot early iterations
earlyith=cell(size(ctrialrow,1),1);
earlyspk=[];
% allspikes=[];
sigma=20;
for ct=1:size(ctrialrow,1)
    %which direction
    if ctcodes(ct,2)-floor(ctcodes(ct,2)/10)*10==2
        dir=1;
    else
        dir=-1;
    end
    earlyith{ct,:}=dir.*cth(ct,cttimes(ct,6):cttimes(ct,min(ctrialscol)-1)+100);
    plot(dir.*cth(ct,cttimes(ct,6):cttimes(ct,min(ctrialscol)-1)+100));
    tspikes=zeros(1,max(ctrasters(ct,:)));
    tspikes(ctrasters(ct,~isnan(ctrasters(ct,:)) & ctrasters(ct,:)>0))=1;
%     earlyspk=cat_variable_size_row(earlyspk,tspikes(find(ctrasters(ct,:)>=alltimes(ctrialrow(ct),6),1):...
%         find(ctrasters(ct,:)<alltimes(ctrialrow(ct),min(nctrialscol)-1)+100,1,'last')));
%     allspikes=cat_variable_size_row(allspikes,tspikes);
    earlyspk=cat_variable_size_row(earlyspk,tspikes(cttimes(ct,6)-sigma:cttimes(ct,min(ctrialscol)-1)+100+sigma));
end

% sdf 
sumall=nansum(earlyspk,1);
sdf=fullgauss_filtconv(sumall,sigma,0)./ct.*1000;
% sdf=sdf(sigma+1:end-sigma);
maxxlim=max(size(earlyspk,2),max([cellfun(@(x) length(x),earlyith)]));
set(gca,'xlim',[1 maxxlim]);

subplot(2,2,3)
% min(alltimes(ctrialrow(:),min(nctrialscol)-1) - alltimes(ctrialrow(:),6))
title('Spike Density Function','FontName','calibri','FontSize',11);
hold on;
plot(sdf)
set(gca,'xlim',[1 maxxlim]);
ylim=get(gca,'ylim');

subplot(2,2,2)
hold on;
%plot early iterations
lastith=cell(size(ctrialrow,1),1);
lastspk=[];
% allspikes=[];
sigma=20;
for ct=1:size(ctrialrow,1)
    %which direction
%     if ctcodes(ct,2)-floor(ctcodes(ct,2)/10)*10==2
%         dir=1;
%     else
%         dir=-1;
%     end
    lastith{ct,:}=dir.*cth(ct,cttimes(ct,ctrialscol(ct)-7):cttimes(ct,ctrialscol(ct)-1)+100);
    plot(dir.*cth(ct,cttimes(ct,ctrialscol(ct)-7):cttimes(ct,ctrialscol(ct)-1)+100));
    plot(cttimes(ct,ctrialscol(ct)-6)-cttimes(ct,ctrialscol(ct)-7)+predictsaclat,1,'dr');
    tspikes=zeros(1,max(ctrasters(ct,:)));
    tspikes(ctrasters(ct,~isnan(ctrasters(ct,:)) & ctrasters(ct,:)>0))=1;
%     lastspk=cat_variable_size_row(lastspk,tspikes(find(ctrasters(ct,:)>=alltimes(ctrialrow(ct),6),1):...
%         find(ctrasters(ct,:)<alltimes(ctrialrow(ct),min(nctrialscol)-1)+100,1,'last')));
%     allspikes=cat_variable_size_row(allspikes,tspikes);
    lastspk=cat_variable_size_row(lastspk,tspikes(cttimes(ct,ctrialscol(ct)-7)-sigma:cttimes(ct,ctrialscol(ct)-1)+100+sigma));
end

% sdf 
sumall=nansum(lastspk,1);
sdf=fullgauss_filtconv(sumall,sigma,0)./ct.*1000;
% sdf=sdf(sigma+1:end-sigma);
maxxlim=max(size(lastspk,2),max([cellfun(@(x) length(x),lastith)]));
set(gca,'xlim',[1 maxxlim]);


subplot(2,2,4)
% min(alltimes(ctrialrow(:),min(nctrialscol)-1) - alltimes(ctrialrow(:),6))
title('Spike Density Function - C','FontName','calibri','FontSize',11);
hold on;
plot(sdf)
set(gca,'xlim',[1 maxxlim],'ylim',ylim);


%% plot non-cancelled trials
figure(3); 
subplot(2,2,1)
hold on;
%plot early iterations
earlyith=cell(size(nctrialrow,1),1);
earlyspk=[];
% allspikes=[];
sigma=20;
for nct=1:size(nctrialrow,1)
    %which direction
    if nctcodes(nct,2)-floor(nctcodes(nct,2)/10)*10==2
        dir=1;
    else
        dir=-1;
    end
    earlyith{nct,:}=dir.*ncth(nct,ncttimes(nct,6):ncttimes(nct,min(nctrialscol)-1)+100);
    plot(dir.*ncth(nct,ncttimes(nct,6):ncttimes(nct,min(nctrialscol)-1)+100));
    tspikes=zeros(1,max(nctrasters(nct,:)));
    tspikes(nctrasters(nct,~isnan(nctrasters(nct,:)) & nctrasters(nct,:)>0))=1;
%     earlyspk=cat_variable_size_row(earlyspk,tspikes(find(nctrasters(nct,:)>=alltimes(nctrialrow(nct),6),1):...
%         find(nctrasters(nct,:)<alltimes(nctrialrow(nct),min(nnctrialscol)-1)+100,1,'last')));
%     allspikes=cat_variable_size_row(allspikes,tspikes);
    earlyspk=cat_variable_size_row(earlyspk,tspikes(ncttimes(nct,6)-sigma:ncttimes(nct,min(nctrialscol)-1)+100+sigma));
end

% sdf 
sumall=nansum(earlyspk,1);
sdf=fullgauss_filtconv(sumall,sigma,0)./nct.*1000;
% sdf=sdf(sigma+1:end-sigma);
maxxlim=max(size(earlyspk,2),max([cellfun(@(x) length(x),earlyith)]));
set(gca,'xlim',[1 maxxlim]);

subplot(2,2,3)
% min(alltimes(nctrialrow(:),min(nnctrialscol)-1) - alltimes(nctrialrow(:),6))
title('Spike Density Function - NC','FontName','calibri','FontSize',11);
hold on;
plot(sdf)
set(gca,'xlim',[1 maxxlim]);
ylim=get(gca,'ylim');

subplot(2,2,2)
hold on;
%plot early iterations
lastith=cell(size(nctrialrow,1),1);
lastspk=[];
% allspikes=[];
sigma=20;
for nct=1:size(nctrialrow,1)
    %which direction
    if nctcodes(nct,2)-floor(nctcodes(nct,2)/10)*10==2
        dir=1;
    else
        dir=-1;
    end
    lastith{nct,:}=dir.*ncth(nct,ncttimes(nct,nctrialscol(nct)-7):ncttimes(nct,nctrialscol(nct)-1)+100);
    plot(dir.*ncth(nct,ncttimes(nct,nctrialscol(nct)-7):ncttimes(nct,nctrialscol(nct)-1)+100));
    plot(ncttimes(nct,nctrialscol(nct)-6)-ncttimes(nct,nctrialscol(nct)-7)+predictsaclat,1,'dr');
    tspikes=zeros(1,max(nctrasters(nct,:)));
    tspikes(nctrasters(nct,~isnan(nctrasters(nct,:)) & nctrasters(nct,:)>0))=1;
%     lastspk=cat_variable_size_row(lastspk,tspikes(find(nctrasters(nct,:)>=alltimes(nctrialrow(nct),6),1):...
%         find(nctrasters(nct,:)<alltimes(nctrialrow(nct),min(nnctrialscol)-1)+100,1,'last')));
%     allspikes=cat_variable_size_row(allspikes,tspikes);
    lastspk=cat_variable_size_row(lastspk,tspikes(ncttimes(nct,nctrialscol(nct)-7)-sigma:ncttimes(nct,nctrialscol(nct)-1)+100+sigma));
end

% sdf 
sumall=nansum(lastspk,1);
sdf=fullgauss_filtconv(sumall,sigma,0)./nct.*1000;
% sdf=sdf(sigma+1:end-sigma);
maxxlim=max(size(lastspk,2),max([cellfun(@(x) length(x),lastith)]));
set(gca,'xlim',[1 maxxlim]);


subplot(2,2,4)
% min(alltimes(nctrialrow(:),min(nctrialscol)-1)+100 - alltimes(nctrialrow(:),6))
title('Spike Density Function','FontName','calibri','FontSize',11);
hold on;
plot(sdf)
set(gca,'xlim',[1 maxxlim],'ylim',ylim);









