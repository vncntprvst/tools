%% load data file
% [fname,dname] = uigetfile({'*.nev','NEV Data Format';...
%     '*.*','All Files' },'Data folder','C:\Data');
[fname,dname] = uigetfile({'*.*','All Files' },'Data folder','C:\Data\export',...
            'MultiSelect','on');
if iscell(fname)
    fileFormat=fname{1}(end-3:end);
else
    fileFormat=fname(end-3:end);
end
if strfind(fileFormat,'nev')
    Data=openNEV('read', [dname '\' fname]);
    
    %% select unit to plot
str= num2str(linspace(1,double(max(Data.Data.Spikes.Unit)),max(Data.Data.Spikes.Unit))');
unitSelected = listdlg('PromptString','select unit to plot:',...
                'SelectionMode','single',...
                'ListString',str);
            
    %% get spike times and change it to binary array
logicalUnitSelected=Data.Data.Spikes.Unit==unitSelected;
spikeTimes=Data.Data.Spikes.TimeStamp(logicalUnitSelected);
spikeTimeIdx=zeros(1,max(Data.Data.Spikes.TimeStamp));
spikeTimeIdx(spikeTimes)=1;

SampleRes=Data.MetaTags.SampleRes;

else
    for fl=1:size(fname,2)
        Data{fl}=load(fname{fl});
        spikeTimeIdx{fl}=zeros(1,size(Data{fl}.Spikes.downSampled,2));
        spikeTimeIdx{fl}(logical(Data{fl}.Spikes.downSampled))=1;
        spikeTimes{fl}=find(Data{fl}.Spikes.downSampled);
        SampleRes{fl}=1000; %Data{fl}.Spikes.samplingRate;
    end
end

%% bin into 1 second bins and plot
figure;
for plot=1:size(Data,2)
    binSize=1000;
    numBin=ceil(size(spikeTimeIdx{plot},2)/(SampleRes{plot}/1000)/binSize);
    % binspikeTime = histogram(double(spikeTimes{plot}), numBin); %plots directly histogram
    [binspikeTime,binspikeTimeEdges] = histcounts(double(spikeTimes{plot}), numBin);
    
    subplot(1,size(Data,2)+1,plot:(2*plot)-1)
    bar(binspikeTimeEdges(1:end-1)+round(mean(diff(binspikeTimeEdges))/2),binspikeTime,'hist');
    set(gca,'xtick',linspace(0,round(numBin*binSize/10000)*10000,round(numBin*binSize/10000)),...
        'xticklabel',round(linspace(0,round(numBin*binSize/10000)*10,round(numBin*binSize/10000))),'TickDir','out');
    axis('tight');box off;
    xlabel('Time (sec.)')
    ylabel('Firing rate (Hz)')
    set(gca,'Color','white','FontSize',14,'FontName','calibri');
    
    %% compare with spike density function (sigma=20)
% sigma=1000;
% convspikeTime = fullgauss_filtconv(spikeTimeIdx{plot},sigma,0).*1000;
% hold on 
% plot([zeros(1,sigma*3) convspikeTime zeros(1,sigma*3)])

end

