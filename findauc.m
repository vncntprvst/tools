function [auc,slopes,peaksdft,nadirsdft,modulationinfo]=findauc(filename,dataaligned,dirs)
% get area under curve for all or selected direction
% auc is computed for a continuous region above 20% of peak response, from
% point that reach threshold to peak
% Also compute slope and peak response
global directory slash

% tasktype=get(findobj('Tag','taskdisplay'),'String');
mstart= str2double(get(findobj('Tag','msbefore'),'String'));
if isnan(mstart)
    mstart=1000;
end
mstop= str2double(get(findobj('Tag','msafter'),'String'));
if isnan(mstop)
    mstop=500;
end

%% load alignement file if necessary
%filename='R113L6A2_18900';
if ~isstruct(dataaligned)
    algdir=[directory,'processed',slash,'aligned',slash];
    load([algdir,filename,'_sac.mat']);
end

%% define which dir
if strcmp(dirs,'all')
    bestdirs=find(~cellfun(@isempty, {dataaligned.alignidx}));
elseif strcmp(dirs,'active')
    %based on h stats
    filehstat=arrayfun(@(x) sum(x{:}.h), {dataaligned(~cellfun(@isempty, {dataaligned.stats})).stats});
    bestdirs=find(filehstat);%==max(filehstat));
elseif strcmp(dirs,'best')
    gooddirs=find(arrayfun(@(x) nansum(x{:}.h), {dataaligned(~cellfun(@isempty, {dataaligned.stats})).stats}));
    maxmeandiffs=arrayfun(@(x) max(x{:}.p), {dataaligned(gooddirs).stats});
    bestdirs=gooddirs(maxmeandiffs==max(maxmeandiffs));
end

%% compute auc and slope
auc=nan(1,length(bestdirs));
slopes=nan(2,length(bestdirs)); % line 1: rise ; line 2: fall
peaksdft=nan(1,length(bestdirs));
nadirsdft=nan(1,length(bestdirs));

