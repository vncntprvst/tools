function features = sc_parse_feature_selection(x,y,features)

N=numel(features.name);

pos=[linspace(0.8,-1,N+1)];

if  (x<-1) && ( y<1) && (x>-1.2)
    
    for i=1:N
        % plot([-1.2 -1],([1 1].*pos(i))+0.03,'color',[.8 .8 .8]);
        
        if  (y<(pos(i)+0.03)) && (y>(pos(i+1)+0.03))  %abs(pos(i)-y)<0.03
            
            if x<-1.1
                features.featureselects(1)=i;
                %      disp(['set X to feature ',features.name{i}]);
            else
                features.featureselects(2)=i;
                %     disp(['set Y to feature ',features.name{i}]);
            end;
            
        end;
    end;
    
end;

if  (x<-1) && ( y<0.82) && (x<-1.2) % remove feature
    for i=1:N
        if  (y<(pos(i)+0.03)) && (y>(pos(i+1)+0.03))  %abs(pos(i)-y)<0.03
            
            button = questdlg(['Remove feature ',features.name{i}],'delete feature?','Yes','No','Yes');
            
            if strcmp(button,'Yes')
                % remove feature
                features.data(i,:)=[];
                tmp=features.name;
                features.name={};
                c=0;
                for j=1:N-1
                    c=c+1;
                    if j==i
                        c=c+1;
                    end;
                    features.name{j}=tmp{c};
                end;
                
                % also make sure no removed feature is still selected
                features.featureselects(features.featureselects==i)=1;
                
                if features.featureselects(1)>size(features.data,1)
                    features.featureselects(1)=size(features.data,1);
                end;
                if features.featureselects(2)>size(features.data,1)
                    features.featureselects(2)=size(features.data,1);
                end;
            end;
        end;
    end;
end;

% remove multiple features
if  (x<-1) && ( y>.82) && (x<-1.2) % remove feature
    button = questdlg(['Remove multiple features '],'delete features?','Yes','No','Yes');
    if strcmp(button,'Yes')
        
        
    
        text(-.5,0,'click on 1st feature to delete', 'BackgroundColor',[.7 .9 .7]);
        [x,y,b] = sc_ginput(1);
        for i=1:N
            if  (y<(pos(i)+0.03)) && (y>(pos(i+1)+0.03))  %abs(pos(i)-y)<0.03
                del_mult_from=i;
                plot([-1.2 -1],[.03 .03]+pos(i),'r','LineWidth',2);
                plot([-1.2 -1],[.03 .03]+pos(i)-.01,'r--','LineWidth',1);
                plot([-1.2 -1],[.03 .03]+pos(i)-.02,'r--','LineWidth',1);
            end;
        end;
        text(-.5,0,'click on last feature to delete', 'BackgroundColor',[.7 .9 .7]); drawnow;
                [x,y,b] = sc_ginput(1);
        for i=1:N
            if  (y<(pos(i)+0.03)) && (y>(pos(i+1)+0.03))  %abs(pos(i)-y)<0.03
                plot([-1.2 -1],[.03 .03]+pos(i+1)+.01,'r--','LineWidth',1);
                plot([-1.2 -1],[.03 .03]+pos(i+1)+.02,'r--','LineWidth',1);
                del_mult_to=i; plot([-1.2 -1],[.03 .03]+pos(i+1),'r','LineWidth',2); drawnow;
            end;
        end;
        
        
        %delete the features
        i=del_mult_from;
        for k=del_mult_from:del_mult_to
            features.data(i,:)=[];
            
            N=numel(features.name);
            tmp=features.name;
            features.name={};
            c=0;
            for j=1:N-1
                c=c+1;
                if j==i
                    c=c+1;
                end;
                features.name{j}=tmp{c};
            end;
            
            % also make sure no removed feature is still selected
            features.featureselects(features.featureselects==i)=1;
            
            if features.featureselects(1)>size(features.data,1)
                features.featureselects(1)=size(features.data,1);
            end;
            if features.featureselects(2)>size(features.data,1)
                features.featureselects(2)=size(features.data,1);
            end;
                        end;
    end;
end;
