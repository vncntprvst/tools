function sc_plotfeatureselection(features)

N=numel(features.name);

    
    pos=[linspace(0.8,-1,N+1)];

for i=1:N
    
    if features.featureselects(1)==i
        %plot([-1.2,-1.1],[1 1].*pos(i),'color',[.8 .8 .8],'LineWidth',10);
        fill([ -1.1 -1.2 -1.2 -1.1] ,[pos(i) pos(i) pos(i+1) pos(i+1) ]+0.03 ,'b','FaceColor',[1 1 .7]);    
    end;
    if features.featureselects(2)==i
        %plot([-1.1,-1.0],[1 1].*pos(i),'color',[.8 .8 .8],'LineWidth',10);
        fill([ -1.1 -1.2 -1.2 -1.1]+0.1 ,[pos(i) pos(i) pos(i+1) pos(i+1) ]+0.03 ,'b','FaceColor',[.8 1 1]);    
        
    end;
    
    
    text(-1.18,pos(i),features.name{i});
    
    plot([-1.32 -1],([1 1].*pos(i))+0.03,'color',[.8 .8 .8]);
    
    text(-1.25,pos(i),'x','color',[.6 .6 .6]);
    
end;
text(-1.15 ,0.9,'x','color',[1 0 0]);
text(-1.08 ,0.9,'y','color',[1 0 0]);

plot([1 1].* -1.1,[-1 1],'color',[.8 .8 .8]);

plot([1 1].* -1.2,[-1 1],'color',[.5 .5 .5]);

% delete multiple feature button

text(-1.3,0.94,'del.','color',[.6 .6 .6]);
text(-1.3,0.90,'mult.','color',[.6 .6 .6]);
    