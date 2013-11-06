function [cohrfreq,cohrmag,SFcorr,Spikenum,trials]=SFC(filename,corrwind,epochrg,binwidth)
%% Spike Field Coeherence analysis
% Returns correlation/coherence between spikes and LFP signals in temporal
% domain (cross correlation) and frequency domain (spike-field coherence)
% Comparisons data from one file over multiple conditions
% Needs alignment file from GUI

%VP - 10/1/2013
% example of variable inputs:
% filename='H125L6A2_17581_error2sac_clus1';
% corrwind= 100;

load(filename);
numcomp=size(dataaligned,2);
if numcomp > 2 && strcmp(dataaligned(2).alignlabel,'stop_cancel')% keep only sac and nc
    dataaligned=dataaligned([1 3]);
    numcomp=size(dataaligned,2);
end
trials=zeros(1,numcomp);
comptype='alignement';

%preallocate
rsLFP=cell(1,numcomp);
LFPData=cell(1,numcomp);
SpikeData=cell(1,numcomp);
% spikes_o=cell(1,numcomp);
spikes=cell(1,numcomp);
cohrmag=cell(2,numcomp);
cohrfreq=cell(2,numcomp);
SFcorr=cell(3,numcomp);
epochsz=epochrg(2)-epochrg(1); %e.g. 256 bins
Spikenum=zeros(1,numcomp);

    % define parameters
    timeunit = binwidth/1000 ; %in ms
    duration=epochsz*timeunit;
    %timevector = (1:epochsz)*timeunit;
    df=1/duration; 
    cohrfreq{1,1} = 0:250/(epochsz/2/binwidth):250;
    cohrfreq{1,2} = 0:250/(epochsz/2/binwidth):250;
    cohrfreq{2,1} = (-epochsz/2/binwidth:epochsz/2/binwidth-1)*df;
    cohrfreq{2,2} = (-epochsz/2/binwidth:epochsz/2/binwidth-1)*df;
    
for cmpn=1:numcomp
    %% get sampling rate
    load([cell2mat(regexp(filename,'^\w+_\d+','match')) 'f']);
    varlist=who;
    eval(['recSR =' cell2mat(varlist(~cellfun(@isempty ,(cellfun(@(x) strfind(x,filename(1:3)), varlist, 'UniformOutput', false)))))]);
    clear(cell2mat(varlist(~cellfun(@isempty ,(cellfun(@(x) strfind(x,filename(1:3)), varlist, 'UniformOutput', false))))));
    recSR=1/recSR.interval; %sampling rate
    
    %% get epoch's LFP data

    LFPData{cmpn}=dataaligned(1,cmpn).rawsigs;    
        LFPData{cmpn}=LFPData{cmpn}(:,round(max(dataaligned(1,cmpn).alignrawidx)+epochrg(1)*recSR/1000):...
        round(max(dataaligned(1,cmpn).alignrawidx)+epochrg(2)*recSR/1000-1)); 
    
    %% unnecessarily split up operation: 
    % round(recSR*timeunit) is number of data point per bin
    % round(epochrg()/binwidth) is epoch size in ms. That is number of
    % bins, adjusted by bin size (in ms).
%     LFPData{cmpn}=LFPData{cmpn}(:,round(max(dataaligned(1,cmpn).alignrawidx)+(round(recSR*timeunit))*round(epochrg(1)/binwidth)):...
%         round(max(dataaligned(1,cmpn).alignrawidx)+(round(recSR*timeunit))*round(epochrg(2)/binwidth)-1)); 
    
    %% get epoch's Spike data
    % no need to compensate for sampling rate, already in ms
    SpikeData{cmpn}=dataaligned(1,cmpn).rasters;
    SpikeData{cmpn}=SpikeData{cmpn}(:,dataaligned(1,cmpn).alignidx+epochrg(1):...
        dataaligned(1,cmpn).alignidx+epochrg(2)-1);

    %% get spikes data     
    %pre-allocate
    MUAfourier= zeros(trials(cmpn),length(cohrfreq{2,cmpn}));
    LFPfourier= zeros(trials(cmpn),length(cohrfreq{2,cmpn}));
    LFPMUAxcorr= zeros(trials(cmpn),corrwind/binwidth*2+1);
    STA=nan(trials(cmpn),corrwind/binwidth*2+1);
    fullSTA=nan(trials(cmpn),recSR/1000*corrwind/binwidth*2+1);
    TrialCoher=zeros(epochsz/binwidth/2+1,trials(cmpn));
    trials(cmpn)=size(LFPData{cmpn},1);
    for trnm=1:trials(cmpn)
        % downsampling LFP to match bin size if necessary (e.g., 500Hz for 2ms bins)
        if (1/timeunit)/recSR ~= 1
            rsLFP{cmpn} = [rsLFP{cmpn} resample(LFPData{cmpn}(trnm,:),1,round(recSR*timeunit))];
        else
            rsLFP{cmpn} = [rsLFP{cmpn} LFPData{cmpn}(trnm,:)];
        end
        
        % try binning instead of using resample
