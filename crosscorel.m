function [peakcct,peaksdf,tbtdircor,tbtdirmsact,tbtdirmsdur]=crosscorel(filename,dataaligned,dirs,plotf)
global directory slash

%% load alignement file if necessary
%filename='R113L6A2_18900';
if ~isstruct(dataaligned)
algdir=[directory,'processed',slash,'aligned',slash];
load([algdir,filename,'_sac.mat']);
end

%% load processed file
if strcmp(filename(1),'R')
    procdir=[directory,'processed',slash,'Rigel',slash];
elseif strcmp(filename(1),'S')
    procdir=[directory,'processed',slash,'Sixx',slash];
elseif strcmp(filename(1),'H')
    procdir=[directory,'processed',slash,'Hilda',slash];
end
load([procdir,filename,'.mat']);
%% get directions
for rstplt=1:length(dataaligned)
    dataaligned(1,rstplt).dir=getdir_fpos(dataaligned,rstplt); %#ok<AGROW>
end

%% trials for dir with best effects
%pick the best (or the first best)

if strcmp(dirs,'all')
    bestdirs=find(~cellfun(@isempty, {dataaligned.alignidx}));
elseif strcmp(dirs,'active')
    %% get file h stats
    filehstat=arrayfun(@(x) sum(x{:}.h), {dataaligned(~cellfun(@isempty, {dataaligned.stats})).stats});
    bestdirs=find(filehstat==max(filehstat));
