% Benchmark Spike Sorting Programs
% Using a test case with 32 channel silicone probe + opto stimulation with
% photoelectric and movement artifacts.
% Spyking Circus / JRClust / Tridesclous / Kilosort (through spk2)
%% data export and create parameter files
% BatchExport(exportDir); RunSpykingCircus(exportDir) etc
DataExportGui

% run analysis

%% plot representative traces and summary figures %%
cmap=lines;
%% recording info
cd('D:\Data\Ephys\SpikeSortingBenchMarking\vIRt22_2018-10-16_18-43-54_5100_50ms1Hz5mW_ML')
recInfo=load('vIRt22_2018-10-16_18-43-54_5100_50ms1Hz5mW_CAR_info');
recInfo=recInfo.rec_info;
recordingStartTime=recInfo.recordingStartTime;
samplingRate=recInfo.samplingRate;
bitResolution=recInfo.bitResolution;

%% traces
cd('D:\Data\Ephys\SpikeSortingBenchMarking\vIRt22_2018-10-16_18-43-54_5100_50ms1Hz5mW_ML')
traces=load('vIRt22_2018-10-16_18-43-54_5100_50ms1Hz5mW_CAR_traces');
traces=int32(traces.rawData);

ShiftUp=int32(1:size(traces,1))*int32(median(max(traces,[],2)));
midTimeWindow=size(traces,2)/2-(samplingRate*5):size(traces,2)/2+(samplingRate*5)-1;% 1:60000;
% figure; plot(bsxfun(@plus,traces(:,midTimeWindow),ShiftUp')'); hold on

chNum=29;
figure; plot(traces(chNum,midTimeWindow)','k'); hold on

%% spikes
%% 4 RMS threshold
% cd('D:\Data\Ephys\SpikeSortingBenchMarking\vIRt22_2018-10-16_18-43-54_5100_50ms1Hz5mW_Spikes')
% RMSspikes=load('vIRt22_2018-10-16_18-43-54_5100_50ms1Hz5mW_CAR_spikes');
% RMSspikes=RMSspikes.spikes;
% RMSspikesTimes=[vertcat(RMSspikes.Offline_Threshold.data{:, 1}),...
%     false(numel(recInfo.exportedChan),1)];
% Somehow doesn't match ...

%5 RMS
% for chNum=1:size(RMSspikesTimes,1)
%     chRMSspikes=find(traces(chNum,midTimeWindow)<-rms(traces(chNum,midTimeWindow))*5);
%     chRMSspikes=find(RMSspikesTimes(chNum,midTimeWindow));
%     plot(chRMSspikes,int32(ones(numel(chRMSspikes),1))*min(traces(chNum,midTimeWindow))/2,...
%         'color',cmap(chNum,:),'LineStyle' ,'none','Marker','d'); %+ShiftUp(chNum))    
% end
% 4 RMS
    chRMSspikes=find(traces(chNum,midTimeWindow)<-rms(traces(chNum,midTimeWindow))*4);
    plot(chRMSspikes,int32(ones(numel(chRMSspikes),1))*min(traces(chNum,midTimeWindow))/2,...
        'color',cmap(chNum,:),'LineStyle' ,'none','Marker','d'); %+ShiftUp(chNum))    

%% Spiking Circus
% struct('parameterNames',{'file_format';'sampling_rate';...
%         'data_dtype';'nb_channels';'mapping';'overwrite';'output_dir';...
%         'N_t';'spike_thresh';'peaks';'isolation';'remove_median';...
%         'max_clusters';'smart_search';'smart_select';'cc_merge';...
%         'dispersion';'noise_thr';'make_plots';'gpu_only';...
%         'collect_all';'correct_lag';'auto_mode'},... %'max_elts','nclus_min'
%         'userParams',{'raw_binary';'30000';'int16';'32';'';'True';... %False to keep original binary file as is
%         '';'3';'7';'both';'True';'True';'15';'True';'True';...
%          '0.975';'2, 5';'0.9';'True';'False';'True';'True';'0.1'});
% Changed:
% N_t= 2 
% spike_thresh   = 5.5
% isolation = false
% dispersion     = (5, 5) 
% (in probe file ) radius            = 100
% the rest is as usual
SCspikes=LoadSpikeData_byElectrode('vIRt22_2018-10-16_18-43-54_5100_50ms1Hz5mW_nopp.result-merged.hdf5',...
    traces,numel(recInfo.exportedChan),samplingRate,bitResolution);
% for chNum=1:numel(recInfo.exportedChan)
%     figure; plot(traces(1,midTimeWindow)','k'); hold on
rmChuNm=recInfo.probeLayout(1).OEChannel;
chSCspikes=SCspikes.SpikeTimes{rmChuNm, 1}; chSCunits=SCspikes.Units{rmChuNm, 1};
chSCunits=chSCunits(chSCspikes>=midTimeWindow(1) & chSCspikes<=midTimeWindow(end));
chSCspikes=chSCspikes(chSCspikes>=midTimeWindow(1) & chSCspikes<=midTimeWindow(end))-...
    midTimeWindow(1)+1;
[unitFreq,chSCunitIDs]=hist(chSCunits,unique(chSCunits));
for unitNum=2:numel(chSCunitIDs)
    chSCUnitSpikes=chSCspikes(chSCunits==chSCunitIDs(unitNum));
    plot(chSCUnitSpikes,int32(ones(numel(chSCUnitSpikes),1))*min(traces(...
        chNum,midTimeWindow))/2+40,...
            'color',cmap(unitNum+1,:),'LineStyle' ,'none','Marker','d'); %+ShiftUp(chNum))     