%             [~,bin] = histc(1:LFPepochsz,linspace(1,LFPepochsz,LFPepochsz/(recSR/1000)/binwidth));
%             sparsepoch = sparse(1:LFPepochsz,bin,LFPData{cmpn}(trnm,:));
%             bLFP=full(sum(sparsepoch)./sum(sparsepoch~=0));
%             bLFP(isnan(bLFP))=0;
        
        
        %% old method to extract epoch from rasters
%         trialepoch=dataaligned(1,cmpn).rasters(trnm,dataaligned(1,cmpn).alignidx+epochrg(1):dataaligned(1,cmpn).alignidx+epochrg(2)-1);
%         
%         % bin spikes if necessary
%         if binwidth>1
%             [~,bin] = histc(1:epochsz,linspace(1,epochsz,epochsz/binwidth));
%             sparsepoch_o = sparse(1:epochsz,bin,trialepoch);
%             rsSpikes_o=full(sum(sparsepoch_o)./sum(sparsepoch_o~=0));
%             rsSpikes_o(isnan(rsSpikes_o))=0;
%             % get spikes, format in serial sequence
%             spikes_o{cmpn} = [spikes_o{cmpn} rsSpikes_o];
%         else
%             spikes_o{cmpn} = [spikes_o{cmpn} trialepoch];
%         end
        
        %% new method
        if binwidth>1
            [~,bin] = histc(1:epochsz,linspace(1,epochsz,epochsz/binwidth));
            sparsepoch = sparse(1:epochsz,bin,SpikeData{cmpn}(trnm,:));
            rsSpikes=full(sum(sparsepoch)./sum(sparsepoch~=0));
            rsSpikes(isnan(rsSpikes))=0;
            % get spikes, format in serial sequence
            spikes{cmpn} = [spikes{cmpn} rsSpikes];
        else
            spikes{cmpn} = [spikes{cmpn} SpikeData{cmpn}(trnm,:)];
        end
    end

     
    for trnm=1:trials(cmpn)
        % spikes for period of interest in that trial
        trspikes=spikes{cmpn}(epochsz/binwidth*(trnm-1)+1:epochsz/binwidth*trnm);
        % LFP for period of interest in that trial
        trLFP=rsLFP{cmpn}(epochsz/binwidth*(trnm-1)+1:epochsz/binwidth*trnm);
        % cross-correlation
        LFPMUAxcorr(trnm,:)=xcorr(trLFP,trspikes,corrwind/binwidth);% LFP summation over +/- sliding window (e.g., 100ms) triggered by spikes. Use 'coeff' for normalization: not advised here
        
        % simply summing LFP fragments around each spike within that window
        % (dividing by number of spikes below)
        windowct=find(trspikes);
        if ~isempty(windowct)
            LFPfrag=nan(length(windowct),corrwind/binwidth*2+1);
            fullLFPfrag=nan(length(windowct),recSR/1000*corrwind/binwidth*2+1);
            for spkwd=1:length(windowct)
                if windowct(spkwd)-corrwind/binwidth<1 || windowct(spkwd)+corrwind/binwidth>epochsz/binwidth
                    continue;
                else
                    LFPfrag(spkwd,:)=trLFP(windowct(spkwd)-corrwind/binwidth:windowct(spkwd)+corrwind/binwidth);
                    fullLFPfrag(spkwd,:)=LFPData{cmpn}(trnm,windowct(spkwd)*50-(corrwind/binwidth)*50:windowct(spkwd)*50+(corrwind/binwidth)*50); % not downsampled fragment
