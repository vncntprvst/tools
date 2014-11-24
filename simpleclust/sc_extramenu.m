function varargout=extramenu(features,mua,x,y,b,s_opt)

pos=[-1  -.8 -.6 -.5 -.4 -.3 -.2 0.0 0.1 0.4 0.5 0.8 1 1.2 1.4 1.7 1.9];
pos(6:end)=pos(6:end)+.2;

plot([-1.3 3.3] ,[-1 -1],'color',[.7 .7 .7]);

if nargout==0 % plot
    
    i=1;
    
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,'+wavelet');
    
    
    i=2;
    
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,'+PCA');
    
    
    
    i=3;
    
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,'wf+');
    
    i=4;
    
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,'wf-');
    
    i=5;
    
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,['isi+ [',num2str(features.isioptions(1).tmax),'ms]']);
    
    i=6;
    
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,'isi-');
    
    i=7;
    
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    if features.plotgroup
        plot([0 0.2]+pos(i)+0,[1 1].*-1.05,'color',[.7 .7 .7],'LineWidth',20);
    end;
    text(pos(i)+0.02,-1.05,'plotgroup?');
    
    i=8;
    
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,'.x');
    
    i=9;
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,['Ndisp ',num2str(features.Ndisplay),'(+)']);
    
    i=10;
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,['(-)']);
    
    
    i=11;
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,['new label']);
    
    i=12; % rescaling!
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,['rescale']);
    %sc_scale_features
    
    i=13; % undo
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,['undo']);
    % features.clusters=features.clusters_undo;
    
    
    i=14; % undo
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,['compare']);
    
    i=15; % isi feature
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,['+ISI feature']);
    
    i=16; % sample specific pca feature
    plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
    plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);
    
    text(pos(i)+0.02,-1.05,['+PCA for subsets']);
    
