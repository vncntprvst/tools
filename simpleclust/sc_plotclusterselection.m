
function sc_plotclusterselection(features);


for i=1:features.Nclusters
    
    
    if features.selected==i
        %plot(-1+(0.2*(i-1)) +.14 ,1.16,'k.','MarkerSize',22);
        
        fill([ 0 -.1  -.2 -.2 -.1 -.1]-1 +((i)*0.2),[1.1 1.2 1.2 1.1 1.1 1.1] ,'b','FaceColor',[1 1 .7]);
    end;
    
    text(-1+(0.2*(i-1)) +.04 ,1.16,['[',num2str(i),']'])
    plot(-1+(0.2*(i-1)) +.02 ,1.16,features.clusterfstrs{i},'MarkerSize',16,'color',features.colors(i,:));
    
    
    text(-1+(0.2*(i-1)) +.17 ,1.17,'v')
    
    if features.clustervisible(i)
        fill([0 -.1 0]-1 +((i)*0.2),[1.1 1.2 1.2] ,'b','FaceColor',[.8 .8 .8]);
    end;
    
    
    plot([0 -.1]-1 +((i)*0.2),[1.1 1.2] ,'k');
    
    
    
    plot([0 0]-1 +((i-1)*0.2),[1 1.2],'color',[.4 .4 .4]);
    plot([0 0]-1 +((i-0)*0.2),[1 1.2],'color',[.4 .4 .4]);
    
    
    
    plot( [(i-1)*0.2,(i)*0.2]-1  ,[1.1, 1.1],'color',[.7 .7 .7]);
    
    plot( [(i-1)*0.2,(i)*0.2]-1  ,[1.05, 1.05],'color',[.7 .7 .7]); % divide add/mult buttons in half
    
    if i==1 %the null cluster functions slightly differently
        text(-1+(0.2*(i-1)) +.04 ,1.08,'+');
        text(-1+(0.2*(i-1)) +.14 ,1.06,'*^{-1}');
        text(-1+(0.2*(i-1)) +.04 ,1.02,'++');
        text(-1+(0.2*(i-1)) +.14 ,1.02,'-');
        
    else
        text(-1+(0.2*(i-1)) +.04 ,1.08,'+');
        text(-1+(0.2*(i-1)) +.14 ,1.06,'*');
        text(-1+(0.2*(i-1)) +.04 ,1.02,'++');
        text(-1+(0.2*(i-1)) +.14 ,1.02,'-');
    end;
    
    plot([1 1].*-1+(0.2*(i-1)) +.1,[1 1.1],'color',[.7 .7 .7]);
    
end;

plot([0 0.15]-1+(0.2*(i)) +.02,[1 1].*1.1,'k','LineWidth',15,'color',.85.*[1 1 1]);
plot([0.075 0.075]-1+(0.2*(i)) +.02,[0 0.15]+1.02,'k','LineWidth',15,'color',.85.*[1 1 1]);


text(-1+(0.2*(i)) +.1,1.04,'+new');
plot([0 0]-1 +((i+1)*0.2),[1 1.2],'color',[.7 .7 .7]);

text(-1+(0.2*(i)) +.3,1.16,'Simple Clust v0.5     ','FontWeight','bold');
text(-1+(0.2*(i)) +.65,1.16,'jvoigts@mit.edu ');

text(-1+(0.2*(i)) +.3,1.09,features.muafilepath,'Interpreter','none');
text(-1+(0.2*(i)) +.3,1.06,features.muafile_justfile,'Interpreter','none','color',[.0 .0 .0],'FontWeight','bold');

