function  [px,py] =getpolygon(features,plotcolor);


%manual polygon draw
%{
px=[];
py=[];

[x,y,b] = sc_ginput(1);

px(end+1)=x;
py(end+1)=y;

while b~=3
    
    [x,y,b] = sc_ginput(1);
    plot( [px(end),x],[py(end),y] ,'color',plotcolor);
    
    px(end+1)=x;
    py(end+1)=y;
end;

%}

%better: draw freehand outline

        t= imfreehand(gca,'Closed' ,1);
        t.setClosed(1);
         r=t.getPosition;

        px=r(:,1);py=r(:,2);
        
% remap from screen space to feature space


px=sc_remap(px,-.9, .9, features.zoomrange(features.featureselects(1),1),features.zoomrange(features.featureselects(1),2) );
py=sc_remap(py,-.9, .9, features.zoomrange(features.featureselects(2),1),features.zoomrange(features.featureselects(2),2) );