end
peakcct=nan(length(bestdirs),1);
peaksdf=nan(length(bestdirs),1);
tbtdircor=[];
tbtdirmsact=[];
tbtdirmsdur=[];
for showdirs=1:length(bestdirs)
    bestdir=bestdirs(showdirs);
    bestdirname=dataaligned(1,bestdirs(showdirs)).dir;
    %dircodes=[0 1 2 3 4 5 6 7 8];
    bdtrials=dataaligned(1,bestdir).trials;
    
    if ~isempty(bdtrials)
    %% get saccade durations for those trials
    alldurs=reshape({saccadeInfo.duration},size(saccadeInfo)); % all directions found in saccadeInfo
    allgoodsacs=~cellfun('isempty',reshape({saccadeInfo.latency},size(saccadeInfo)));
    % if saccade detection corrected, there may two 'good' saccades
    
    if max(sum(allgoodsacs,2))>1
        twogoods=find(sum(allgoodsacs,2)>1);
        for dblsac=1:length(twogoods)
            allgoodsacs(twogoods(dblsac),find(allgoodsacs(twogoods(dblsac),:),1))=0;
        end
    end
    bddurs=alldurs(bdtrials,:);
    bdgoodsacs=allgoodsacs(bdtrials,:);
    bddurs=transpose(bddurs);
    allgooddurs=cell2mat(bddurs(transpose(bdgoodsacs)));
    
    
    %% get rasters and velocities for the relevant trials.
    bdeyevel=dataaligned(1,bestdir).eyevel;
    bdrasters=dataaligned(1,bestdir).rasters;
    bdamps=dataaligned(1,bestdir).amplitudes;
    bdduration=dataaligned(1,bestdir).allgreyareas;

    % compute time window
    aligntime=dataaligned(1,bestdir).alignidx;
    timewin=[aligntime*ones(size(bdeyevel,1),1) ...
        aligntime*ones(size(bdeyevel,1),1)+allgooddurs];
    % get time window restricted eyevel and rasters
    twbdeyevel=cell(size(bdeyevel,1),1);
    twbdrasters=cell(size(bdeyevel,1),1);
    for bdtrial=1:size(bdeyevel,1)
        twbdeyevel(bdtrial)={bdeyevel(timewin(bdtrial,1):timewin(bdtrial,2))};
        twbdrasters(bdtrial)={bdrasters(timewin(bdtrial,1):timewin(bdtrial,2))};
    end
    
    %% sums and sdf
    startwindow=aligntime;%-200
    if startwindow<1
        startwindow=1;
    end
    endwindow=aligntime+199;
    if endwindow>length(bdeyevel)
        endwindow=length(bdeyevel);
    end
    
    trsaccrosscol=cell(size(bdeyevel,1),1);
    trsaccrosscol2=nan(size(bdeyevel,1),1);
    trpresaccrosscol=cell(size(bdeyevel,1),1);
    sduration=nan(size(bdeyevel,1),1);
    mseyevel=nan(size(bdeyevel,1),1);
    mtrsacactiv=nan(size(bdeyevel,1),1);
    mtrpresacactiv=nan(size(bdeyevel,1),1);
    %trial by trial analysis
    for trnb=1:size(bdeyevel,1)
        sduration(trnb,1)=bdduration{1,trnb}(2,2)-bdduration{1,trnb}(2,1);
        mseyevel(trnb,1)=nanmean(bdeyevel(trnb,startwindow:startwindow+sduration(trnb,1)-1));
        trsacactiv=spike_density(bdrasters(trnb,startwindow:startwindow+sduration(trnb,1)-1),15);
        trsacactiv=trsacactiv./max(trsacactiv);
        trsacactiv(isnan(trsacactiv))=0;
        mtrsacactiv(trnb,1)=nanmean(trsacactiv);
        trpresacactiv=spike_density(bdrasters(trnb,startwindow-200:startwindow),15);
        trpresacactiv=trpresacactiv./max(trpresacactiv);
        trpresacactiv(isnan(trpresacactiv))=0;
        mtrpresacactiv(trnb)=nanmean(trpresacactiv);
        trsaccrosscol(trnb)={xcorr(trsacactiv,...
            bdeyevel(trnb,startwindow:startwindow+sduration(trnb,1)-1),'coeff')};
        trsaccrosscolall=corrcoef(([trsacactiv; ...
            bdeyevel(trnb,startwindow:startwindow+sduration(trnb,1)-1)])');
        trsaccrosscol2(trnb)=trsaccrosscolall(1,2);
        trpresaccrosscol(trnb)={xcorr(trpresacactiv,...
            bdeyevel(trnb,startwindow-200:startwindow),'coeff')};
    end
    %corrcoef([mtrsacactiv mseyevel])
    tbtdircor=[tbtdircor;trsaccrosscol2];
    tbtdirmsact=[tbtdirmsact;mtrpresacactiv];
    tbtdirmsdur=[tbtdirmsdur;sduration];
    
    mtrsaccrosscol=cellfun(@(x) nanmean(x), trsaccrosscol);
    mtrsaccrosscol(isnan(mtrsaccrosscol))=0;
    mean(mtrsaccrosscol);
    std(mtrsaccrosscol);
    
    mtrpresaccrosscol=cellfun(@(x) nanmean(x), trpresaccrosscol);
    mtrpresaccrosscol(isnan(mtrpresaccrosscol))=0;
    mean(mtrpresaccrosscol);
    std(mtrpresaccrosscol);
    % end trial by trial
%% 
    meaneyevel=nansum(bdeyevel(:,startwindow:endwindow))./size(bdrasters,1);
    activsum=nansum(bdrasters(:,startwindow:endwindow));
    activsdf=spike_density(activsum,15)./size(bdrasters,1);
    peaksdf(showdirs)=round(max(activsdf));
    %normalize each
    norm_meaneyevel=meaneyevel./max(meaneyevel);
    norm_activsdf=activsdf./max(activsdf);
    
    %% cross-correlations
    %two methods, perfectly identical results
    %fft method
    %corrlength=length(norm_meaneyevel)+length(norm_activsdf)-1;
    %crosscol=fftshift(ifft(fft(norm_meaneyevel,corrlength).*conj(fft(norm_activsdf,corrlength))));
    %matab method
    crosscol=xcorr(norm_activsdf,norm_meaneyevel,'coeff');
    if isempty(find(crosscol==max(crosscol)))
        peakcct(showdirs)=nan(1,1);
    else
    peakcct(showdirs)=find(crosscol==max(crosscol))-length(norm_meaneyevel);
    end
    
    %% plot results
    if plotf
        figname=['Cross-correlogram for file ',filename,', best dir ',bestdirname];
        crosscolfigh=figure('NumberTitle','off','Name',figname,'Color','white');
        set(crosscolfigh,'Position',[90    100   480   900])
        colmap=winter(16);
        subplot(3,1,1);
        plot(activsdf,'color',colmap(9,:),'LineWidth',1.8);
        set(get(gca,'YLabel'),'string','Spk/s','FontSize',10)
        set(get(gca,'XLabel'),'string','Time from Saccade (ms)','FontSize',10);
        set(gca,'Xtick',[0:100:400]);
        set(gca,'Xticklabel',[-200:100:200]);
        title('Mean Firing Rate','FontSize',12);
        hold on;
        patch([repmat(199,1,2) repmat(201,1,2)], ...
        [get(gca,'YLim') fliplr(get(gca,'YLim'))], ...
        [0 0 0 0],[1 0 0],'EdgeColor','none','FaceAlpha',0.5);
        subplot(3,1,2);
        plot(meaneyevel,'color',colmap(6,:),'LineWidth',1.8);
        set(get(gca,'YLabel'),'string','Eye velocity (deg/ms)','FontSize',10);
        set(get(gca,'XLabel'),'string','Time from Saccade (ms)','FontSize',10);
        set(gca,'Xtick',[0:100:400]);
        set(gca,'Xticklabel',[-200:100:200]);
        title('Mean Eye Velocity','FontSize',12);
        hold on;
        patch([repmat(199,1,2) repmat(201,1,2)], ...
        [get(gca,'YLim') fliplr(get(gca,'YLim'))], ...
        [0 0 0 0],[1 0 0],'EdgeColor','none','FaceAlpha',0.5);
        subplot(3,1,3);
        plot(crosscol,'color',colmap(3,:),'LineWidth',1.8);
        set(get(gca,'XLabel'),'string','Relative Time between Peak Firing Rate and Peak Velocity (ms)','FontSize',10);
        set(gca,'Xtick',[0:200:800]);
        set(gca,'Xticklabel',[-200:100:200]);
        title('Cross-correlation between firing rate and eye velocity','FontSize',12);
        hold on;
        patch([repmat(399,1,2) repmat(401,1,2)], ...
        [get(gca,'YLim') fliplr(get(gca,'YLim'))], ...
        [0 0 0 0],[1 0 0],'EdgeColor','none','FaceAlpha',0.5);
        
        allaxes=findobj(gcf,'Type','axes');
        set(allaxes(2:3),'TickDir','out');
        set(allaxes,'box','off');
        set(allaxes,'FontSize',12);
        set(allaxes(2:3),'xlim',[0 400]);
        set(allaxes(1),'xlim',[0 800]);
        set(allaxes(1),'ylim',[0 1]);
        exportfig=[directory,'figures',slash,'CCfigs',slash,filename,'_',bestdirname,'_','cc'];
        print(gcf, '-dpng', '-noui', '-opengl','-r600', exportfig);
        %set(gca,'Color','none')
        %set(gca,'Xtick',)
        %set(gca,'Xticklabel',)
        delete(crosscolfigh);
    end
    end
end

end