end
% by units
SCspikes=LoadSpikeData('vIRt22_2018-10-16_18-43-54_5100_50ms1Hz5mW_nopp.result-merged.hdf5',traces);
SCspikes.waveforms=SCspikes.waveforms.*bitResolution;     
SCspikes.unitID=double(SCspikes.unitID);
[unitFreq,unitIDs]=hist(SCspikes.unitID,unique(SCspikes.unitID));
[unitFreq,freqIdx]=sort(unitFreq','descend');
unitFreq=unitFreq./sum(unitFreq)*100; unitIDs=unitIDs(freqIdx);
bestUnitsIdx=find(unitFreq>2);
bestUnits=unitIDs(unitIDs(bestUnitsIdx)>=~0);

%unacceptably high number of non-fitted spikes with spike_thresh = 5.5
% change to:
% spike_thresh   = 7
% dispersion     = (3, 3)

%% Kilosort
% testing with spk2 pipeline. Actually not usefull: designed for .kwik recordings
% Also not more user friendly than Kilosort
% not using those parameters, as compared to spk2_pipe's config file: 
% ops.fs                  = A.fs;
% ops.NchanTOT            = numel(A.idx_dat);
% ops.Nchan               = numel(cfg.chs);
% run modified spk2_pipe (see in C:\Code\SpikeSorting\spk2\)
KSspikes=LoadSpikeData_byElectrode('rez.mat',traces,numel(recInfo.exportedChan),...
    samplingRate,bitResolution);
chKSspikes=KSspikes.SpikeTimes{chNum, 1};chKSunits=double(KSspikes.Units{chNum, 1});
chKSunits=chKSunits(chKSspikes>=midTimeWindow(1) & chKSspikes<=midTimeWindow(end));
chKSspikes=chKSspikes(chKSspikes>=midTimeWindow(1) & chKSspikes<=midTimeWindow(end))-...
    midTimeWindow(1)+1;
[unitFreq,chKSunitIDs]=hist(chKSunits,unique(chKSunits));
for unitNum=1:numel(chKSunitIDs)
    chKSunitspikes=chKSspikes(chKSunits==chKSunitIDs(unitNum));
    plot(chKSunitspikes,int32(ones(numel(chKSunitspikes),1))*min(traces(...
        chNum,midTimeWindow))/2+80,...
        'color',cmap(unitNum+1,:),'LineStyle' ,'none','Marker','d'); %+ShiftUp(chNum))
end

%% JRClus
JRspikes=LoadSpikeData_byElectrode('vIRt22_2018-10-16_18-43-54_5100_50ms1Hz5mW_nopp_32Ch_jrc.mat',...
    traces,numel(recInfo.exportedChan),samplingRate,bitResolution);

rmChuNm=recInfo.probeLayout(chNum).OEChannel;
chJRspikes=JRspikes.SpikeTimes{rmChuNm, 1}; chJRunits=double(JRspikes.Units{rmChuNm, 1});
chJRunits=chJRunits(chJRspikes>=midTimeWindow(1) & chJRspikes<=midTimeWindow(end));
chJRspikes=chJRspikes(chJRspikes>=midTimeWindow(1) & chJRspikes<=midTimeWindow(end))-...
    midTimeWindow(1)+1;
[unitFreq,chJRunitIDs]=hist(chJRunits,unique(chJRunits));
for unitNum=2:numel(chJRunitIDs)
    chJRUnitSpikes=chJRspikes(chJRunits==chJRunitIDs(unitNum));
    plot(chJRUnitSpikes,int32(ones(numel(chJRUnitSpikes),1))*min(traces(...
        chNum,midTimeWindow))/2+120,...
            'color',cmap(unitNum+1,:),'LineStyle' ,'none','Marker','d'); %+ShiftUp(chNum))     
end

%% Tridesclous

%% UtraMegaSort
load('vIRt22_2018-10-16_18-43-54_5100_50ms1Hz5mW_CAR_spikes.mat');
unitIdx=spikes.assigns==(spikes.labels(chNum));
UMSspikes=spikes.spiketimes*spikes.params.Fs; %(unitIdx)*spikes.params.Fs;
% chUMSunits=spikes.labels(chNum,1);
UMSunits=spikes.assigns;
UMSunits=UMSunits(UMSspikes>=midTimeWindow(1) & UMSspikes<=midTimeWindow(end));
UMSspikes=UMSspikes(UMSspikes>=midTimeWindow(1) & UMSspikes<=midTimeWindow(end))-...
    midTimeWindow(1)+1;
[unitFreq,UMSunitIDs]=hist(UMSunits,unique(UMSunits));
[unitFreq,freqIdx]=sort(unitFreq','descend');
unitFreq=unitFreq./sum(unitFreq)*100; UMSunitIDs=UMSunitIDs(freqIdx);
for unitNum=2:numel(UMSunitIDs)
    chUMSunitspikes=UMSspikes(UMSunits==UMSunitIDs(unitNum));
    plot(chUMSunitspikes,int32(ones(numel(chUMSunitspikes),1))*min(traces(...
        chNum,midTimeWindow))/2+160,...
        'color',cmap(unitNum+1,:),'LineStyle' ,'none','Marker','d'); %+ShiftUp(chNum))
end






    
