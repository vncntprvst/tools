function varargout=sc_timeline(features,mua,x,y,b)

% plot timeline things
xfrom=-1.1;
xto=3.2;

yfrom= -1.1;
yto= -1.3;


if nargout==0 % plot
    
    plot([-1.3, 3.3],[1 1].*yfrom,'k','color',[.5 .5 .5])
    
    text(-1.2,-1.13,'+');
    text(-1.2,-1.25,'-');
    
    text(-1.28,((yfrom+yto)/2),[num2str(round(features.timeselectwidth)),'s']);
    
    plot([-1.3, -1.15],[1 1].*((yfrom+yto)/2)+0.025,'k','color',[.5 .5 .5]);
    plot([-1.3, -1.15],[1 1].*((yfrom+yto)/2)-0.025,'k','color',[.5 .5 .5]);
    
    
    nbins=1000;
    ll=linspace(features.ts(1),features.ts(end),nbins);
    imrate=zeros(features.Nclusters,nbins);
    
    for c=1:features.Nclusters
        this=find(features.clusters==c);
        
        imrate(c,:)=min(histc(features.ts(this),ll),50)./50;
        
        imrate(c,:)=1-(  imrate(c,:)./max(imrate(c,:))  );
        plot(-1.12, (yto+(yfrom-yto)*c./features.Nclusters)-0.02  ,features.clusterfstrs{c},'MarkerSize',22,'color',features.colors(c,:));
        
    end;
    
    pixelcorrect=(yfrom-yto)/(features.Nclusters);% imagesc positions at center of pixels, we need to correct for that or the plot spills over  abit
    imagesc(linspace(xfrom,xto,nbins),linspace(yto+(pixelcorrect/2) ,yfrom-(pixelcorrect/2),features.Nclusters),-imrate.*1);
    
    if features.timeselection
        
        tx= ((features.selectedtime-features.ts(1))/(features.ts(end)-features.ts(1)).*(xto-xfrom))+xfrom;
        txfrom=(((features.selectedtime-features.timeselectwidth)-features.ts(1))/(features.ts(end)-features.ts(1)).*(xto-xfrom))+xfrom;
        txto=(((features.selectedtime+features.timeselectwidth)-features.ts(1))/(features.ts(end)-features.ts(1)).*(xto-xfrom))+xfrom;
        
        plot([0.01,0,0,0.01]+txfrom ,[yfrom, yfrom,yto,yto],'y-');
        plot([-0.01,0,0,-0.01]+txto ,[yfrom, yfrom,yto,yto],'y-');
        plot([-0.00,0,0,-0.00]+tx ,[yfrom, yfrom,yto,yto],'y--');
        
        
    end;
    
else %if vargout >0, parse input
    
    if y<yfrom
        
        if x<xfrom % change window size
            if y<((yfrom+yto)/2)+0.025
                
                features.timeselectwidth=features.timeselectwidth.*.55;
            end;
            
            if y> ((yfrom+yto)/2)-0.025
                
                features.timeselectwidth=features.timeselectwidth.*1.8;
            end;
            
            % update new visibility boundaries ONLY if time selectio is active
            if features.timeselection
                features.timevisible= (features.ts> features.selectedtime-features.timeselectwidth).* (features.ts < features.selectedtime+features.timeselectwidth) ; % reset time visibility
            end;
            
        else % manage timeline clicks, either move window or end time selction mode
            
            if b==1
                features.timeselection=1;
                
                features.selectedtime =  features.ts(1)+ ((features.ts(end)-features.ts(1))*((x-xfrom)/(xto-xfrom)));
                
                
                features.timevisible= (features.ts> features.selectedtime-features.timeselectwidth).* (features.ts < features.selectedtime+features.timeselectwidth) ; % reset time visibility
                
            end;
            
            if b==3
                features.timeselection=0;
                features.timevisible=ones(1,numel(features.ts)); % reset time visibility
            end;
        end;
        
        
    end;
    
    varargout={features};
end;