function [p_evt,h_evt]=eventraststats(datalign,event)

tasktype=get(findobj('Tag','taskdisplay'),'String');
if ~iscell(tasktype)
    tasktype={tasktype};
end
mstart= str2double(get(findobj('Tag','msbefore'),'String'));
mstop= str2double(get(findobj('Tag','msafter'),'String'));
%% do stats for each condition + all collapsed
% datalign=datalign(~cellfun('isempty',{datalign.alignidx}));
numrast=length(datalign);

%prealloc
p_evt=nan(numrast+1,6);
h_evt=nan(numrast+1,6);
isnantrial=cell(numrast,1);
samplemat=cell(numrast+1,1);
for alignmtnum=1:numrast+1
    
    if alignmtnum<=numrast
        rasters=datalign(alignmtnum).rasters;
        if size(rasters,1)<7
            continue
        end
        allgreyareas=datalign(alignmtnum).allgreyareas;
    end
    
    if ~isempty(rasters)
        if alignmtnum<=numrast % when alignmtnum is numrast+1, that's pooled data
            
            % have to find isnantrial, since stats have been extracted
            % from rdd_rasters_sdf
            aidx=datalign(alignmtnum).alignidx;
            start = aidx - mstart;
            stop = aidx + mstop;
            if start < 1
                start = 1;
            end
            if stop > length(rasters)
                stop = length(rasters);
            end
            isnantrial(alignmtnum)={zeros(1,size(rasters,1))};
            for szrast=1:size(rasters,1)
                if isnan(sum(rasters(szrast,start:stop)))
                    isnantrial{alignmtnum}(szrast)=1;
                end
            end
            
            
            %preallocate
            allbaseline=nan(size(rasters,1),1);
            allpreevt=nan(size(rasters,1),1);
            allpostevt=nan(size(rasters,1),1);
            allperievt=nan(size(rasters,1),1);
            alldelay=nan(size(rasters,1),1);
            
            %% Statistic Information
            for num_trials = 1:size(rasters,1)
                timesmat = allgreyareas{num_trials}; %condtimes
                
                %       Measure mean firing rate in different time periods:
                %       - fixation period from (500 to 200) or 300 ms before target
                %       - delay period covering the last 300 ms interval of the delay
                %       interval (if any)
                %       - pre-event period covering the last 100 ms before event onset
                %       - post-event period covering the first 100 ms after
                %       event onset, if saccade, or 50 to 150 ms after event
                %       onset if cue or reward
                
                delay=0; %unless later specified otherwise (for saccade alignement stats only
                
                %300ms of fixation period
                baseline = timesmat(1,1)-300 : timesmat(1,1)-1;   %300 ms to 1ms before cue
                
                if strcmp(event,'mainsacalign') && ~sum(isnan(timesmat(2,:)))
                    %100ms of pre-eye movement period
                    preevt = timesmat(2,1)-100 : timesmat(2,1)-1; %100ms before evt initation
                    
                    %100ms of eye movement period
                    postevt = timesmat(2,1)+1 : timesmat(2,1)+100; %100ms before evt initation
                    
                    %perisactime
                    perievt = timesmat(2,1)-49 : timesmat(2,1)+50; %100ms around evt initation
                    
                    if strcmp(tasktype{:},'memguided') % || strcmp(tasktype,'vg_saccades')
                        delay=timesmat(3,2)-300 : timesmat(3,2)-1;
                    elseif strcmp(tasktype{:}, 'st_saccades') || strcmp(tasktype{:}, 'tokens')
                        delay=timesmat(2,1)-400 : timesmat(2,1)-101;
                    end
                    
                    %detailed stats for gapstop will be performed separately
                    
                elseif strcmp(event,'tgtshownalign') %&& ~sum(isnan(timesmat(1,:)))
                    %100ms of pre-cue period
                    preevt = datalign(alignmtnum).alignidx-100 : datalign(alignmtnum).alignidx-1; %100ms before cue presentation
                    
                    %150ms period of visual response
                    postevt = datalign(alignmtnum).alignidx+21 : datalign(alignmtnum).alignidx+150; %21ms to 150ms after cue presentation
                    
                    %use postevt for 3rd test
                    perievt = postevt;
                    
                elseif strcmp(event,'rewardalign')
                    %100ms of pre-eye movement period
                    preevt = datalign(alignmtnum).alignidx-100 : datalign(alignmtnum).alignidx-1;
                    
                    %150ms period of reward response
                    postevt = datalign(alignmtnum).alignidx+51 : datalign(alignmtnum).alignidx+150;
                    
                    %use postevt for 3rd test
                    perievt = postevt;
                else
                    [preevt,postevt,perievt]=deal(1);
                end
                %conversion to firing rate (since epochs are different
                %durations)
                
                
                if ~isnantrial{alignmtnum}(num_trials) && ~isnan(timesmat(1,1)) && ~isnan(timesmat(2,1)) %% need data, cue and eye movement (or stop ...)
                    allbaseline(num_trials) = (nansum(rasters(num_trials, baseline))/length(baseline))*1000;
                    allpreevt(num_trials) = (nansum(rasters(num_trials, preevt))/length(preevt))*1000;
                    allpostevt(num_trials) = (nansum(rasters(num_trials, postevt))/length(postevt))*1000;
                    allperievt(num_trials) = (nansum(rasters(num_trials, perievt))/length(perievt))*1000;
                    if delay
                        alldelay(num_trials) = (nansum(rasters(num_trials, delay))/length(delay))*1000;
                    end
                else
                    isnantrial{alignmtnum}(num_trials)=1;
                end
            end
            
            allbaselines{alignmtnum}=allbaseline(~isnantrial{alignmtnum});
            allpreevts{alignmtnum}=allpreevt(~isnantrial{alignmtnum});
            allpostevts{alignmtnum}=allpostevt(~isnantrial{alignmtnum});
            allperievts{alignmtnum}=allperievt(~isnantrial{alignmtnum});
            if delay
                alldelays{alignmtnum}=alldelay(~isnantrial{alignmtnum});
            end
            
        else %pooled data
            try
                allbaselines{alignmtnum}=vertcat(allbaselines{:});
                allpreevts{alignmtnum}=vertcat(allpreevts{:});
                allpostevts{alignmtnum}=vertcat(allpostevts{:});
                allperievts{alignmtnum}=vertcat(allperievts{:});
                if delay
                    alldelays{alignmtnum}=vertcat(alldelays{:});
                end
            catch
                continue
            end
            if size(allbaselines{alignmtnum},1)<7 % minimum number of trials to be considered
                continue
            end
        end
        
        samplemat{alignmtnum}=[allbaselines{alignmtnum}'; allpreevts{alignmtnum}'; ...
            allpostevts{alignmtnum}'; allperievts{alignmtnum}'];
        if delay
            samplemat{alignmtnum}=[samplemat{alignmtnum};alldelays{alignmtnum}'];
        end
        if ~strcmp(event,'tgtshownalign') && ~strcmp(event,'rewardalign')
            %pre-event Vs baseline
            if ~isempty(allbaselines{alignmtnum}(~isnan(allbaselines{alignmtnum}))) && ~isempty(allpreevts{alignmtnum}(~isnan(allpreevts{alignmtnum})))
                %Wilcoxon signed rank test, get p value (adding difference of mean
                %firing rate), and h (yes or no significance)
                [p_evt(alignmtnum,1),h_evt(alignmtnum,1)] = signrank(allbaselines{alignmtnum}, allpreevts{alignmtnum});
                [h_evt(alignmtnum,2), ~, p_evt(alignmtnum,2)] = statcond({allbaselines{alignmtnum}' allpreevts{alignmtnum}'}, 'method', 'perm', 'naccu', 20000,'verbose','off');
                %             p_evt(alignmtnum,2)=mean(allpreevts{alignmtnum})-mean(allbaselines{alignmtnum});
            end
        end
        if ~strcmp(event,'tgtshownalign')
            %post-event Vs pre-event
            if ~isempty(allpostevts{alignmtnum}(~isnan(allpostevts{alignmtnum}))) && ~isempty(allpreevts{alignmtnum}(~isnan(allpreevts{alignmtnum})))
                %if pre-evt inhibition and post-evt burst, the pre-evt Vs baseline
                % comparison might not give correct results, but that will be
                % caught by following pre/post comparison
                [p_evt(alignmtnum,3),h_evt(alignmtnum,3)] = signrank(allpreevts{alignmtnum}, allpostevts{alignmtnum});
                [h_evt(alignmtnum,4), ~ ,p_evt(alignmtnum,4)] = statcond({allpreevts{alignmtnum}' allpostevts{alignmtnum}'}, 'method', 'perm', 'naccu', 20000,'verbose','off');
                %             p_evt(alignmtnum,4)=mean(allpostevts{alignmtnum})-mean(allpreevts{alignmtnum});
            end
        end
        %peri-event Vs baseline
        if ~isempty(allbaselines{alignmtnum}(~isnan(allbaselines{alignmtnum}))) && ~isempty(allperievts{alignmtnum}(~isnan(allperievts{alignmtnum})))
            % if evt burst sharp, short and exacty at evt time, the
            % first two tests may not catch it (100ms periods too long for that).
            % But perievt period comparison with baseline should
            [p_evt(alignmtnum,5),h_evt(alignmtnum,5)] = signrank(allbaselines{alignmtnum}, allperievts{alignmtnum});
            [h_evt(alignmtnum,6), ~, p_evt(alignmtnum,6)] = statcond({allbaselines{alignmtnum}' allperievts{alignmtnum}'}, 'method', 'perm', 'naccu', 20000,'verbose','off');
            %             p_evt(alignmtnum,6)=mean(allperievts{alignmtnum})-mean(allbaselines{alignmtnum});
        end
        %             datalign(alignmtnum).stats.p=p_evt(alignmtnum,:);
        %             datalign(alignmtnum).stats.h=h_evt(alignmtnum,:);
        
    end
end

% p_rmanov=nan(numrast+1,1);
% mcstats=cell(numrast+1,1);
% for alignmtnum=1:numrast+1
%     if size(samplemat{alignmtnum},2)
%     [p_anovmr]=anova_rm(samplemat{alignmtnum},'off');
%     p_rmanov(alignmtnum)=p_anovmr(2);
%     if length(p_rmanov)>1 && p_rmanov(2)<0.05 %p(1) is inter-trial comparison, p(2) inter-group
%         try
%             %note on multcompare: check use of Tukey Kramer ctype
%             [~,~,friedstats] = friedman(samplemat{alignmtnum}',1,'off');
%             mcstats{alignmtnum}=multcompare(friedstats,'display','off');
%         catch % won't work if just one good trial. Check friedman(cellfun(@(x) size(x,2)<2, samplemat)
%             mcstats{alignmtnum}=0;
%         end
%
%     else
%         mcstats{alignmtnum}=0;
%     end
%     end
% end
end

