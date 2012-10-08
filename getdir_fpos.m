function [dir]=getdir_fpos(datalg,dirnb)
%retrieve direction from eye position in dataaligned files

    sacdeg=nan(size(datalg(1,dirnb).trials,2),1);
    for eyetr=1:size(datalg(1,dirnb).trials,2)
    thissach=datalg(1,dirnb).eyeh(eyetr,datalg(1,dirnb).alignidx:datalg(1,dirnb).alignidx+100);
    thissacv=datalg(1,dirnb).eyev(eyetr,datalg(1,dirnb).alignidx:datalg(1,dirnb).alignidx+100);
    minwidth=5;
    [~, ~, thissacvel, ~, ~, ~] = cal_velacc(thissach,thissacv,minwidth);
    peakvel=find(thissacvel==max(thissacvel),1);
    sacendtime=peakvel+find(thissacvel(peakvel:end)<=...
        (min(thissacvel(peakvel:end))+(max(thissacvel(peakvel:end))-min(thissacvel(peakvel:end)))/10),1);
    try
    sacdeg(eyetr)=abs(atand((thissach(sacendtime)-thissach(1))/(thissacv(sacendtime)-thissacv(1))));
    catch
        thissacv;
    end

    % sign adjustements
    if thissacv(sacendtime)<thissacv(1) % negative vertical amplitude -> vertical flip
    	sacdeg(eyetr)=180-sacdeg(eyetr);
    end
    if thissach(sacendtime)>thissach(1)%inverted signal: leftward is in postive range. Correcting to negative. 
        sacdeg(eyetr)=360-sacdeg(eyetr); % mirror image;
    end
    end
    % a quick fix to be able to put "upwards" directions together
    distrib=hist(sacdeg,3); %floor(length(sacdeg)/2)
    if max(bwlabel(distrib,4))>1 && distrib(1)>1 && distrib(end)>1 %=bimodal distribution with more than 1 outlier
    sacdeg=sacdeg+45;
    sacdeg(sacdeg>360)=-(360-(sacdeg(sacdeg>360)-45));
    sacdeg(sacdeg>0)= sacdeg(sacdeg>0)-45;
    end
    sacdeg=abs(median(sacdeg));
    
    if sacdeg>45/2 && sacdeg <= 45+45/2
        dir='up_right';
    elseif sacdeg>45+45/2 && sacdeg <= 90+45/2
        dir='rightward';
    elseif sacdeg>90+45/2 && sacdeg <= 135+45/2
        dir='down_right';
    elseif sacdeg>135+45/2 && sacdeg < 180+45/2
        dir='downward';
    elseif sacdeg>=180+45/2 && sacdeg <= 225+45/2
        dir='down_left';
    elseif sacdeg>225+45/2 && sacdeg <= 270+45/2
        dir='leftward';
    elseif sacdeg>270+45/2 && sacdeg <= 315+45/2
        dir='up_left';
    else
        dir='upward';
    end