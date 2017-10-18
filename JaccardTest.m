% JaccardTest.m
% Compute the Jaccard similarity coefficient (index) of two images. 
% Also how to find the Jaccard distance.
%
% Kawahara (2013).
 
% A value of "1" = the line object (foreground).
% A value of "0" = the background.
 
% Alice draws a vertical line.
Alice = [0 1 0; 
         0 1 0; 
         0 1 0];
 
% RobotBob tries to draw a line.     
RobotBob = [0 0 0;
            0 1 1;
            0 0 1];
 
% Carol tries to draw a line.
Carol = [0 1 0; 
         0 1 0; 
         1 1 0;];
 
% Let's see their two drawings.
figure; 
subplot(1,3,1); imagesc(Alice); axis image; colormap gray; 
title('Alice''s nice line drawing');
 
subplot(1,3,2); imagesc(RobotBob); axis image; colormap gray; 
title('RobotBob tries to draw Alice''s line'); 
 
subplot(1,3,3); imagesc(Carol); axis image; colormap gray; 
title('Carol''s tries to draw Alice''s line'); 
 
% How similar are Alice's and Bob's drawing of a line? 
% An intuitive way to measure this is to compare each of the white "line" 
% pixels (a value of "1") to each other and see how many white pixels 
% overlap compared to the total number of white line pixels.
 
% We compute the intersection of the two lines using the "AND" operator "&".
intersectImg = Alice & RobotBob; 
figure; imagesc(intersectImg); axis image; colormap gray; title('intersection');
 
% We compute the union of the two lines using the "OR" operator "|".
unionImg = Alice | RobotBob;
figure; imagesc(unionImg); axis image; colormap gray; title('union');
 
% There is only one pixel that overlaps (intersects) 
numerator = sum(intersectImg(:));
 
% There are 5 pixels that are unioned.
denomenator = sum(unionImg(:));
 
% So intuitively we might expect that a similarity of 1/5 would 
% be a good indication. This is exactly what Jaccard's does.
 
jaccardIndex = numerator/denomenator
% jaccardIndex =
%     0.2000
 
% Jaccard distance shows how dis-similar the two line drawings are.
jaccardDistance = 1 - jaccardIndex
% jaccardDistance =
%     0.8000
 
%% How simililar are Alice and Carol's two line drawings?
 
% We can compute Jaccard's index in a single line,
jaccardIndex_ac = sum(Alice(:) & Carol(:)) / sum(Alice(:) | Carol(:))
%jaccardIndex_ac =
%     0.7500
%
% As expected, we can see that Alice's and Carol's drawing of a line is
% much MORE "similar" than Alice's and Bob's drawing (0.2).
 
% Let's check the Jaccard distance.
jaccardDistance_ac = 1 - jaccardIndex_ac
% jaccardDistance_ac =
%    0.2500
%
% As expected, we can see there is LESS "distance" between Alice's and
% Carol's drawing of a line than Alice's and Bob's drawing of a line (0.8).