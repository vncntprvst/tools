function [auc,slopes,peaksdft]=findauc(filename,dataaligned,dirs)
% get area under curve for all or selected direction
% auc is computed for a continuous region above 20% of peak response, from
% point that recah threshold to peak
% Also compute slope and peak response
global directory slash

% tasktype=get(findobj('Tag','taskdisplay'),'String');
mstart= str2double(get(findobj('Tag','msbefore'),'String'));
mstop= str2double(get(findobj('Tag','msafter'),'String'));

%% load alignement file if necessary
%filename='R113L6A2_18900';
if ~isstruct(dataaligned)
    algdir=[directory,'processed',slash,'aligned',slash];
    load([algdir,filename,'_sac.mat']);
end

%% define which dir
if strcmp(dirs,'all')
    bestdirs=find(~cellfun(@isempty, {dataaligned.alignidx}));
else strcmp(dirs,'active')
    %based on h stats
    filehstat=arrayfun(@(x) sum(x{:}.h), {dataaligned(~cellfun(@isempty, {dataaligned.stats})).stats});
    bestdirs=find(filehstat==max(filehstat));
end

%% compute auc and slope
auc=nan(1,length(bestdirs));
slopes=nan(1,length(bestdirs));
peaksdft=nan(1,length(bestdirs));
for showdirs=1:length(bestdirs)
    bestdir=bestdirs(showdirs);
    aligntime=dataaligned(1,bestdir).alignidx;
    %% get rasters for the relevant trials.
    bdrasters=dataaligned(1,bestdir).rasters;
    %% find isnantrial
    % from rdd_rasters_sdf
    start = aligntime - mstart;
    stop = aligntime + mstop;
    if start < 1
        start = 1;
    end
    if stop > length(bdrasters)
        stop = length(bdrasters);
    end
    isnantrial(showdirs)={zeros(1,size(bdrasters,1))};
    for szrast=1:size(bdrasters,1)
        if isnan(sum(bdrasters(szrast,start:stop)))
            isnantrial{showdirs}(szrast)=1;
        end
    end
    %prealloc
    allbaseline=nan(size(bdrasters,1),1);
    endfix=nan(size(bdrasters,1),1);
    %% get baseline for adaptive threshold
    for num_trials = 1:size(bdrasters,1)
        timesmat = dataaligned(1,bestdir).allgreyareas{num_trials}; %condtimes
        % see raststats for description of time windows
        
        baseline = timesmat(1,1)-300 : timesmat(1,1)-1;   %300 ms to 1ms before cue
        %
        %         %150ms period of visual response
        %         postcue = timesmat(1,1)+51 : timesmat(1,1)+150; %50ms to 150ms after cue presentation
        %
        %         %100ms of pre-eye movement period
        %         presac = timesmat(2,1)-100 : timesmat(2,1)-1; %100ms before sac initation
        %
        %         %100ms of eye movement period
        %         postsac = timesmat(2,1)+1 : timesmat(2,1)+100; %100ms before sac initation
        %
        %         %perisactime
        %         perisac = timesmat(2,1)-50 : timesmat(2,1)+50; %100ms around sac initation
        %
        %         if strcmp(tasktype{:},'memguided') % || strcmp(tasktype,'vg_saccades')
        %             delay=timesmat(3,2)-300 : timesmat(3,2)-1;
        %         elseif strcmp(tasktype{:}, 'st_saccades') || strcmp(tasktype{:}, 'tokens')
        %             delay=timesmat(2,1)-400 : timesmat(2,1)-101;
        %         else
        %             delay=0;
        %         end
        %         %make changes above for gapstop
        
        %conversion to firing rate (since epochs are different
        %durations)
        
        
        if ~isnantrial{showdirs}(num_trials)
            %             allpostcue(num_trials) = (sum(bdrasters(num_trials, postcue))/length(postcue))*1000;
            allbaseline(num_trials) = (nansum(bdrasters(num_trials, baseline))/length(baseline))*1000;
            endfix(num_trials)=baseline(end);
            %             allpresac(num_trials) = (sum(bdrasters(num_trials, presac))/length(presac))*1000;
            %             allpostsac(num_trials) = (sum(bdrasters(num_trials, postsac))/length(postsac))*1000;
            %             allperisac(num_trials) = (sum(bdrasters(num_trials, perisac))/length(perisac))*1000;
            %             if delay
            %                 alldelay(num_trials) = (sum(bdrasters(num_trials, delay))/length(delay))*1000;
            %             end
        end
        
    end
    %% threshold activity
    %fixation period noise
    fixnoise = max(mean(allbaseline(~isnan(allbaseline))) + 3*std(allbaseline(~isnan(allbaseline))),1); % that is to say, if fixnoise is 0, set it to 1
    %default threshold at 0.2 * peak response was too high
    activsum=nansum(bdrasters);
    activsdf=spike_density(activsum,15)./size(bdrasters,1);
    if length(activsdf)==1 || isempty(activsdf)
        peaksdft(showdirs)=nan(1,1);
        auc(showdirs)=nan(1,1);
        slopes(showdirs)=nan(1,1);
        continue
    end
    % presumed peak time
    ppkt=find(activsdf(aligntime-400:aligntime+200)==max(activsdf(aligntime-400:aligntime+200)),1)+aligntime-401;
    % threshold crossing time
    thdcrosst=ppkt-find(activsdf(ppkt:-1:1)<fixnoise,1)+1;
    %local noise
    locnoise = median(activsdf(thdcrosst-60:thdcrosst)) + 2*std(activsdf(thdcrosst-60:thdcrosst)); %relaxed criteria because bursts generate high std
    if ceil(locnoise)>floor(activsdf(ppkt))
        locnoise = 3*std(activsdf(thdcrosst-60:thdcrosst));
    end
    if ~locnoise
        peaksdft(showdirs)=nan(1,1);
        auc(showdirs)=nan(1,1);
        slopes(showdirs)=nan(1,1);
        continue
    end
    %restrict to period of interest as much as possible
    fixtosac=zeros(1,length(activsdf));
    fixtosac(min(ppkt,round(median(endfix(endfix>0)))):max(aligntime,ppkt))=activsdf(min(ppkt,round(median(endfix(endfix>0)))):max(aligntime,ppkt));
    peakarea=bwlabel(fixtosac>locnoise);
    
    %% if more than one region, select the one with highest activity
    if max(peakarea)>1
        maxpeakarea=nan(max(peakarea),1);
        for mxpk=1:max(peakarea)
            maxpeakarea(mxpk)=max(activsdf(peakarea==mxpk));
        end
        peakarea=(peakarea==find(maxpeakarea==max(maxpeakarea),1));
    elseif max(peakarea)==0
        peakarea(ppkt-60:ppkt)=1;
    end
    % limit of active period
    endlimactiv=find(peakarea,1)+find(activsdf(find(peakarea,1):end)<locnoise,1);
    
    %% find peak sdf time
    peaksdft(showdirs)=(find(activsdf(find(peakarea,1):endlimactiv)== ...
        max(activsdf(find(peakarea,1):endlimactiv)),1)+find(peakarea,1)-1) - aligntime;
    
    thdactiv=activsdf(find(peakarea,1):peaksdft(showdirs)+aligntime);
    %% compute auc
    if ~isempty(thdactiv)
        auc(showdirs)=round(max(cumsum(thdactiv)));
    else
        auc(showdirs)=0;
    end
    % if declining activity
    if activsdf(round(median(endfix(endfix>0))))> activsdf(aligntime)
        thdactiv=activsdf(find(peakarea,1))- ... 
            activsdf(find(peakarea,1): find(activsdf(find(peakarea,1):aligntime)== ...
            min(activsdf(find(peakarea,1):aligntime)),1)+find(peakarea,1)-1);
        if ~isempty(thdactiv)
        peaksdft(showdirs)=find(thdactiv==max(thdactiv),1)+find(peakarea,1)-1- aligntime;
        auc(showdirs)=-max(cumsum(thdactiv));
        else
             auc(showdirs)=0;
        end
        if length(thdactiv)==1 %got it wrong
            thdactiv=activsdf(find(peakarea,1):peaksdft(showdirs)+aligntime);
            if ~isempty(thdactiv)
            peaksdft(showdirs)=(find(activsdf(find(peakarea,1):endlimactiv)== ...
        max(activsdf(find(peakarea,1):endlimactiv)),1)+find(peakarea,1)-1) - aligntime;
            auc(showdirs)=max(cumsum(thdactiv));
            else
        auc(showdirs)=0;
    end
        end
    end
    
    %% compute slope
    if ~isempty(thdactiv)
    slopes(showdirs)=round((thdactiv(end)-thdactiv(1))/length(thdactiv)*1000); %in spk/s^e-2
    if activsdf(round(median(endfix(endfix>0))))> activsdf(aligntime)
    slopes(showdirs)=-slopes(showdirs);
        if length(thdactiv)==1 %got it wrong
            slopes(showdirs)=-slopes(showdirs);
        end
    end
    else
        slopes(showdirs)=0;
    end
end
end