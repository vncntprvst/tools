SHdir='B:\data\Recordings\Rigel\SHrec\';
fullrecdata=daqread([SHdir 'R154L1A0_12600.daq'],'Channels',1);
figure
plot(fullrecdata)
set(gca,'TickDir','out')
box off
set(gca,'FontSize',12)
set(gca,'Xtick',[0:400000:floor(length(fullrecdata)/400000)*400000]) %sampling rate: 40000.
set(gca,'Xticklabel',[0:10:floor(length(fullrecdata)/400000)*10]) % every 10sec
set(gca,'xlim',[0 length(fullrecdata)])
set(get(gca,'XLabel'),'string','Time (sec)')
set(get(gca,'YLabel'),'string','Voltage')
title('Granule cell layer recording')


exerpt=[400000:420000];%
plot(fullrecdata(exerpt))
set(gca,'TickDir','out')
box off
%set(gca,'Color','none')
set(gca,'FontSize',12)
set(gca,'Xtick',[0:4000:floor(length(exerpt)/4000)*4000]) %sampling rate: 40000.
set(gca,'Xticklabel',[0:100:floor(length(exerpt)/4000)*100]) % every 10msec
set(gca,'xlim',[0 length(exerpt)])
set(get(gca,'XLabel'),'string','Time (ms)')
set(get(gca,'YLabel'),'string','Voltage')
title('Granule cell layer recording (500ms)')