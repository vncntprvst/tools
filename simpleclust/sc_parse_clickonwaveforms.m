function features= parse_clickonwaveforms(x,y,features,mua,s_opt)


psize=0.65;
xpos=[0 0 0 1 1 1 2 2 2];
ypos=[1 2 3 1 2 3 1 2 3];

labelpos=[linspace(0, psize-.3,5),linspace(0, psize-.3,10) ,linspace(0, psize-.3,10) ; zeros(1,5),ones(1,10).*.2,ones(1,10).*.3];

for i=1:features.Nclusters
    xo=(xpos(i)*(psize+.01))+.05;
    yo=-(ypos(i)*(psize+.01))+1;
    
    
    
    if (x> 1+xo) && (x<1+xo+psize) && (y>yo) && (y<psize+yo) % find waveform display that click is in
        
        %  plot( [1 1.1]+xo , [psize-0.1 psize]+yo,'k');
        %disp(((x-xo)-(y-yo)));
        if ((x-xo)-(y-yo))<0.5 % click on label button
            
            
            % better: do it in one click
            
            % fill([1+xo+psize 1+xo 1+xo 1+xo+psize],[ yo yo yo+psize yo+psize],'c','facecolor',[.9 .9 .9]); % draw a box
            
            
            % better: draw whitened out spike so user can still see it
            im=-((features.clusterimages(:,:,i)./max(max(features.clusterimages(:,:,i))) ).^(.6));
            
            imagesc( linspace(1,1+psize,features.imagesize)+xo , linspace(0,psize,features.imagesize)+yo , im/2 );
            
            
            text(xo+1.01,yo+0.02,num2str(i),'color',[0 0 0]);
            plot(xo+1.06,yo+0.03,features.clusterfstrs{i},'MarkerSize',22,'color',features.colors(i,:));
            
            for j=1:features.nlabels
                if features.clusterlabels(i)==j
                    text(labelpos(2,j)+xo+1.03,labelpos(1,j)+yo+.15,features.labelcategories{j},'color',[0 0 0],'BackgroundColor',[.7 .9 .7]);
                else
                    text(labelpos(2,j)+xo+1.03,labelpos(1,j)+yo+.15,features.labelcategories{j},'color',[0 0 0]);
                end;
                
                %just click on nearest, not pretty but easy
                lx(j)=labelpos(2,j)+xo+1.06;
                ly(j)=labelpos(1,j)+yo+.15;
                
            end;
            c=features.colors(i,:);
            plot( [1 1]+xo , [0 psize]+yo,'k','color',c);
            plot( [1+psize 1+psize]+xo , [0 psize]+yo,'k','color',c);
            plot( [1 1+psize]+xo , [0 0]+yo,'k','color',c);
            plot( [1 1+psize]+xo , [psize psize]+yo,'k','color',c);
            
            if i==1
                text(xo+1.1 ,yo+0.02,['N: ',num2str(sum(features.clusters==i)),' (MUA/null cluster)'],'color',[0 0 0]);
            else
                text(xo+1.1 ,yo+0.02,['N: ',num2str(sum(features.clusters==i)),' ',features.labelcategories{features.clusterlabels(i)}],'color',[0 0 0]);
            end;
            
            text(labelpos(2,1)+xo+1.03,labelpos(1,1)+yo+.15,'none','color',[.4 .4 .4]);
            
            [ix iy ib]=ginput(1);
            
            if ib==1 % only left clicks, right cancels
                d=(ix-lx).^2 +(iy-ly).^2;
                [ignore,m]=min(d);
                features.clusterlabels(i)=m;
            end;
            
        elseif ((x-xo)+(y-yo))>2.2 % click on +/options button
            
            im=-((features.clusterimages(:,:,i)./max(max(features.clusterimages(:,:,i))) ).^(.6));
            imagesc( linspace(1,1+psize,features.imagesize)+xo , linspace(0,psize,features.imagesize)+yo , im/2 );
            
            text(xo+1.01,yo+0.02,num2str(i),'color',[0 0 0]);
            plot(xo+1.06,yo+0.03,features.clusterfstrs{i},'MarkerSize',22,'color',features.colors(i,:));
            
            c=features.colors(i,:);
            plot( [1 1]+xo , [0 psize]+yo,'k','color',c);
            plot( [1+psize 1+psize]+xo , [0 psize]+yo,'k','color',c);
            plot( [1 1+psize]+xo , [0 0]+yo,'k','color',c);
            plot( [1 1+psize]+xo , [psize psize]+yo,'k','color',c);
            
            if i==1
                text(xo+1.1 ,yo+0.02,['N: ',num2str(sum(features.clusters==i)),' (MUA/null cluster)'],'color',[0 0 0]);
            else
                text(xo+1.1 ,yo+0.02,['N: ',num2str(sum(features.clusters==i)),' ',features.labelcategories{features.clusterlabels(i)}],'color',[0 0 0]);
            end;
            
            % plot options
            
            optlabels={'move cluster to noise', '[add P_{in cluster} feature]', 'add regression feature','merge with cluster'};
            for j=1:numel(optlabels)
                text(labelpos(2,j)+xo+1.03,labelpos(1,j)+yo+.15,optlabels{j},'color',[0 0 0],'BackgroundColor',[.9 .9 .9]);
                %just click on nearest, not pretty but easy
                lx(j)=labelpos(2,j)+xo+1.06;
                ly(j)=labelpos(1,j)+yo+.15;
                
            end;
            
            [ix iy ib]=ginput(1);
            
            d=(ix-lx).^2 +(iy-ly).^2;
            [ignore,m]=min(d);
            
            if ib==1
                if m==1 % move tcluster to noise
                    
                    incluster=find(features.clusters==i );
                    features.clusters_undo=features.clusters;
                    features.clusters(incluster)=2;
                    features=sc_updateclusterimages(features,mua,s_opt);
                    
                end;
                
                if m==2 % add feature based on likelihood of any spikewaveform to be in cluster based on waveform dist.
                    
                    %{
                figure(4); clf; % debug
                imagesc(-features.clusterimages(:,:,3)); hold on;
                plot(round((features.waveforms_hi(find(1),:).*features.waveformscale*features.imagesize)+(features.imagesize/2)));
                    %}
                    P_in=zeros(size(mua.ts));
                    P_this=features.clusterimages(:,:,i)./sum(sum(features.clusterimages(:,:,i))); % we dont really care about correct normalization here
                    excl=[1:features.Nclusters]; excl(i)=[];
                    P_all=mean(features.clusterimages(:,:,excl),3)./sum(sum(mean(features.clusterimages(:,:,excl),3))); % we dont really care about correct normalization here
                    parfor s=1:numel(features.ts)
                        yc=round((features.waveforms_hi(s,:).*features.waveformscale*features.imagesize)+(features.imagesize/2));
                        yc=min(max(yc,1),features.imagesize);
                        iii=sub2ind(size(P_this),yc,[1:features.imagesize]);
                        P_in(s)=(sum(P_this(iii)./max(P_all(iii),0.0001) )); % P of this spike to be from this cluster
                        
                        if mod(s,1000)==0
                            text(0,0,['making P_{in cluster} feature, (',num2str(round( 100*(s/numel(features.ts)) )),'%)'],'color',[0 0 0],'BackgroundColor',[.9 .9 .9]);
                            drawnow;
                        end;
                        
                    end;
                    
                    features.data(end+1,:)= P_in';
                    
                    features.name{size(features.data,1)}=['P_{in ',num2str(i),'}'];
                    
                    features=sc_scale_features(features);
                end;
                
                if m==3 % add feature based on regression on waveforms
                    
                    visible = find(ismember(features.clusters, find(features.clustervisible)));
                    
                    Nmaxregress=100000;
                    while numel(visible)>Nmaxregress
                        visible=visible(1:2:end);
                    end;
                    
                    visible=logical(visible);
                    
                    
                    fy=(features.clusters(visible)'==i); % only run on visible ones
                    b=regress(fy,mua.waveforms(visible,:)); 
                    feat=mua.waveforms*b;  % do prediction on all, why not
                    
                    
                    features.data(end+1,:)= feat';
                    
                    features.name{size(features.data,1)}=['regr_{in ',num2str(i),'}'];
                    
                    %features=sc_scale_features(features);
                    
                    % select that feature
                    features.featureselects(2)=size(features.data,1);
                    
                    features=sc_zoom_all(features);
                    
                end;
                
                if m==4 % merge cluster with other cluster
                    
                    incluster=find(features.clusters==i );
                    features.clusters_undo=features.clusters;
                    
                    % select target cluster
                    
                    text(0,0,['select target cluster'],'color',[0 0 0],'BackgroundColor',[.9 .9 .9]);
                    
                    
                    [x,y]=ginput(1);
                    targetcluster=[];
                    for j=1:features.Nclusters
                        xoo=(xpos(j)*(psize+.01))+.05;
                        yoo=-(ypos(j)*(psize+.01))+1;
                        if (x> 1+xoo) && (x<1+xoo+psize) && (y>yoo) && (y<psize+yoo) % find waveform display that click is in
                            targetcluster=j;
                        end ;
                    end;
                    
                    if numel(targetcluster)>0
                        features.clusters(incluster)=targetcluster;
                        features=sc_updateclusterimages(features,mua,s_opt);
                    end;
                    
                end;
                

                
                
            end; %left button?
            
            
        else % click on actual waveform
            % make new feature with amplitude at that point
            npoints=numel(mua.ts_spike);
            %xa=  (linspace(0,psize,npoints));
            samples=[-1:1]+((x-(1+xo))/psize)*npoints;
            samples=max(min(round(samples),npoints),1);
            
            % calculate new feature from avg value at that sample
            
            %features.numextrafeaatures=features.numextrafeaatures+1;
            
            features.data(end+1,:)=  mean(mua.waveforms(:,samples)')';
            
            features.name{size(features.data,1)}=['amp@',num2str(round(((x-(1+xo))/psize)*npoints))];
            
            features=sc_scale_features(features);
            
            % select that feature
            features.featureselects(2)=size(features.data,1);
        end;
    end;
    
    
end;