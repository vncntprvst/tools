function Raster_sdf_plot(rasters,event_times,start,stop,alignmtt,conv_sigma,evtsort)
% event_times=gsdata(sacalg).evttime;
% evtsort=0; %default 0 for chronological display order

if start < 1
    start = 1;
end
if stop > size(rasters,2)
    stop = size(rasters,2);
end

%     if ~evtsort %% that's for plotting multiple rasters / sdfs, with all
%     rasters pooled together in chronological order
%        cut_chrasters=zeros(length([alignedata.trials]),plotstart+plotstop+1);
%        %listing relevant trials in a continuous series with other rasters
%        chronoidx=ismember(sort([alignedata.trials]),alignedata(rastnum).trials); 
%         cut_chrasters=zeros(size(rasters,1),stop-start-6*conv_sigma+1);
%         chronoidx=1:size(rasters,1);
%     end

figure
colormap lines;
cmap = colormap(gcf);
rastnum=1;
hrastplot(rastnum)=subplot(2,1,1,'Layer','top', ...
        'XTick',[],'YTick',[],'XColor','white','YColor','white');

%reducing spacing between rasters
if rastnum>1 && ~evtsort
    rastpos=get(gca,'position');
    rastpos(2)=rastpos(2)+rastpos(4)*0.5;
    set(gca,'position',rastpos);
end

% build event times "masks" over rasters
% event order is 'cue' 'eyemvt' 'fix' 'rew' 'fail'
rast_mask=zeros(size(rasters,1),size(rasters,2),4);
%visual cue mask
rast_mask(:,:,1)=cell2mat(rot90(cellfun(@(x) [zeros(1,x(1,1)-1) ones(1,x(1,2)-x(1,1)) zeros(1,size(rasters,2)+1-x(1,2))], event_times,'UniformOutput',false)));
%veye movement mask
rast_mask(:,:,2)=cell2mat(rot90(cellfun(@(x) [zeros(1,x(2,1)-1) ones(1,x(2,2)-x(2,1)) zeros(1,size(rasters,2)+1-x(2,2))], event_times,'UniformOutput',false)));
%fixation mask
rast_mask(:,:,3)=cell2mat(rot90(cellfun(@(x) [zeros(1,x(3,1)-1) ones(1,x(3,2)-x(3,1)) zeros(1,size(rasters,2)+1-x(3,2))], event_times,'UniformOutput',false)));
%reward mask
rast_mask(:,:,4)=cell2mat(rot90(cellfun(@(x) [zeros(1,x(4,1)-1) ones(1,x(4,2)-x(4,1)) zeros(1,size(rasters,2)+1-x(4,2))], event_times,'UniformOutput',false)));

if evtsort
% sorting rasters according event time
evtstarts=cellfun(@(x) x(evtsort,1), event_times,'UniformOutput',true);
[~,sortidx]=sort(evtstarts,'descend');
rasters=rasters(sortidx,:);
rast_mask=rast_mask(sortidx,:,:);
end

hold on

cut_rasters = rasters(:,start+3*conv_sigma:stop-3*conv_sigma); % Isolate rasters of interest
rast_mask = rast_mask(:,start+3*conv_sigma:stop-3*conv_sigma,:);
isnantrial = isnan(sum(cut_rasters,2)); % Identify nantrials
cut_rasters(isnan(cut_rasters)) = 0; % take nans out so they don't get plotted
% if ~evtsort
%     cut_chrasters(chronoidx,:)=cut_rasters;
%     [indy, indx] = ind2sub(size(cut_chrasters),find(cut_chrasters)); %find row and column coordinates of spikes
% else
%     [indy, indx] = ind2sub(size(cut_rasters),find(cut_rasters)); %find row and column coordinates of spikes
%     [indy, indx, indz] = ind2sub(size(rast_mask),find(rast_mask));

%"masked" rasters record event times for every trial
% event order is 'cue' 'eyemvt' 'fix' 'rew' 'fail'
[indy{1}, indx{1}] = ind2sub(size(cut_rasters),find(cut_rasters & rast_mask(:,:,1)));
[indy{2}, indx{2}] = ind2sub(size(cut_rasters),find(cut_rasters & rast_mask(:,:,2)));
[indy{3}, indx{3}] = ind2sub(size(cut_rasters),find(cut_rasters & rast_mask(:,:,3)));
[indy{4}, indx{4}] = ind2sub(size(cut_rasters),find(cut_rasters & rast_mask(:,:,4)));
% regular (not "masked") rasters
[indy{5}, indx{5}] = ind2sub(size(cut_rasters),find(cut_rasters));
% end

