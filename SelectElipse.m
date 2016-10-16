rng default; 

% 3d plot
% rndData = [randn(100,3)*0.75+ones(100,3);
%     randn(100,3)*0.5-ones(100,3)];
% 
% figure;
% plotH=scatter3(rndData(:,1),rndData(:,2),rndData(:,3),'.'); hold on
% title 'Random Data';

rndData = [randn(100,2)*0.75+ones(100,2);
    randn(100,2)*0.5-ones(100,2)];

figure;
plotH=scatter(rndData(:,1),rndData(:,2),'.'); hold on
title 'Random Data';

ellipseSelectionH = imellipse;

selectPos=ellipseSelectionH.getPosition;

selectIdx=rndData(:,1)>=selectPos(1) & rndData(:,1)<=(selectPos(1)+selectPos(3)) &...
rndData(:,2)>=selectPos(2) & rndData(:,2)<=(selectPos(2)+selectPos(4));

scatter(rndData(selectIdx,1),rndData(selectIdx,2),'r.');

% better indexing with meshgrid (but circular selection)
[rr, cc] = meshgrid(min(rndData(:,1)):max(rndData(:,1)),...
    min(rndData(:,2)):max(rndData(:,2)));
selectionIdx = sqrt((rr-selectPos(1)+selectPos(3)/2).^2+(cc-selectPos(2)+selectPos(4)/2).^2)<=...
    min([selectPos(3) selectPos(4)]);
 