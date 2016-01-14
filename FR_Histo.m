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
    if ~iscell(fname)
        fname={fname};
    end
    for fl=1:size(fname,2)
        Data{fl}=load(fname{fl});
        if size(Data{fl}.Spikes.channel,2)>1 & fl==1
            str= num2str([Data{fl}.Spikes.channel{:}]');
            ChNum= listdlg('PromptString','select channel to plot:','ListString',str);
        end
        spikeTimeIdx{fl}=zeros(1,size(Data{fl}.Spikes.downSampled{ChNum},2));
        spikeTimeIdx{fl}(logical(Data{fl}.Spikes.downSampled{ChNum}))=1;
        spikeTimes{fl}=find(Data{fl}.Spikes.downSampled{ChNum});
        SampleRes{fl}=1000; %Data{fl}.Spikes.samplingRate(2);
    end
end

%% bin into 1 second bins and plot
conditions={'Baseline','Female Interaction','Single again'};
figure('position',[12,589,1150,406]);
for plotN=1:size(Data,2)
    binSize=1000;
    numBin=ceil(size(spikeTimeIdx{plotN},2)/(SampleRes{plotN}/1000)/binSize);
    % binspikeTime = histogram(double(spikeTimes{plot}), numBin); %plots directly histogram
    [binspikeTime,binspikeTimeEdges] = histcounts(double(spikeTimes{plotN}), numBin);
    
    ploth(plotN)=subplot(1,size(Data,2)*2-1,max([(plotN-1)*2 1]):max([(plotN-1)*2 1])+(plotN>1));
    bar(binspikeTimeEdges(1:end-1)+round(mean(diff(binspikeTimeEdges))/2),binspikeTime,'hist');
    set(gca,'xtick',linspace(0,round(numBin*binSize/10000)*10000,round(numBin*binSize/10000)),...
        'xticklabel',round(linspace(0,round(numBin*binSize/10000)*10,round(numBin*binSize/10000))),'TickDir','out');
    axis('tight');box off;
    xlabel('Time (sec.)')
    if plotN==1
        ylabel(['Channel ' num2str(Data{fl}.Spikes.channel{ChNum}) ' Firing rate (Hz)'])
    end
    set(gca,'Color','white','FontSize',14,'FontName','calibri');
    title(conditions{plotN});
    %% compare with spike density function (sigma=20)
% sigma=1000;
% convspikeTime = fullgauss_filtconv(spikeTimeIdx{plot},sigma,0).*1000;
% hold on 
% plot([zeros(1,sigma*3) convspikeTime zeros(1,sigma*3)])
end
    % get max y lim
    maxYLim=round(max(max(cell2mat(get(ploth,'ylim'))))/10)*10;
    set(ploth,'ylim',[0 maxYLim]);
    