if(size(rasters,1) == 1)
rastlines{1}=plot([indx{5};indx{5}],[indy{5};indy{5}+1],'color',cmap(1,:),'LineStyle','-'); % plot rasters
else
rastlines{1}=plot([indx{5}';indx{5}'],[indy{5}';indy{5}'+1],'color','k','LineStyle','-'); % plot rasters
    
    %plot bi-color rasters pre/post event
    % get raster indx referenced to alignement time, for standard two-color plot
% evtlimidx={indx{5}<=alignmtt-(start+3*conv_sigma),indx{5}>alignmtt-(start+3*conv_sigma)};
%     plot([indx{5}(evtlimidx{1})';indx{5}(evtlimidx{1})'],...
%         [indy{5}(evtlimidx{1})';indy{5}(evtlimidx{1})'+1],'color',cmap(1,:),'LineStyle','-'); % plot < align event rasters
%     plot([indx{5}(evtlimidx{2})';indx{5}(evtlimidx{2})'],...
%         [indy{5}(evtlimidx{2})';indy{5}(evtlimidx{2})'+1],'color',cmap(4,:),'LineStyle','-'); % plot > align event rasters

    % plot "masked" rasters 
rastlines{2}=plot([indx{1}';indx{1}'],[indy{1}';indy{1}'+1],'color',cmap(1,:),'LineStyle','-'); % plot rasters
rastlines{3}=plot([indx{2}';indx{2}'],[indy{2}';indy{2}'+1],'color',cmap(2,:),'LineStyle','-'); % plot rasters
rastlines{4}=plot([indx{3}';indx{3}'],[indy{3}';indy{3}'+1],'color',cmap(4,:),'LineStyle','-'); % plot rasters
rastlines{5}=plot([indx{4}';indx{4}'],[indy{4}';indy{4}'+1],'color',cmap(7,:),'LineStyle','-'); % plot rasters    
end
rastlineprop=cellfun(@(x) x(1), rastlines(~cellfun('isempty',rastlines)),'UniformOutput',false);
rasterevtlegtxt={'raw','cue','eyemvt','fix','rew'};rasterevtlegtxt=rasterevtlegtxt(~cellfun('isempty',rastlines));
[rastlegh,rastlegicons]=legend([rastlineprop{:}],rasterevtlegtxt,'Location','northoutside')%,'FontSize',8,'FontWeight','bold',...
%     ,'Orientation','horizontal');

%refine legend
rastlegicons(5).LineStyle=':';
rastlegicons(5).LineWidth=3
% rasterevtlegtxtcol=cellfun(@(x) x.Color, rastlineprop(~cellfun('isempty',rastlines)),'UniformOutput',false)
rastlegicons(1).Color='red'
rastlegh.Box='off';
rastlegh.linewidth=10;
set(gca,'xlim',[1 length(start+3*conv_sigma:stop-3*conv_sigma)]);
axis(gca, 'off'); % axis tight sets the axis limits to the range of the data.
    
%% Plot sdf
sdfplot=subplot(2,1,2,'Layer','top');
%sdfh = axes('Position', [.15 .65 .2 .2], 'Layer','top');
title('Spike Density Function','FontName','calibri','FontSize',11);
hold on;
if size(rasters(~isnantrial,:),1)<5 %if less than 5 good trials
    %useless plotting this
    sumall=NaN;
else
    sumall=sum(rasters(~isnantrial,start:stop));
end
[sdf, ~, rastsem]=conv_raster(rasters,conv_sigma,start,stop); %(sumall,conv_sigma,causker)./length(find(~isnantrial)).*1000;

if size(rasters(~isnantrial,:),1)>=5
    %    plot confidence intervals
    patch([1:length(sdf),fliplr(1:length(sdf))],[sdf-rastsem,fliplr(sdf+rastsem)],cc(rastnum,:),'EdgeColor','none','FaceAlpha',0.1);
    %plot sdf
    plot(sdf,'Color',cc(rastnum,:),'LineWidth',1.8);
end

axis(gca,'tight');
box off;
set(gca,'Color','white','TickDir','out','FontName','calibri','FontSize',8); %'YAxisLocation','rigth'
hylabel=ylabel(gca,'Firing rate (spikes/s)','FontName','calibri','FontSize',8);
currylim=get(gca,'YLim');

if ~isempty(rasters)
    % drawing the alignment bar
    patch([repmat((alignmtt-(start+3*conv_sigma))-2,1,2) repmat((alignmtt-(start+3*conv_sigma))+2,1,2)], ...
        [[0 currylim(2)] fliplr([0 currylim(2)])], ...
        [0 0 0 0],[1 0 0],'EdgeColor','none','FaceAlpha',0.5);
end

end
