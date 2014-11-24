[features,mua]=sc_loadmuadata(features.muafile,1,s_opt);


features.muafilepath =[PathName];

if s_opt.batch
    
    features.muafile =[PathName,multifiles{multi_N}];
    features.muafile_justfile =multifiles{multi_N};
else
    features.muafile =[PathName,FileName];
    features.muafile_justfile =FileName;
end;

% cd(PathName); % for faster selection of later input files


% ask to load other files
% this can be used to make a feature that counts how many
% channels a spike occurs in simultaneously

if ~isfield(features,'skipsetup') % backwards comp. - if no field, assume its not a prev. simpleclust file
    features.skipsetup=0;
end;

if s_opt.auto_overlap && (features.skipsetup==0) % automatically load all others
    
    features.loadmultiple=1;
    otherfiles=[ dir([PathName,'*.ntt']) ;dir([PathName,'*.nst']) ;dir([PathName,'*.nse']) ;dir([PathName,'*_extracted.mat']) ;dir([PathName,'*.spikes']) ];
    
    cc=1;j=1;
    
    while cc && (j<=numel(otherfiles))   % throw put current channel
     
        if strcmp(otherfiles(j).name,mua.fname)
            otherfiles(j)=[]; cc=0;
        end; 
        j=j+1;



    end;
    
    if s_opt.auto_overlap_max > 0  % cut down to limits
        otherfiles=otherfiles(1:min(numel(otherfiles),s_opt.auto_overlap_max));
    end;
    
    
    features.otherchannelfiles={otherfiles.name};
    if numel(otherfiles) >1
        [features,mua]=sc_addotherchannelstomua(features,mua);
    else
        disp('no other files to process for overlap feature');
    end;
    
    if s_opt.auto_noise
        
        features.clusterlabels(2)=2; % make 2nd cluster 'noise'
        features.clustervisible(2)=0; % make invisible
        
        fn=find(strcmp(features.name,'Ch.overlap')); % find feature
        if numel(fn)==0
            warning('selected automatic noise rejection but not Ch.overlap feature found!');
        else
            
            ii= features.data(fn(1),:)>s_opt.auto_noise_trs;
            features.clusters(ii)=2; % assign
            features=sc_updateclusterimages(features,mua,s_opt);
        end;
        
        
    end;
    
    
else % select manually
    if s_opt.auto_overlap_dontask
        features.loadmultiple=0;
    else
    if (debugstate >0) || (s_opt.batch)
        button='no';
    else
        
        button = questdlg('Open other channnels from same recording?','open?','Yes','No','Yes');
    end;
    
    if strcmp(button,'Yes')
        features.loadmultiple=1;
        [FileName,PathName,FilterIndex] = uigetfile({'*.wf;*.nse;*.nst;*.ntt;','all base electrode file types';'*_simpleclust.mat', 'simpleclust file';'*.mat', 'matlab file';'*_extracted.mat', 'extracted matlab file';'*.wf','Waveform file';'*.nse' ,'neuralynx single electrode file'; '*.nst',  'neuralynx stereotrode file'; '*.ntt',  'neuralynx tetrode file'},['choose files for other channels (vs ch ',num2str(spikes.sourcechannel),')'],'MultiSelect','on');

        features.otherchannelfiles=FileName;
        
        [features,mua]=sc_addotherchannelstomua(features,mua);
        
    else
        features.loadmultiple=0;
    end;
    end
    
end;

dataloaded=1;
