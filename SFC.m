function [cohrfreq,cohrmag,SFcorr,trials]=SFC(filename,alignment,cluster,corrwind,preblocks,postblocks,option)
%Spike Field Coeherence analysis
% returns correlation/coherence between spikes and LFP signals in temporal 
% domain (cross correlation) and frequency domain (spike-field coherence) 
%VP - 10/1/2013
% example of variable inputs:
% filename='H125L6A2_17581';
% alignment='error2sac'; % 'sac';
% cluster='1';

%comparisons: either comparing multiple files, or one file over multiple conditions
if option==1
    load(filename);
    numcomp=size(dataaligned,2);
    trials=zeros(1,numcomp);
    comptype='alignement';
else  %debug if necessary
    SpikeFiles={[filename '_AllClus.mat']}; % previous format 'H12316301_AllClus.mat'
    LFPFiles={[filename '_LFP.mat']}; % previous format 'H12316301_LFP.mat'
    numcomp=length(filename);
    comptype='files';
end

%preallocate
rsLFP=cell(1,numcomp);
LFPData=cell(1,numcomp);
spikes=cell(1,numcomp);
cohrmag=cell(2,numcomp);
cohrfreq=cell(2,numcomp);
SFcorr=cell(1,numcomp);
epochsz=256;

for ldfl=1:numcomp
    if strcmp(comptype,'files')
        % load cluster file.
        load(SpikeFiles{ldfl});
        varlist=who;
        %% for some reason that doesn't work
        % varlist=varlist(~cellfun(@isempty,strfind(varlist,SpikeFiles{1}(1))))
        % [cellfun(@(x) eval([x '.title']), varlist,'UniformOutput',false)]
        %% so less efficient
        eval(['ClusAllData{ldfl} =' cell2mat(varlist(~cellfun(@isempty ,(cellfun(@(x) strfind(x,SpikeFiles{1}(1)), varlist, 'UniformOutput', false)))))]);
        clear(cell2mat(varlist(~cellfun(@isempty ,(cellfun(@(x) strfind(x,SpikeFiles{1}(1)), varlist, 'UniformOutput', false))))));
        
        load(LFPFiles{ldfl});
        varlist=who;
        eval(['LFPData{ldfl} =' cell2mat(varlist(~cellfun(@isempty ,(cellfun(@(x) strfind(x,SpikeFiles{1}(1)), varlist, 'UniformOutput', false)))))]);
        clear(cell2mat(varlist(~cellfun(@isempty ,(cellfun(@(x) strfind(x,SpikeFiles{1}(1)), varlist, 'UniformOutput', false))))));
        
        % get the cluster codes
        cluscode=ClusAllData{ldfl}.codes(:,1);
        
        % downsampling LFP to 500Hz
        rsLFP{ldfl} = resample((LFPData{ldfl}.values)',1, round(1/(500/(1/LFPData{ldfl}.interval))));
        
        % and convert spike trains to waveform of same sampling rate by binning
        % into 2ms bins (max one spike/bin)
        binwidth=2;
        numbins = ceil( LFPData{ldfl}.length / (binwidth * round((1/LFPData{ldfl}.interval)/1000)));
        spikes{ldfl} = zeros(ClusAllData{ldfl}.traces,numbins);
        for clusnum=1:ClusAllData{ldfl}.traces
            % spike times for each cluster
            clustimes=round(ClusAllData{ldfl}.times(cluscode==clusnum).*1000);
            spikes{ldfl}(clusnum,ceil(clustimes/binwidth))=1; %dirty point, as promised
        end
    else
        % get sampling rate
        load([cell2mat(regexp(filename,'^\w+_\d+','match')) 'f']);
        varlist=who;
        eval(['recSR =' cell2mat(varlist(~cellfun(@isempty ,(cellfun(@(x) strfind(x,filename(1)), varlist, 'UniformOutput', false)))))]);
        clear(cell2mat(varlist(~cellfun(@isempty ,(cellfun(@(x) strfind(x,filename(1)), varlist, 'UniformOutput', false))))));
        recSR=1/recSR.interval; %sampling rate
        
        %extract relevant segments
        LFPData{ldfl}=dataaligned(1,ldfl).rawsigs;
        LFPData{ldfl}=LFPData{ldfl}(:,round(max(dataaligned(1,ldfl).alignrawidx)-(round(1/(500/recSR)))*epochsz):round(max(dataaligned(1,ldfl).alignrawidx)-1)); %taking epochsz bins of 2ms before alignment
    end
end

if strcmp(comptype,'files')
    %% method for one electrode/tetrode and no trials
    samples = min(cellfun(@(x) length(x), rsLFP));
    trials=length(SpikeFiles);
    
    % make sure trials are the same length and pool all spikes into MUA
    for trnm=1:trials
        
        % plot me some spike waveform
        %     for wf=1:size(spikes{trnm},1)
        %         figure
        %         hold on
        %         spkdata=ClusAllData{trnm}.values(:,:,wf);
        %         % plot spread
        %         plot(mean(spkdata)+std(spkdata), ':', 'LineWidth', 1);
        %         plot(mean(spkdata)-std(spkdata), ':', 'LineWidth', 1);
        %         % plot confidence intervals
        %         spksem=std(spkdata)/ sqrt(size(spkdata,1));
        %         spksem = spksem * 1.96; % 95% of the data will fall within 1.96 standard deviations of a normal distribution
        %         plot(mean(spkdata)+spksem, 'r--', 'LineWidth', 2);
        %         plot(mean(spkdata)-spksem, 'r--', 'LineWidth', 2);
        %         plot(mean(spkdata),'k','LineWidth', 1);
        %         set(gca,'xlim',[0 32],'ylim',[-0.5 0.5]);
        %     end
        
        rsLFP{trnm}=rsLFP{trnm}(1:samples);
        spikes{trnm}=spikes{trnm}(:,1:samples);
        %     spikes{trnm}= sum(spikes{trnm})>0;
        %     spikes{trnm}=spikes{trnm}-mean(spikes{trnm});
        % tried the nifty method with neuron that has the less spikes :
        %spikes{trnm}= spikes{trnm}(sum(spikes{trnm},2)==min(sum(spikes{trnm},2)),:);
        % doesn't make it better
        
        % remove cell from MUA that drives all the LFP
        spikes{trnm}= spikes{trnm} ([1 2 4],:); %(sum(spikes{trnm},2)~=max(sum(spikes{trnm},2)),:);   % MUA is cell #3 (3,:)
    end
    
else
    %% method for recordings made with a task running (need condition to align to)
    binwidth=2;
    for ldfl=1:numcomp
        trials(ldfl)=size(LFPData{ldfl},1);
        for trnm=1:trials(ldfl)
            % downsampling LFP to 500Hz
            rsLFP{ldfl} = [rsLFP{ldfl} resample(LFPData{ldfl}(trnm,:),1,round(1/(500/recSR)))];
            
            % and extract epoch from rasters with same sampling rate
            trialepoch=dataaligned(1,ldfl).rasters(trnm,dataaligned(1,ldfl).alignidx-epochsz*binwidth:dataaligned(1,ldfl).alignidx-1);
            [~,bin] = histc(1:epochsz*binwidth,linspace(1,epochsz*binwidth,epochsz));
            sparsepoch = sparse(1:epochsz*binwidth,bin,trialepoch);
            rsSpikes=full(sum(sparsepoch)./sum(sparsepoch~=0));
            rsSpikes(isnan(rsSpikes))=0;
            % get spikes, format in serial sequence
            spikes{ldfl} = [spikes{ldfl} rsSpikes];
        end
    
    %% more detailed method (doesn't really work with long trials. Need short, typically 256ms long trial windows) )
    % define parameters
    timeunit = binwidth/1000 ;
    duration=epochsz*timeunit;
    timevector = (1:epochsz)*timeunit;
    df=1/duration;
    cohrfreq{2,ldfl} = (-epochsz/2:epochsz/2-1)*df;
    MUAfourier= zeros(trials(ldfl),length(cohrfreq{2,ldfl}));
    LFPfourier= zeros(trials(ldfl),length(cohrfreq{2,ldfl}));
    LFPMUAcorr= zeros(trials(ldfl),corrwind*2+1);
    
    for trnm=1:trials(ldfl)
        trspikes=spikes{ldfl}(epochsz*(trnm-1)+1:epochsz*trnm);
        trspikes=trspikes-mean(trspikes);
        trLFP=rsLFP{ldfl}(epochsz*(trnm-1)+1:epochsz*trnm);
        MUAfourier(trnm,:)=fft(trspikes);
        LFPfourier(trnm,:)=fft(trLFP);
        LFPMUAcorr(trnm,:)=xcorr(trspikes,trLFP,corrwind,'coeff');% +/- 100ms sliding window coeff for normalization
    end
    
    % cross-correlation 
%     SFcorr{ldfl}=nansum(LFPMUAcorr);
%     SFcorr{ldfl}=fullgauss_filtconv(SFcorr{ldfl},10,0)./(trials(ldfl)-sum(isnan(sum(LFPMUAcorr,2))));
      SFcorr{ldfl}=nanmean(LFPMUAcorr);
    
    %   Power spectra and cross spectrum.
    [CS_MUA_MUA, CS_MUA_LFP, CS_LFP_LFP] = deal(zeros(1,length(cohrfreq{2,ldfl})));
    for trnm=1:trials(ldfl)
        CS_MUA_MUA = CS_MUA_MUA + timeunit^2/duration*(MUAfourier(trnm,:).*conj(MUAfourier(trnm,:)))/trials(ldfl);
        CS_MUA_LFP = CS_MUA_LFP + timeunit^2/duration*(MUAfourier(trnm,:).*conj(LFPfourier(trnm,:)))/trials(ldfl);
        CS_LFP_LFP = CS_LFP_LFP + timeunit^2/duration*(LFPfourier(trnm,:).*conj(LFPfourier(trnm,:)))/trials(ldfl);
    end
    
    %   And then the coherence.
    cohr = CS_MUA_LFP.*conj(CS_MUA_LFP) ./CS_MUA_MUA ./CS_LFP_LFP;
    
    cohrmag{2,ldfl}=fftshift(cohr);

%     figure
%     plot(cohrfreq{2,ldfl},cohrmag{2,ldfl})
%     ylim([0 1]);  xlim([-50 50])
%     
    end
end




%% same calculation with mscohere
% In mscohere, Matlab's spectral functions % split data into multiple chunks, define by window (e.g., epochsz).
% That works, but depending on how the data is formatted, it may be wrong.
% Coherence requires to be calculated over several trials, so the following method
% is dirty if we don't format along multiple epochs (trials).

for cmpn=1:numcomp
    % calculate coherence
    [cohrmag{1,cmpn},cohrfreq{1,cmpn}]=mscohere(spikes{cmpn},rsLFP{cmpn},epochsz,0,epochsz,500);
    
    %calculate significance threshold
    numsection=floor(length(spikes{cmpn})/epochsz);
    cohrsiglev=1-0.05^(1/(numsection-1)); %only usable when more than one data section
    % for higher resolution, one can go ham with:
    % mscohere(spikes,rsLFP,hanning(1024),512,1024,500);
    
    %plot
%     figure;
%     bar(cohrfreq{1,cmpn}(3:find((cohrfreq{1,cmpn})<50,1,'last'),1),...
%         cohrmag{1,cmpn}(3:find((cohrfreq{1,cmpn})<50,1,'last'),1));
%     % plot(cohrfreq{cmpn}(2:find((cohrfreq{cmpn})<50,1,'last'),1),...
%     %     cohrmag{cmpn}(2:find((cohrfreq{cmpn})<50,1,'last'),1),'LineWidth',2.5);
%     hold on
%     plot(1:round(cohrfreq{1,cmpn}(find(cohrfreq{1,cmpn}<50,1,'last'))),...
%         ones(1,round(cohrfreq{1,cmpn}(find(cohrfreq{1,cmpn}<50,1,'last')))).*cohrsiglev,'r','LineWidth',2.5)
%     
%     title({'Coherence estimate'},'FontSize',20,'FontName','calibri');
%     xlabel({'Frequency (Hz)'},'FontSize',16,'FontName','calibri');
%     ylabel({'Magnitude'},'FontSize',16,'FontName','calibri');
end



