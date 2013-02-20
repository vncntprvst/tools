function [p_sac,h_sac,p_rmanov,mcstats]=raststats(datalign)

tasktype=get(findobj('Tag','taskdisplay'),'String');
if ~iscell(tasktype)
    tasktype={tasktype};
end
mstart= str2double(get(findobj('Tag','msbefore'),'String'));
mstop= str2double(get(findobj('Tag','msafter'),'String'));
%% do stats for each raster
% datalign=datalign(~cellfun('isempty',{datalign.alignidx}));
numrast=length(datalign);

    %prealloc
    p_sac=nan(numrast,6);
    h_sac=nan(numrast,3);
    isnantrial=cell(numrast,1);
    samplemat=cell(numrast,1);
    for alignmtnum=1:numrast
        
        rasters=datalign(alignmtnum).rasters;
        allgreyareas=datalign(alignmtnum).allgreyareas;
        
        if ~isempty(rasters)
            
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
            allpostcue=nan(size(rasters,1),1);
            allbaseline=nan(size(rasters,1),1);
            allpresac=nan(size(rasters,1),1);
            allpostsac=nan(size(rasters,1),1);
            allperisac=nan(size(rasters,1),1);
            alldelay=nan(size(rasters,1),1);
            
            %% Statistic Information
            for num_trials = 1:size(rasters,1)
                timesmat = allgreyareas{num_trials}; %condtimes
                
                %       Measure mean firing rate in four time periods:
                %       - fixation period from (500 to 200) or 300 ms before target
                %       - visual period from 50 to 150 ms after visual stimulus onset
                %       - delay period covering the last 300 ms interval of the delay
                %       interval (if any)
                %       - presaccadic period covering the last 100 ms before saccade onset
                %       - postsaccadic period covering the first 100 ms after saccade onset
                
                %300ms of fixation period
                baseline = timesmat(1,1)-300 : timesmat(1,1)-1;   %300 ms to 1ms before cue
                
                %150ms period of visual response
                postcue = timesmat(1,1)+51 : timesmat(1,1)+150; %50ms to 150ms after cue presentation
                
                if ~sum(isnan(timesmat(2,:)))
                %100ms of pre-eye movement period
                presac = timesmat(2,1)-100 : timesmat(2,1)-1; %100ms before sac initation
                
                %100ms of eye movement period
                postsac = timesmat(2,1)+1 : timesmat(2,1)+100; %100ms before sac initation
                
                %perisactime
                perisac = timesmat(2,1)-50 : timesmat(2,1)+50; %100ms around sac initation
                
                if strcmp(tasktype{:},'memguided') % || strcmp(tasktype,'vg_saccades')
                    delay=timesmat(3,2)-300 : timesmat(3,2)-1;
                elseif strcmp(tasktype{:}, 'st_saccades') || strcmp(tasktype{:}, 'tokens')
                    delay=timesmat(2,1)-400 : timesmat(2,1)-101;
                else
                    delay=0;
                end
                
                %make changes above for gapstop
                else
                [presac,postsac,perisac]=deal(1);
                delay=0;
                end
                %conversion to firing rate (since epochs are different
                %durations)              
                
                
                if ~isnantrial{alignmtnum}(num_trials) && ~isnan(timesmat(2,1)) %% need data, and eye movement (or stop ...)
                    allpostcue(num_trials) = (nansum(rasters(num_trials, postcue))/length(postcue))*1000;
                    allbaseline(num_trials) = (nansum(rasters(num_trials, baseline))/length(baseline))*1000;
                    allpresac(num_trials) = (nansum(rasters(num_trials, presac))/length(presac))*1000;
                    allpostsac(num_trials) = (nansum(rasters(num_trials, postsac))/length(postsac))*1000;
                    allperisac(num_trials) = (nansum(rasters(num_trials, perisac))/length(perisac))*1000;
                    if delay
                        alldelay(num_trials) = (nansum(rasters(num_trials, delay))/length(delay))*1000;
                    end
                end
                
            end
            
            allpostcue=allpostcue(~isnantrial{alignmtnum});
            allbaseline=allbaseline(~isnantrial{alignmtnum});
            allpresac=allpresac(~isnantrial{alignmtnum});
            allpostsac=allpostsac(~isnantrial{alignmtnum});
            allperisac=allperisac(~isnantrial{alignmtnum});
            if delay
                alldelay=alldelay(~isnantrial{alignmtnum});
            end
            
            samplemat{alignmtnum}=[allbaseline'; allpostcue'; allpresac'; allpostsac'; allperisac'];
            if delay
                samplemat{alignmtnum}=[samplemat{alignmtnum};alldelay'];
            end
            
            if ~isempty(allbaseline) && ~isempty(allpresac)
            %Wilcoxon signed rank test, get p value (adding difference of mean
            %firing rate), and h (yes or no significance)
            [p_sac(alignmtnum,1),h_sac(alignmtnum,1)] = signrank(allbaseline, allpresac);
            p_sac(alignmtnum,2)=mean(allpresac)-mean(allbaseline);
            end
            
            if ~isempty(allpostsac) && ~isempty(allpresac)
            %if pre-sac inhibition and post-sac burst, the pre-sac Vs baseline
            % comparison might not give correct results, but that will be
            % caught by following pre/post comparison
            
            [p_sac(alignmtnum,3),h_sac(alignmtnum,2)] = signrank(allpresac, allpostsac);
            p_sac(alignmtnum,4)=mean(allpostsac)-mean(allpresac);
            end
            
            if ~isempty(allbaseline) && ~isempty(allperisac)
            % if saccade burst sharp, short and exacty at saccade time, the
            % first two tests may not catch it (100ms periods too long for that).
            % But perisaccadic period comparison with baseline should
            
            [p_sac(alignmtnum,5),h_sac(alignmtnum,3)] = signrank(allbaseline, allperisac);
            p_sac(alignmtnum,6)=mean(allperisac)-mean(allbaseline);
            end
%             datalign(alignmtnum).stats.p=p_sac(alignmtnum,:);
%             datalign(alignmtnum).stats.h=h_sac(alignmtnum,:);
            
        end
    end
    
    p_rmanov=nan(numrast,1);
    mcstats=cell(numrast,1);
    for alignmtnum=1:numrast
    [p_anovmr]=anova_rm(samplemat{alignmtnum},'off');
    p_rmanov(alignmtnum)=p_anovmr(2);
    if length(p_rmanov)>1 && p_rmanov(2)<0.05 %p(1) is inter-trial comparison, p(2) inter-group
        try
        [~,~,friedstats] = friedman(samplemat{alignmtnum}',1,'off');
                mcstats{alignmtnum}=multcompare(friedstats,'display','off');
        catch % won't work if just one good trial. Check friedman(cellfun(@(x) size(x,2)<2, samplemat)
            mcstats{alignmtnum}=0;
        end

    else
    mcstats{alignmtnum}=0;
    end
    end
    