%                     plot(fullLFPfrag);
%                     pause
                    Spikenum(cmpn)=Spikenum(cmpn)+1;
                end
            end
            STA(trnm,:)=nansum(LFPfrag); 
            fullSTA(trnm,:)=nansum(fullLFPfrag); 
        else
            STA(trnm,:)=nan(1,corrwind/binwidth*2+1);
            fullSTA(trnm,:)=nan(1,recSR/1000*corrwind/binwidth*2+1);
        end
%         fullSTAsem(trnm,:)=nanstd(fullLFPfrag)/ sqrt(size(fullLFPfrag,1)); %standard error of the mean
%         fullSTAsem(trnm,:) = fullSTAsem(trnm,:) * 1.96;       
%         figure; hold on;
%         patch([1:length(fullSTA(trnm,:)),fliplr(1:length(fullSTA(trnm,:)))],...
%             [-fullSTAsem(trnm,:),fliplr(fullSTAsem(trnm,:))],'b','EdgeColor','none','FaceAlpha',0.5);
% %          plot(fullSTA(trnm,:)./Spikenum(cmpn));
%         set(gca,'xlim',[0 length(fullLFPfrag)]);
        % coherence with Matlab's mscohere
        TrialCoher(:,trnm)=mscohere(trspikes,trLFP,hanning(2*corrwind/binwidth+1),[],epochsz/binwidth,500); %frequencies will be [0 250] in nfft/2 steps 
            % example for higher resolution: mscohere(spikes,rsLFP,hanning(1024),512,1024,500);
        % Fourier transforms for spectral calculations
        trspikes=trspikes-mean(trspikes);  
        MUAfourier(trnm,:)=fft(trspikes);
        LFPfourier(trnm,:)=fft(trLFP);
    end
    
    %% average values over trials
    %     SFcorr{cmpn}=nansum(LFPMUAcorr);
    %     SFcorr{cmpn}=fullgauss_filtconv(SFcorr{cmpn},10,0)./(trials(cmpn)-sum(isnan(sum(LFPMUAcorr,2))));
    
    cohrmag{1,cmpn}=nanmean(TrialCoher,2); % bar(0:250/(epochsz/2):250,cohrmag{1,cmpn})
    
    %% Power spectra and cross spectrum.
    [CS_MUA_MUA, CS_MUA_LFP, CS_LFP_LFP] = deal(zeros(1,length(cohrfreq{2,cmpn})));
    for trnm=1:trials(cmpn)
        CS_MUA_MUA = CS_MUA_MUA + timeunit^2/duration*(MUAfourier(trnm,:).*conj(MUAfourier(trnm,:)))/trials(cmpn);
        CS_MUA_LFP = CS_MUA_LFP + timeunit^2/duration*(MUAfourier(trnm,:).*conj(LFPfourier(trnm,:)))/trials(cmpn);
        CS_LFP_LFP = CS_LFP_LFP + timeunit^2/duration*(LFPfourier(trnm,:).*conj(LFPfourier(trnm,:)))/trials(cmpn);
    end
    
    %% calculate coherence with 'manual' method
    cohr = CS_MUA_LFP.*conj(CS_MUA_LFP) ./CS_MUA_MUA ./CS_LFP_LFP;
    cohrmag{2,cmpn}=fftshift(cohr);
    
    %collect values
    SFcorr{1,cmpn}=STA;
    SFcorr{2,cmpn}=LFPMUAxcorr; 
    SFcorr{3,cmpn}=fullSTA;
    
%% calculate significance threshold
%     numsection=floor(length(spikes{cmpn})/epochsz);
%     cohrsiglev=1-0.05^(1/(numsection-1));
    
    
%% plots
%           figure
%     %     plot(cohrfreq{2,cmpn},cohrmag{2,cmpn})
%     %     ylim([0 1]);  xlim([-50 50])
%         plot(SFcorr{1,cmpn});
%         hold on
%         plot(SFcorr{2,cmpn},'r');
%         set(gca,'xlim',[1 65],'xtick',2 : 30 : 62,'xticklabel',[-60 0 60])
%         % STA confidence interval
%         STAsem=std(LFPMUAxcorr)/ sqrt(size(LFPMUAxcorr,1)); %standard error of the mean
%         STAsem = STAsem * 1.96;
%         patch([1:length(SFcorr{2,cmpn}),fliplr(1:length(SFcorr{2,cmpn}))],[SFcorr{2,cmpn}-STAsem,fliplr(SFcorr{2,cmpn}+STAsem)],'r','EdgeColor','none','FaceAlpha',0.1);

        
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