modulationinfo=cell(1,length(bestdirs));
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
        if isnan(baseline)
            return
        end
        if ~isnantrial{showdirs}(num_trials)
            allbaseline(num_trials) = (nansum(bdrasters(num_trials, baseline))/length(baseline))*1000;
            endfix(num_trials)=baseline(end);
        end
        
    end
    %% threshold activity
    %fixation period noise
    fixnoise = max(mean(allbaseline(~isnan(allbaseline))) + 2*std(allbaseline(~isnan(allbaseline))),1); % that is to say, if fixnoise is 0, set it to 1
    %default threshold at 0.2 * peak response was too high
    activsum=nansum(bdrasters);
    activsdf=spike_density(activsum,20)./size(bdrasters,1);
    if length(activsdf)==1 || isempty(activsdf)
        peaksdft(showdirs)=nan(1,1);
        auc(showdirs)=nan(1,1);
        slopes(showdirs)=nan(1,1);
        continue
    end
    % presumed peak time
    ppkt=find(activsdf(aligntime-400:aligntime+200)==max(activsdf(aligntime-400:aligntime+200)),1)+aligntime-401;
    %% compute lead time
    %     The criterion for significant modulation was set at a discharge frequency
    %     (in at least two successive 5 ms bins) more than 2 standard deviations
    %     above or below the mean level of discharge in a 200 ms (40 bins)
    %     ‘control’ period immediately prior to the visual event or saccade onset.
    %     Onset latency was calculated to the leading edge of the first significant bin.
    leadtime=ppkt;
    while logical(sum(find(activsdf(leadtime-4:leadtime)>fixnoise)))
        leadtime=leadtime-1;
    end
    %leadtime=ppkt-find(activsdf(ppkt:-1:1)<fixnoise,1)+1;
    timetoonset=aligntime-leadtime;
    % assess ramp: if multiple threshold cross - not simple ramp up or
    % down
    pre_peaks=find(activsdf(leadtime:-1:round(median(endfix(endfix>0))))>fixnoise, 1);
    if ~isempty(pre_peaks)
        slopeshape='wobbly';
    else
        slopeshape='smooth';
    end
    modulationinfo(showdirs,1:3)={timetoonset,aligntime-ppkt,slopeshape};
    %local noise
    locnoise = median(activsdf(leadtime-60:leadtime)) + 2*std(activsdf(leadtime-60:leadtime)); %relaxed criteria because bursts generate high std
    if ceil(locnoise)>floor(activsdf(ppkt))
        locnoise = 3*std(activsdf(leadtime-60:leadtime));
    end
    if isnan(locnoise) || ~locnoise
        peaksdft(showdirs)=nan(1,1);
        auc(showdirs)=nan(1,1);
        slopes(showdirs)=nan(1,1);
        continue
    end
    %restrict to period of interest as much as possible
    fixtoppkt=zeros(1,length(activsdf));
    fixtoppkt(min(ppkt,round(median(endfix(endfix>0)))):ppkt)=activsdf(min(ppkt,round(median(endfix(endfix>0)))):ppkt);
    peakarea=bwlabel(fixtoppkt>locnoise);
    
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
    
    %% find peak sdf time (time referenced to alignment time)
    peaksdft(showdirs)=(find(activsdf(find(peakarea,1):endlimactiv)== ...
        max(activsdf(find(peakarea,1):endlimactiv)),1)+find(peakarea,1)-1) - aligntime;
    
    %% find nadir
    nadirsdft(showdirs) = find(activsdf(min(ppkt,round(median(endfix(endfix>0)))):endlimactiv)== ...
        min(activsdf(min(ppkt,round(median(endfix(endfix>0)))):endlimactiv)),1)+min(ppkt,round(median(endfix(endfix>0)))) - aligntime;
     
    %% compute auc of peak area
    thdactiv=activsdf(find(peakarea,1):peaksdft(showdirs)+aligntime);
    if ~isempty(thdactiv)
        peakdata=activsdf(find(peakarea,1):find(peakarea,1,'last'));
        normpeakdata=peakdata/median(peakdata); normpeakdata=normpeakdata./max(normpeakdata)*100;
        auc(showdirs)=round(max(cumsum(normpeakdata))); 
    else
        auc(showdirs)=0;
    end
    
    %% if declining activity
    
    if activsdf(round(median(endfix(endfix>0))))> activsdf(aligntime) && ...
            (peaksdft(showdirs)+aligntime > aligntime || peaksdft(showdirs)+aligntime < round(median(endfix(endfix>0))))
        thdactiv=activsdf(find(peakarea,1))- ...
            activsdf(find(peakarea,1): find(activsdf(find(peakarea,1):aligntime+100)== ...
            min(activsdf(find(peakarea,1):aligntime+100)),1)+find(peakarea,1)-1);
        if ~isempty(thdactiv)
            nadirsdft(showdirs)=find(thdactiv==max(thdactiv),1)+find(peakarea,1)-1- aligntime;
            if nadirsdft(showdirs)==100 % increase limit, as nadir may happen after aligntime +100
                thdactiv=activsdf(find(peakarea,1))- ...
                    activsdf(find(peakarea,1): find(activsdf(find(peakarea,1):min([aligntime+200 length(activsdf)]))== ...
                    min(activsdf(find(peakarea,1):min([aligntime+200 length(activsdf)]))),1)+find(peakarea,1)-1);
                nadirsdft(showdirs)=find(thdactiv==max(thdactiv),1)+find(peakarea,1)-1- aligntime;
            end
            auc(showdirs)=-max(cumsum(thdactiv));
        else
            auc(showdirs)=0;
        end
        if length(thdactiv)==1 %got it wrong
            thdactiv=activsdf(find(peakarea,1):peaksdft(showdirs)+aligntime);
            if ~isempty(thdactiv)
                nadirsdft(showdirs)=(find(activsdf(find(peakarea,1):endlimactiv)== ...
                    max(activsdf(find(peakarea,1):endlimactiv)),1)+find(peakarea,1)-1) - aligntime;
                auc(showdirs)=max(cumsum(thdactiv));
            else
                auc(showdirs)=0;
            end
        end
    elseif activsdf(peaksdft(showdirs)+aligntime)> activsdf(aligntime) && ...
            (peaksdft(showdirs)+aligntime < aligntime && peaksdft(showdirs)+aligntime > round(median(endfix(endfix>0))))
        thdactiv=activsdf(find(peakarea,1))- ...
            activsdf(find(peakarea,1): find(activsdf(find(peakarea,1):aligntime+100)== ...
            min(activsdf(find(peakarea,1):aligntime+100)),1)+find(peakarea,1)-1);
        if ~isempty(thdactiv)
            nadirsdft(showdirs)=find(thdactiv==max(thdactiv),1)+find(peakarea,1)-1- aligntime;
            if nadirsdft(showdirs)==100 % increase limit, as nadir may happen after aligntime +100
                thdactiv=activsdf(find(peakarea,1))- ...
                    activsdf(find(peakarea,1): find(activsdf(find(peakarea,1):min([aligntime+200 length(activsdf)]))== ...
                    min(activsdf(find(peakarea,1):min([aligntime+200 length(activsdf)]))),1)+find(peakarea,1)-1);
                nadirsdft(showdirs)=find(thdactiv==max(thdactiv),1)+find(peakarea,1)-1- aligntime;
            end
        end
    end
    
    %% compute slopes
    if ~isempty(thdactiv) && ~isnan(timesmat(3,2)) && ~isnan(timesmat(1,1))
        % smoothen curve
        activsdf=spike_density(activsum,50)./size(bdrasters,1);
        % put in chronological order cue, peak, nadir
        if timesmat(1,1) > peaksdft(showdirs)+aligntime
            threetimes=[timesmat(3,2) peaksdft(showdirs)+aligntime nadirsdft(showdirs)+aligntime];
        else
            threetimes=[timesmat(1,1) peaksdft(showdirs)+aligntime nadirsdft(showdirs)+aligntime];
        end
        threetimes=sort(threetimes(~isnan(threetimes)));
        if length(threetimes)>1
            period1=round((activsdf(threetimes(2))-activsdf(threetimes(1)))/(threetimes(2)-threetimes(1))*1000);
        else
            period1=nan(1,1);
        end
        if length(threetimes)>2
            period2=round((activsdf(threetimes(3))-activsdf(threetimes(2)))/(threetimes(3)-threetimes(2))*1000);
        else
            period2=nan(1,1);
        end
        if nanmax([period1 period2])>0
            slopes(1,showdirs)=nanmax([period1 period2]);
        end
        % if ~plateau between peak and aligntime, and nadir post-aligntime,
        % fall will be sharper. Keep it.
        if nanmin([period1 period2])<0
            if nadirsdft(showdirs)>0 && peaksdft(showdirs)<0
                slopes(2,showdirs)=nanmin([nanmin([period1 period2]) round((activsdf(nadirsdft(showdirs)+aligntime)-activsdf(aligntime))/nadirsdft(showdirs)*1000)]);
            else
                slopes(2,showdirs)=nanmin([period1 period2]);
            end
        end
    end
      
end
end