else % evaluate x,y
    
    i=1;
    if (x>pos(i)) && (x<pos(i+1))
        
        button = questdlg('compute wavelet feature? this will take a while.','compute wavelets?','Yes','No','Yes');
        
        if strcmp(button,'Yes')
            
            text(-.5,0,'computing additional wavelet features for visible spikes... ', 'BackgroundColor',[.7 .9 .7]);
            drawnow;
            
            features=sc_compute_extra_wavelet_coeffs(features,mua);
        end;
    end;
    
    
    i=2;
    if (x>pos(i)) && (x<pos(i+1))
        
        text(-.5,0,'computing additional PCA features for visible spikes... ', 'BackgroundColor',[.7 .9 .7]);
        drawnow;
        
        features=sc_compute_extra_PCA_coeffs(features,mua);
        
    end;
    
    
    i=3; % waveforms +
    if (x>pos(i)) && (x<pos(i+1))
        features.waveformscale=features.waveformscale.*1.1;
        features=sc_updateclusterimages(features,mua,s_opt);
    end;
    
    i=4; % waveforms -
    if (x>pos(i)) && (x<pos(i+1))
        features.waveformscale=features.waveformscale.*.9;
        features=sc_updateclusterimages(features,mua,s_opt);
    end;
    
    % if features.selected>0
    if  features.isioptions(1).tmax>15
        c=5;
    else
        c=2;
    end;
    
    
    
    i=5; % ISI +
    if b==3  % on right click open up menu for manual entry
        if   ((x>pos(i)) && (x<pos(i+1))) || ( (x>pos(i)) && (x<pos(i+1)))
            prompt={'Enter max ISI lag (ms)'};
            name='ISI lag';
            numlines=1;
            defaultanswer={'10'};
            
            answer=inputdlg(prompt,name,numlines,defaultanswer);
            try  features.isioptions(1).tmax=str2num(answer{1});
            catch
                features.isioptions(1).tmax=10;
            end;
            if numel( features.isioptions(1).tmax)==0
                features.isioptions(1).tmax=10;
            end;
             features=sc_updateclusterimages(features,mua,s_opt);
        end;
    else % otherwise do +/-
        
        if (x>pos(i)) && (x<pos(i+1))
            features.isioptions(1).tmax=features.isioptions(1).tmax+c;
            
        end;
        
        i=6; % ISI -
        if (x>pos(i)) && (x<pos(i+1))
            
            
            features.isioptions(1).tmax=max(1,features.isioptions(1).tmax-c);
            
        end;
        
        % features=sc_updateclusterimages(features,mua,s_opt);
        
    end;
    %  end;
    
    i=7; % toggle plotgroup
    if (x>pos(i)) && (x<pos(i+1))
        
        features.plotgroup=1-features.plotgroup;
        disp('toggle');
        sc_plotallclusters(features,mua);
        
    end;
    
    i=8; % toggle point size
    if (x>pos(i)) && (x<pos(i+1))
        
        features.plotsize=1-features.plotsize;
        %disp('toggle');
    end;
    
    i=9; %Ndisplay++
    if (x>pos(i)) && (x<pos(i+1))
        features.Ndisplay=features.Ndisplay+5000;
    end;
    i=10; %Ndisplay--
    if (x>pos(i)) && (x<pos(i+1))
        if features.Ndisplay>5000
            features.Ndisplay=features.Ndisplay-5000;
        end;
    end;
    
    
    
    i=11; %  create new label
    if (x>pos(i)) && (x<pos(i+1))
        
        
        prompt = {'Enter new label:'};
        dlg_title = 'new cluster label';
        num_lines = 1;
        def = {''};
        newlabel = inputdlg(prompt,dlg_title,num_lines,def);
        
        if numel(newlabel)>0
            
            features.labelcategories{numel(   features.labelcategories)+1} = newlabel{1};
            features.nlabels=numel(   features.labelcategories);
            features.clusterlabels(features.nlabels)=1;
            
        end;
        %features.plotsize=1-features.plotsize;
        %disp('toggle');
    end;
    
    
    
    i=12; % rescaling
    
    if ((x>pos(i)) && (x<pos(i+1))) || (b==114) % 'r' hotkey
        features=sc_zoom_all(features);
    end;
    %
    
    i=13; % undo
    if (x>pos(i)) && (x<pos(i+1))
        features.clusters=features.clusters_undo;
        features=sc_updateclusterimages(features,mua,s_opt);
        
    end;
    
    
    i=14; % compare clusters
    if (x>pos(i)) && (x<pos(i+1))
        sc_compare_features(features,mua);
    end;
    
    
    i=15; % compute isi feature
    if (x>pos(i)) && (x<pos(i+1))
        
        text(-.5,0,'computing additional ISI features, using only visible spikes... ', 'BackgroundColor',[.7 .9 .7]);
        drawnow;
        
        features=sc_add_isi_feature(features,mua);
    end;
    
    
    i=16; % compute partial pca feature
    if (x>pos(i)) && (x<pos(i+1))
        text(-.5,0,'click on first sample in waveform', 'BackgroundColor',[.7 .9 .7]);
        drawnow
        [x,y,b] = sc_ginput(1);
        
        
        psize=0.65; % find whish one was clicked on
        xpos=[0 0 0 1 1 1 2 2 2];
        ypos=[1 2 3 1 2 3 1 2 3];
        
        
        for i=1:features.Nclusters
            xo=(xpos(i)*(psize+.01))+.05;
            yo=-(ypos(i)*(psize+.01))+1;
            if (x> 1+xo) && (x<1+xo+psize) && (y>yo) && (y<psize+yo) % find waveform display that click is in
                
                
                npoints=numel(mua.ts_spike);
                %xa=  (linspace(0,psize,npoints));
                samples=((x-(1+xo))/psize)*npoints;
                samples_from=max(min(round(samples),npoints),1);
                
                text(-.5,0,'click on secondsample in waveform', 'BackgroundColor',[.7 .9 .7]);
                drawnow;
                
                plot([1 1].*x,yo+[0 psize],'k--');
                
                [x,y,b] = sc_ginput(1);
                
                
                npoints=numel(mua.ts_spike);
                %xa=  (linspace(0,psize,npoints));
                samples=((x-(1+xo))/psize)*npoints;
                samples_to=max(min(round(samples),npoints),1);
                
                
                
                plot([1 1].*x,yo+[0 psize],'k--');
                text(-.5,0,'computing PCA for visible clusters in selected waveform sample range... ', 'BackgroundColor',[.7 .9 .7]);
                drawnow;
                
                
                features=sc_compute_extra_PCA_coeffs_partial(features,mua,samples_from,samples_to);
                
            end;
        end;
        
        
        
    end;
    
    varargout={features};
    
    
    
    
end;
