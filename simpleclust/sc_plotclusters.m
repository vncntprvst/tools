function    features=plotclusters(features)


plot([-1 1],[-1 -1]+0.01,'color',[1 1 .7],'LineWidth',5);
plot([-1 -1]+0.01,[-1 1],'color',[.8 1 1],'LineWidth',5);


fill([-1 1 1 -1 ],[-1 -1 1 1] ,'b','FaceColor',[0 0 0]);

%% scale
use=zeros(1,numel(features.ts));

for i=1:features.Nclusters
    if features.clustervisible(i)
        incluster=find(features.clusters==i );
        use(incluster)=1;
    end;
end;


% this is needed only when a feature was changed
if ~exist('features.updatezoom')
    features.updatezoom=1;
end;
if features.updatezoom
    features.updatezoom=0;
    
    margin=0.1;
    for i=1:2%size(features.data,1) % scale only the features we're looking at
        
        x=features.data(features.featureselects(i),:);
        
        %x=x-min(x(find(use))); x=x./max(x(find(use))); x=x*(2-margin*2); x=x-(1-margin);
        %features.data_scaled(i,:)=x;
        
        % scale to min-max
        %features.data_scaled(features.featureselects(i),:)=sc_remap (features.data(features.featureselects(i),:),min(x(find(use))),max(x(find(use))) ,-.9,.9);
        
        % scale to zoom boundaries
        features.data_scaled(features.featureselects(i),:)=sc_remap(features.data(features.featureselects(i),:), features.zoomrange(features.featureselects(i),1) , features.zoomrange(features.featureselects(i),2) ,-.9,.9);
        
        
        
    end;
    
    % hide out of bounds points
    features.zoomvisible = ( features.data(features.featureselects(1),:) <= features.zoomrange(features.featureselects(1),2) ).* ...
        ( features.data(features.featureselects(1),:) >= features.zoomrange(features.featureselects(1),1) ).* ...
        ( features.data(features.featureselects(2),:) <= features.zoomrange(features.featureselects(2),2) ).* ...
        ( features.data(features.featureselects(2),:) >= features.zoomrange(features.featureselects(2),1) );
    
    
end;

% indicate if some were cut off
% right
if min(( features.data(features.featureselects(1),:) <= features.zoomrange(features.featureselects(1),2) )) ==0
    for i=linspace(-.7 ,.7, 9)
        plot([0 0.04]+.95,i+[0 0],'color',[.5 .5 .5]);
        plot([0 -0.02]+.99,i+[0 0.01],'color',[.5 .5 .5]);
        plot([0 -0.02]+.99,i-[0 0.01],'color',[.5 .5 .5]);
    end;
end;
% left
if min(( features.data(features.featureselects(1),:) >= features.zoomrange(features.featureselects(1),1) )) ==0
    for i=linspace(-.7 ,.7, 9)
        plot([0 0.04]-.95,i+[0 0],'color',[.5 .5 .5]);
        plot([0 0.02]-.95,i+[0 0.01],'color',[.5 .5 .5]);
        plot([0 0.02]-.95,i-[0 0.01],'color',[.5 .5 .5]);
    end;
end;
% top
if min(( features.data(features.featureselects(2),:) <= features.zoomrange(features.featureselects(2),2) )) ==0
    for i=linspace(-.7 ,.7, 9)
        plot(i+[0 0],[0 0.04]+.95,'color',[.5 .5 .5]);
        plot(i+[0 0.01],[0 -0.02]+.99,'color',[.5 .5 .5]);
        plot(i-[0 0.01],[0 -0.02]+.99,'color',[.5 .5 .5]);
    end;
end;
% bottom
if min(( features.data(features.featureselects(2),:) >= features.zoomrange(features.featureselects(2),1) )) ==0
    for i=linspace(-.6 ,.7, 7)
        plot(i+[0 0],[0 0.04]-.95,'color',[.5 .5 .5]);
        plot(i+[0 0.01],[0 0.02]-.95,'color',[.5 .5 .5]);
        plot(i-[0 0.01],[0 0.02]-.95,'color',[.5 .5 .5]);
    end;
end;
%% plot

%ugly bug fix - figure out where this error comes from!
if size(features.timevisible,1)>size(features.timevisible,2)
    features.timevisible=features.timevisible';
end;
if size(features.ts,1)>size(features.ts,2)
    features.ts=features.ts';
end;



for i=1:features.Nclusters
    if features.clustervisible(i)
        
        
        
        
        incluster=find(features.clusters==i .*(features.randperm<features.Ndisplay) .* features.timevisible .* features.zoomvisible);
        if numel(incluster)>0
            sc_plotinbox(features.data_scaled(features.featureselects(1),incluster),features.data_scaled(features.featureselects(2),incluster),features.clusterfstrs{i},features.colors(i,:),features.plotsize);
        end;
        
        % plot cluster traces
        mx=[]; my=[];
        if features.timeselection
            nsteps=100;
            timebins=linspace(features.ts(1),features.ts(end),nsteps);
            for j=2:nsteps
                
                
                incluster_t=find((features.clusters==i  ).*(features.ts > timebins(j-1)).* (features.ts < timebins(j)));
                
                mx(j-1)=median(  features.data_scaled(features.featureselects(1),incluster_t)  );
                my(j-1)=median(  features.data_scaled(features.featureselects(2),incluster_t)  );
                
                
            end;
            
            f=normpdf([-4:4],0,2); f=f./sum(f);
            
            mx=conv(mx,f,'valid');
            my=conv(my,f,'valid');
            
            plot(mx,my,'r-','color',features.colors(i,:),'LineWidth',4);
            plot(mx,my,'r--','color',[1 1 1],'LineWidth',1);
            
            
        end;
    end;
    
end;

% plot x/y range
if isfield(features,'range')
    
    text(-0.95,-0.9,num2str( features.zoomrange(features.featureselects(2),1) ),'color',[.5 .5 .5]);
    text(-0.95,0.95,num2str( features.zoomrange(features.featureselects(2),2) ),'color',[.5 .5 .5]);
    
    text(-0.9,-0.95,num2str( features.zoomrange(features.featureselects(1),1) ),'color',[.5 .5 .5]);
    text(0.9,-0.95,num2str( features.zoomrange(features.featureselects(1),2) ),'color',[.5 .5 .5]);
end;


if features.highlight>0
    plot( features.data_scaled(features.featureselects(1),features.highlight),features.data_scaled(features.featureselects(2),features.highlight),'wo','MarkerSize',8);
    %plot( features.data(features.featureselects(1),features.highlight),features.data(features.featureselects(2),features.highlight),'ko','MarkerSize',9);
    
    
    if features.plotgroup
        plot( features.data_scaled(features.featureselects(1),features.highlight_multiple),features.data_scaled(features.featureselects(2),features.highlight_multiple),'wo','MarkerSize',6,'color',[.6 .6 .6]);
    end;
end;


% plot zoom button

plot([1 .9 ],[.9,1],'b','color',[1 1 1]);
xx=[]; yy=[];
for i=linspace(0,7,20)
    xx(end+1)= sin(i)*.01;
    yy(end+1)= cos(i)*.01;
end;
plot(xx+.96,yy+.98,'b','color',[.9 .9 .9],'LineWidth',2);
plot([.966 .98],[.975 .96],'b','color',[.9 .9 .9],'LineWidth',3);




