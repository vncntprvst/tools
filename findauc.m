function [auc,slopes,peaksdft,modulationinfo]=findauc(filename,dataaligned,dirs)
% get area under curve for all or selected direction
% auc is computed for a continuous region above 20% of peak response, from
% point that recah threshold to peak
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
slopes=nan(1,length(bestdirs));
peaksdft=nan(1,length(bestdirs));
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
    activsdf=spike_density(activsum,15)./size(bdrasters,1);
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
       pre_peaks=find(activsdf(leadtime:-1:round(median(endfix(endfix>0))))>fixnoise);
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