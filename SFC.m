function [cohrfreq,cohrmag,SFcorr,trials]=SFC(filename,corrwind,preblocks,postblocks)
%Spike Field Coeherence analysis
% returns correlation/coherence between spikes and LFP signals in temporal
% domain (cross correlation) and frequency domain (spike-field coherence)
%% needs recordings made with a task running (need condition to align to)
%VP - 10/1/2013
% example of variable inputs:
% filename='H125L6A2_17581_error2sac_clus1';

%comparisons: either comparing multiple files, or one file over multiple conditions
load(filename);
numcomp=size(dataaligned,2);
trials=zeros(1,numcomp);
comptype='alignement';

%preallocate
rsLFP=cell(1,numcomp);
LFPData=cell(1,numcomp);
spikes=cell(1,numcomp);
cohrmag=cell(2,numcomp);
cohrfreq=cell(2,numcomp);
SFcorr=cell(2,numcomp);
epochsz=256; %256 bins
binwidth=2;  %2 ms per bin
    % define parameters
    timeunit = binwidth/1000 ;
    duration=epochsz*timeunit;
    timevector = (1:epochsz)*timeunit;
    df=1/duration; 
    cohrfreq{1,1} = 0:250/(256/2):250;
    cohrfreq{1,2} = 0:250/(256/2):250;
    cohrfreq{2,1} = (-epochsz/2:epochsz/2-1)*df;
    cohrfreq{2,2} = (-epochsz/2:epochsz/2-1)*df;
    
for cmpn=1:numcomp
    %% get sampling rate
    load([cell2mat(regexp(filename,'^\w+_\d+','match')) 'f']);
    varlist=who;
    eval(['recSR =' cell2mat(varlist(~cellfun(@isempty ,(cellfun(@(x) strfind(x,filename(1)), varlist, 'UniformOutput', false)))))]);
    clear(cell2mat(varlist(~cellfun(@isempty ,(cellfun(@(x) strfind(x,filename(1)), varlist, 'UniformOutput', false))))));
    recSR=1/recSR.interval; %sampling rate
    
    %% get LFP data
    LFPData{cmpn}=dataaligned(1,cmpn).rawsigs;
    LFPData{cmpn}=LFPData{cmpn}(:,round(max(dataaligned(1,cmpn).alignrawidx)-(round(1/(500/recSR)))*epochsz):round(max(dataaligned(1,cmpn).alignrawidx)-1)); %taking epochsz bins of 2ms before alignment

    %% get spikes data
    trials(cmpn)=size(LFPData{cmpn},1);
    for trnm=1:trials(cmpn)
        % downsampling LFP to 500Hz
        rsLFP{cmpn} = [rsLFP{cmpn} resample(LFPData{cmpn}(trnm,:),1,round(1/(500/recSR)))];
        
        % and extract epoch from rasters with same sampling rate
        trialepoch=dataaligned(1,cmpn).rasters(trnm,dataaligned(1,cmpn).alignidx-epochsz*binwidth:dataaligned(1,cmpn).alignidx-1);
        [~,bin] = histc(1:epochsz*binwidth,linspace(1,epochsz*binwidth,epochsz));
        sparsepoch = sparse(1:epochsz*binwidth,bin,trialepoch);
        rsSpikes=full(sum(sparsepoch)./sum(sparsepoch~=0));
        rsSpikes(isnan(rsSpikes))=0;
        % get spikes, format in serial sequence
        spikes{cmpn} = [spikes{cmpn} rsSpikes];
    end
      
    %pre-allocate
    MUAfourier= zeros(trials(cmpn),length(cohrfreq{2,cmpn}));
    LFPfourier= zeros(trials(cmpn),length(cohrfreq{2,cmpn}));
    LFPMUAxcorr= zeros(trials(cmpn),corrwind*2+1);
    STA=zeros(trials(cmpn),corrwind*2+1);
    TrialCoher=zeros(epochsz/2+1,trials(cmpn));
    
    for trnm=1:trials(cmpn)
        % spikes for period of interest in that trial
        trspikes=spikes{cmpn}(epochsz*(trnm-1)+1:epochsz*trnm);
        % LFP for period of interest in that trial
        trLFP=rsLFP{cmpn}(epochsz*(trnm-1)+1:epochsz*trnm);
        % cross-correlation
        LFPMUAxcorr(trnm,:)=xcorr(trspikes,trLFP,corrwind,'coeff');% +/- sliding window (e.g., 100ms). Coeff for normalization
        % simply averaging LFP fragments around each spike within that window
        windowct=find(trspikes);
        if ~isempty(windowct)
            LFPfrag=nan(length(windowct),corrwind*2+1);
            for spkwd=1:length(windowct)
                if windowct(spkwd)-corrwind<1 || windowct(spkwd)+corrwind>epochsz
                    continue;
                else
                    LFPfrag(spkwd,:)=trLFP(windowct(spkwd)-corrwind:windowct(spkwd)+corrwind);
                end
            end
            STA(trnm,:)=nanmean(LFPfrag); 
        else
            STA(trnm,:)=nan(1,corrwind*2+1);
        end
        % coherence with Matlab's mscohere
        TrialCoher(:,trnm)=mscohere(trspikes,trLFP,hanning(2*corrwind+1),[],256,500); %frequencies will be [0 250] in nfft/2 steps 
            % example for higher resolution: mscohere(spikes,rsLFP,hanning(1024),512,1024,500);
        % Fourier transforms for spectral calculations
        trspikes=trspikes-mean(trspikes);  
        MUAfourier(trnm,:)=fft(trspikes);
        LFPfourier(trnm,:)=fft(trLFP);
    end
    
    %% average values over trials
    %     SFcorr{cmpn}=nansum(LFPMUAcorr);
    %     SFcorr{cmpn}=fullgauss_filtconv(SFcorr{cmpn},10,0)./(trials(cmpn)-sum(isnan(sum(LFPMUAcorr,2))));
    SFcorr{1,cmpn}=nanmean(STA);
    SFcorr{2,cmpn}=nanmean(LFPMUAxcorr);
    cohrmag{1,cmpn}=nanmean(TrialCoher'); % bar(0:250/(256/2):250,cohrmag{1,cmpn})
    
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
    
    %     figure
    %     plot(cohrfreq{2,cmpn},cohrmag{2,cmpn})
    %     ylim([0 1]);  xlim([-50 50])
    %

%% calculate significance threshold
%     numsection=floor(length(spikes{cmpn})/epochsz);
%     cohrsiglev=1-0.05^(1/(numsection-1));
    
    
%% plot
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



