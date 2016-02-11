%Create video object
% vidObj = VideoReader('C:\Data\Video\video_timestamped2016-01-27T19_24_38.avi'); 
vidObj = VideoReader('C:\Basler\Video\acA640-750um__21814121__20160128_201457757.avi');

%% Initialize parameters
% Determine the height and width of the frames.

vidHeight = vidObj.Height;
vidWidth = vidObj.Width;

% Create a MATLAB® movie structure array, s.

s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),...
    'colormap',[]);

% Read one frame at a time using readFrame until the end of the file is reached.
% Append data from each video frame to the structure array.

k = 1;
while hasFrame(vidObj)
    s(k).cdata = readFrame(vidObj);
    k = k+1;
end

% Display the fifth frame stored in s.

% image(s(5).cdata)

% Resize the current figure and axes based on the video's width and height.
% Then, play the movie once at the video's frame rate using the movie function.

set(gcf,'position',[150 150 vidObj.Width vidObj.Height]);
set(gca,'units','pixels');
set(gca,'position',[0 0 vidObj.Width vidObj.Height]);
movie(s,1,vidObj.FrameRate);