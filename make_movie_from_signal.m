%% get data
fileName='example';

% reading actual video:
% vidObj = VideoReader([fileName '.avi']); 

% reading from file 
% load([fileName '.mat'])

% generating example data: chirp
samplingRate=1000;
Time = 0:1/samplingRate:2;
data = chirp(Time,100,1,200,'q');
figure;
spectrogram(data,128,120,128,1E3,'yaxis')
title('Quadratic chirp')

%% Create video object and Initialize parameters
vidObj = VideoWriter([fileName '.avi']);
vidObj.FrameRate=25;
open(vidObj);

%% add frames
set(0,'DefaultAxesColor','black')
figure('Color','black','Visible', 'off');
for framNum=1:vidObj.FrameRate*10 %10 secondes
  %add an image to the movie:
%   f = im2frame(Img);
%   writeVideo(aviobj,f);

  %Or plot vector, then Add to Movie:
  plot(data((samplingRate/vidObj.FrameRate)*(framNum-1)+1:(samplingRate/vidObj.FrameRate)*(framNum)+1)); 
  ylim([min(data(1:samplingRate*10+1)) max(data(1:samplingRate*10+1))]);
%   axis('tight');box off;
  f = getframe;
  writeVideo(vidObj,f);
end

%% close movie
close(vidObj);

