% to compile into a standalone Figure viewer, run:
% mcc -m -v FigViewer.m

[fileName,dirPath] = uigetfile('*.fig','Select a figure (.fig) file');
if any(fileName)
    openfig(fullfile(dirPath,fileName));
end
    