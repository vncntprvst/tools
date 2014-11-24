function features=parse_custerselection(features,x,y,mua,s_opt)


selected_cluster=0;
action=0;
features.last_op_was_from_any=0;

if (x>-1) && (y> 1)
    
    
    for i=1:features.Nclusters
        features.editedcluster=i;
        
        
        
        if (x>-1 +((i-1)*0.2)) && (x<-1 +((i-0)*0.2))
            %   disp(['hit ',num2str(i)])
            
            if y>1.1
                
                
                if ((x-((i-1)*0.2))+y) >.3; % toggle visibility
                    features.clustervisible(i)=1-features.clustervisible(i);
                    
                else
                    %disp('select');
                    
                    % plot ISI and some extra options for this cluster
                    %plot_cluster_info(features,i);
                    features.selected=i;
                    
                end;
                
            else
                %  disp('act');
                
                if x < ( (-1 +((i-1)*0.2)) +(-1 +((i-0)*0.2)) )/2
                    
                    if y >  1.05 % +
                        
                        text(-1+(0.2*(i-1)) +.04 ,1.08,'+','color',[1 0 0]);
                        features.editedcluster=i;
                        features=sc_add_to_cluster(features,i,s_opt);
                        
                    else
                        %    disp('++');
                        
                        text(-1+(0.2*(i-1)) +.04 ,1.02,'++','color',[1 0 0]);
                        
                        features.last_op_was_from_any=1; % need to update ALL clusterimages now
                        features.editedcluster=i;
                        features=sc_add_to_cluster_from_any(features,i,s_opt);
                    end;
                    
                else
                    
                    if y >  1.05 % *
                        text(-1+(0.2*(i-1)) +.14 ,1.06,'*','color',[1 0 0]);
                        features.editedcluster=i;
                        features=sc_intersect_cluster(features,i,s_opt);
                    else
                        % disp('-');
                        
                        text(-1+(0.2*(i-1)) +.14 ,1.02,'-','color',[1 0 0]);
                        features.editedcluster=i;
                        features=sc_remove_from_cluster(features,i,s_opt);
                    end;
                end;
                
            end;
            
            
        end;
        
    end;
    
    if (x>-1 +((i)*0.2)) && (x<-1 +((i+1)*0.2))
        disp('ADD');
        features.Nclusters=features.Nclusters+1;
        
        plot([0 0.15]-1+(0.2*(i)) +.02,[1 1].*1.1,'k','LineWidth',15,'color',.70.*[1 1 1]);
        plot([0.075 0.075]-1+(0.2*(i)) +.02,[0 0.15]+1.02,'k','LineWidth',15,'color',.70.*[1 1 1]);
        
        
        text(-1+(0.2*(i)) +.1,1.04,'+new','color',[1 0 0])
        drawnow;
        features.editedcluster=i+1;
        features=sc_add_to_cluster(features,features.Nclusters,s_opt);
        
        % features=updateclusterimages(features,mua);
    end;
    
    
    features=sc_updateclusterimages(features,mua,s_opt);
end;




