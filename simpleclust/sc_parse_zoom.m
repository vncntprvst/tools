function features=sc_parse_zoom(b,x,y,features);



if (x<1) &&( y<1) && (x+y >  1.8)
    
    
xx=[]; yy=[];
for i=linspace(0,7,20)
    xx(end+1)= sin(i)*.01;
    yy(end+1)= cos(i)*.01;
end;
plot(xx+.96,yy+.98,'b','color',[.9 .2 .2],'LineWidth',2);
plot([.966 .98],[.975 .96],'b','color',[.9 .2 .2],'LineWidth',3);


drawnow;

    if b==3
        features.zoomrange=features.range;
        features.updatezoom=1;
    end;
    
    if b==1;
        [ya,xa,b] = ginput(1);
        
       
        plot([-1 1],xa+[0 0 ],'b','color',[1 1 1]);
        plot(ya+[0 0 ],[-1 1],'b','color',[1 1 1]);
        drawnow;
        
        
        [yb,xb,b] = ginput(1);
        %  plot( [px(end),x],[py(end),y] ,'color',plotcolor);
        
        
        
        
        
        xs=sc_remap([xa xb],-.9, .9, features.zoomrange(features.featureselects(2),1),features.zoomrange(features.featureselects(2),2) );
        ys=sc_remap([ya yb],-.9, .9, features.zoomrange(features.featureselects(1),1),features.zoomrange(features.featureselects(1),2) );
        
        features.zoomrange(features.featureselects(2),1)= min(xs);
        features.zoomrange(features.featureselects(2),2)= max(xs);
        
        features.zoomrange(features.featureselects(1),1)= min(ys);
        features.zoomrange(features.featureselects(1),2)= max(ys);
        
        features.updatezoom=1;
    end;
end;