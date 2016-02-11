%Create video object
% reading actual video:
% vidObj = VideoReader('C:\Data\Video\video_timestamped2016-01-27T19_24_38.avi'); 
% vidObj = VideoReader('C:\Basler\Video\acA640-750um__21814121__20160128_201457757.avi');
fileName='PrV77_32__2016_01_30_02_09_00_OEph_CAR';
load([fileName '.mat'])


%% Initialize parameters
vidObj = VideoWriter([fileName '.avi']);
vidObj.FrameRate=20;
open(vidObj);
data=Spikes.downSampled;

%% add frames
set(0,'DefaultAxesColor','black')
figure('Color','black','Visible', 'off');
for framNum=1:vidObj.FrameRate*10 %10 secondes
  %add an image to the movie:
%   f = im2frame(Img);
%   writeVideo(aviobj,f);

  %Or plot vector, then Add to Movie:
  plot(data(ChN,(Spikes.samplingRate(2)/25)*(framNum-1)+1:(Spikes.samplingRate(2)/25)*(framNum)+1)); 
  ylim([min(data(ChN,1:Spikes.samplingRate(2)*10+1)) max(data(ChN,1:Spikes.samplingRate(2)*10+1))]);
%   axis('tight');box off;
  f = getframe;
  writeVideo(vidObj,f);
end

%% close movie
close(vidObj);

