figure; cmap=lines; hold on;
clusNum=1;
     [~,plotIdx]=sort(miSite_clu(:,clusNum));[~,plotIdx]=sort(plotIdx);
for wfNum=1:size(miSite_clu,1)
    plot(mean(squeeze(ctrWav_clu{clusNum}(:,plotIdx(wfNum),:)),2),'color',[cmap(wfNum,:) 1-(wfNum/10)]);
end

figure; cmap=lines;
for clusNum=1:length(ctrWav_clu)
    subplot(floor(sqrt(length(ctrWav_clu))),...
        ceil(length(ctrWav_clu)/floor(sqrt(length(ctrWav_clu)))),clusNum);
    hold on;
%     [~,plotIdx]=sort(miSite_clu(:,clusNum));[~,plotIdx]=sort(plotIdx);
    for wfNum=1:size(miSite_clu,1)
        plot(mean(squeeze(ctrWav_clu{clusNum}(:,plotIdx(wfNum),:)),2),'color',[cmap(wfNum,:) 1-(wfNum/10)]);
    end
end

% % read _spkwav.jrc file
% “_spkwav.bin” file
% Binary file containing filtered waveforms per spike. 
% Dimension is described in S0.dimm_spk Format: nSamples x nSites_spk x nSpikes: real.
% e.g., dimm = 32 9 98336 (datapoints, best channels, number of waveforms) 

dirListing=dir;
vcFile=dirListing(~cellfun('isempty',cellfun(@(x) strfind(x,'_spkwav'),...
            {dirListing.name},'UniformOutput',false))).name;
S0struct=dirListing(~cellfun('isempty',cellfun(@(x) strfind(x,'_jrc.mat'),...
            {dirListing.name},'UniformOutput',false))).name;
dimm=load(S0struct, 'dimm_spk');dimm=dimm.dimm_spk;
vcDataType = 'int16';
fid=fopen(vcFile, 'r');
% mnWav = fread_workingresize(fid, dimm, vcDataType); 
mnWav = fread(fid, prod(dimm), ['*', vcDataType]);
if numel(mnWav) == prod(dimm)
    mnWav = reshape(mnWav, dimm);
else
    dimm2 = floor(numel(mnWav) / dimm(1));
    if dimm2 >= 1
        mnWav = reshape(mnWav, dimm(1), dimm2);
    else
        mnWav = [];
    end
end
if ~isempty(vcFile), fclose(fid); end

figure; hold on;
for meanwf=1:10
    plot(mnWav(:,1,meanwf));
end

clusterInfo = ImportJRClusSortInfo('SpVi12_1107_WR_MS_LS500mHz2ms6_nopp_24Ch.csv');
unique(clusterInfo.clusterNum)
sum(clusterInfo.clusterNum==1)
mode(clusterInfo.bestSite(clusterInfo.clusterNum==4))

