%Create video object

% fileName='PrV77_52_HSCam2016-03-17T19_08_11'; 
[fileName,dirName] = uigetfile({'*.avi','AVI files';'*.*','All Files' },...
    'Video files','C:\Data\Video');
videoInput = VideoReader([dirName fileName]);

%% Initialize parameters
% Create a movie structure array, s.
vidStruc = struct('cdata',zeros(videoInput.Height,videoInput.Width,3,'uint8'),'colormap',[]);

% set initial time
videoInput.CurrentTime = (13*60)+34; %13:34

% Read one frame at a time using readFrame until the end of 3 sec epoch.
% Append data from each video frame to the structure array.
clipDuration=2;
k = 1;
while k<=(clipDuration*videoInput.FrameRate)
    vidStruc(k).cdata = readFrame(videoInput);
    k = k+1;
end

% Display the last frame stored in vidStruc

% image(vidStruc(end).cdata)

% Size the current figure and axes based on the video's width and height.
whiskingEpochh = figure;
set(whiskingEpochh,'position',[150 150 videoInput.Width videoInput.Height]);
set(gca,'units','pixels');
set(gca,'position',[0 0 videoInput.Width videoInput.Height]);

% Play the movie once at the video's frame rate
movie(vidStruc,1,videoInput.FrameRate);

%% Save movie
videoOutput = VideoWriter([fileName '_Trial_X.avi']);
videoOutput.FrameRate=videoInput.FrameRate  ;
open(videoOutput);

% add frames
set(0,'DefaultAxesColor','black')
figure('Color','black','Visible', 'off');
for framNum=1:videoInput.FrameRate*clipDuration
  image(vidStruc(int16(framNum)).cdata);
  vFrame=getframe;
  writeVideo(videoOutput,vFrame);
end