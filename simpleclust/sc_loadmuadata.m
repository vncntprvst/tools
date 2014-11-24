function [features,mua]=sc_loadmuadata(muafile, dofeatures,s_opt)

skipsetup=0;

muafile
[ignore,ignoreb,muafile_ext] = fileparts(muafile);
muafile_ext = muafile_ext(2:end);

switch muafile_ext
    
    case 'spikes' % open ephys data format
        [data, timestamps, info] = load_open_ephys_data(muafile);
        
        features.chnumstr = info.header.electrode;
        features.sourcechannel= str2num(info.header.electrode(end-1:end));
        sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
        
        
        mua.Nspikes = numel(timestamps);

       % mua.ts=timestamps./info.header.sampleRate;
         mua.ts=timestamps;
        [pathstr, name, ext] = fileparts(muafile);
        mua.fname=[name,ext];
        
        
        mua.opt=[];
        mua.header=info.header;
        
        mua.ncontacts = info.header.num_channels;
        
        mua.val2volt=1; % alreaddy done in load script
        
        % flatten waveforms for display
        
        mua.waveforms=reshape(data,size(data,1),size(data,2)*size(data,3),1);
        
        
        mua.ts_spike=linspace(-.5,3.5,40* mua.ncontacts); %  neuralynx saves 32 samples at 30303Hz, so its a 1.056ms window
        
        
        if dofeatures
            features=sc_mua2features(mua,s_opt);
            features.sourcechannel=sourcechannel;
        end;
        

        
        
        
    
    case 'mat'
        load(muafile);
        
        if ~ exist('mua', 'var') % no mua var in there, try doreas format
            
            if exist('times_all', 'var') % marker for doreas mat format
                
                if dofeatures
                    if s_opt.auto_number==0
                        prompt = {['source channel nr for file ',muafile]};
                        dlg_title = 'channel nr';
                        num_lines = 1;
                        def = {''};
                        features.chnumstr = inputdlg(prompt,dlg_title,num_lines,def);
                        features.sourcechannel= str2num(features.chnumstr{1});
                        sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
                    else
                        
                        %do it automatically
                        [ignore,n,ignoreb]=fileparts(muafile)
                        disp('automatically detecting ch number for');
                        disp(muafile);
                        
                        
                        nind=find(ismember(n, '0':'9'));
                        if numel(nind)>2 || numel(nind)==0
                            error('for automatic channel numbering make sure the mua filenames contain just one number between 1 and 99 ');
                        end;
                        ch=str2num(n(nind));
                        disp(['-> ch ',num2str(ch)]);
                        features.chnumstr = ch;
                        features.sourcechannel= ch;
                        sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
                        
                    end;
                    
                end;
                
                % load doreas format
                mua.opt=[];
                mua.fname=muafile;
                
                mua.Nspikes = numel(times_all);
                
                % concatenate all waveforms
                
                mua.ncontacts = size(waveforms,2);
                
                mua.waveforms = (reshape(waveforms,size(waveforms,1)*size(waveforms,2),size(waveforms,3) ))';
                
                mua.ts = times_all;
                
                mua.ts_spike=[1:size( mua.waveforms,2)];
                if dofeatures
                    features=sc_mua2features(mua,s_opt);
                    features.sourcechannel=sourcechannel;
                end;
                
                
            end;
            
        else % file has a variable mua in it, probably jakobs own format
            if  exist('features', 'var') %marker for simple_clust output format
                
                if numel(mua.ts)<size(mua.waveforms,1)
                    warning('fewer spikes than waveforms, truncating!');
                    mua.waveforms = mua.waveforms(1:numel(mua.ts),:);
                end;


                % we just loaded previous simple_clust data
                % in theory there should be nothing left to do here?
                skipsetup=1;
                features.skipsetup=1; % so the main program doesnt try to run scripts like auto noise rejection again
                
            else
                
                % parse jakobs ad hoc format here
                % for now we only deal with simple electrodes and ones
                % extracted from laminar recordings
                
                if size(mua.waveforms,2)==3% extracted from laminar, 3 contacts!
                    
                    mua.ncontacts = 3;
                    
                    
                    
                    
                    % reformat wavewforms, flatten for display
                    
                    %D= (squeeze(reshape(mua.waveforms,1,128,size(mua.waveforms,3))));
                    D=[squeeze(mua.waveforms(:,1,:))',squeeze(mua.waveforms(:,2,:))',squeeze(mua.waveforms(:,3,:))'];
                    mua.waveforms=D;
                    
                    mua.ts_spike=linspace(-.5,2.5,93); %  we do  31 samples at 30303Hz, so its a 1.056ms window
                    
                    if dofeatures
                        features=sc_mua2features(mua,s_opt);
                        sourcechannel=mua.sourcechannel;
                        features.sourcechannel=sourcechannel;
                    end;
                elseif size(mua.waveforms,2)==4 %tetrode recording
                    
                    mua.ncontacts = 4;
                    
                    D=[squeeze(mua.waveforms(:,1,:))',squeeze(mua.waveforms(:,2,:))',squeeze(mua.waveforms(:,3,:))',squeeze(mua.waveforms(:,4,:))'];
                    mua.waveforms=D;
                    
                    mua.ts_spike=linspace(-.5,2.5,93); %  we do  31 samples at 30303Hz, so its a 1.056ms window
                    mua.ts_spike=linspace(0,4,size(mua.waveforms,2));
                    if dofeatures
                        features=sc_mua2features(mua,s_opt);
                        sourcechannel=mua.sourcechannel;
                        features.sourcechannel=sourcechannel;
                    end;
                else
                    mua.ncontacts = 1;
                    
                    if dofeatures
                        features=sc_mua2features(mua,s_opt);
                        sourcechannel=mua.sourcechannel;;
                        features.sourcechannel=sourcechannel;
                    end;
                end;
            end;
            
        end;
        
    case 'nse'
        
        if dofeatures
            if s_opt.auto_number==0
                prompt = {['source channel nr for file ',muafile]};
                dlg_title = 'channel nr';
                num_lines = 1;
                def = {''};
                features.chnumstr = inputdlg(prompt,dlg_title,num_lines,def);
                features.sourcechannel= str2num(features.chnumstr{1});
                sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
            else
                
                %do it automatically
                [ignore,n,ignoreb]=fileparts(muafile)
                disp('automatically detecting ch number for');
                disp(muafile);
                
                
                nind=find(ismember(n, '0':'9'));
                if numel(nind)>2 || numel(nind)==0
                    error('for automatic channel numbering make sure the mua filenames contain just one number between 1 and 99 ');
                end;
                ch=str2num(n(nind));
                disp(['-> ch ',num2str(ch)]);
                features.chnumstr = ch;
                features.sourcechannel= ch;
                sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
                
            end;
            
        end;
        
        cdata = read_cheetah_data(muafile);
        %mua = load_neuralynx_mua(muafile);
        
        clear mua;
        mua=[];
        mua.Nspikes = size(cdata.ts,1);
        mua.waveforms=cdata.waveforms;
        mua.ts=cdata.ts;
        
        %identify bits2volt in header
        vstart=strfind(cdata.header,'ADBitVolts');
        mua.val2volt=str2num(cdata.header(vstart+10:vstart+24));
        
        [pathstr, name, ext] = fileparts(muafile);
        mua.fname=[name,ext];
        
        
        mua.opt=[];
        mua.header=cdata.header;
        
        
        
        mua.ncontacts = size(mua.waveforms,1);
        
        % flatten waveforms for display
        
        D= (squeeze(reshape(mua.waveforms,1,32,size(mua.waveforms,3))));
        mua.waveforms=[D(1:end,:)]';
        mua.ts_spike=linspace(-.5,0.5,32);  %  neuralynx saves 32 samples at 30303Hz, so its a 1.056ms window
        
        if dofeatures
            features=sc_mua2features(mua,s_opt);
            features.sourcechannel=sourcechannel;
        end;
        
    case 'nst'
        
        if dofeatures
            if s_opt.auto_number==0
                prompt = {['source channel nr for file ',muafile]};
                dlg_title = 'channel nr';
                num_lines = 1;
                def = {''};
                features.chnumstr = inputdlg(prompt,dlg_title,num_lines,def);
                features.sourcechannel= str2num(features.chnumstr{1});
                sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
            else
                
                %do it automatically
                [ignore,n,ignoreb]=fileparts(muafile)
                disp('automatically detecting ch number for');
                disp(muafile);
                
                
                nind=find(ismember(n, '0':'9'));
                if numel(nind)>2 || numel(nind)==0
                    error('for automatic channel numbering make sure the mua filenames contain just one number between 1 and 99 ');
                end;
                ch=str2num(n(nind));
                disp(['-> ch ',num2str(ch)]);
                features.chnumstr = ch;
                features.sourcechannel= ch;
                sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
                
            end;
            
        end;
        cdata = read_cheetah_data(muafile);
        %mua = load_neuralynx_mua(muafile);
        
        clear mua;
        mua=[];
        mua.Nspikes = size(cdata.ts,1);
        mua.waveforms=cdata.waveforms;
        mua.ts=cdata.ts;
        
        [pathstr, name, ext] = fileparts(muafile);
        mua.fname=[name,ext];
        
        
        mua.opt=[];
        mua.header=cdata.header;
        
        %identify bits2volt in header
        vstart=strfind(cdata.header,'ADBitVolts');
        mua.val2volt=str2num(cdata.header(vstart+10:vstart+24));
        
        mua.ncontacts = size(mua.waveforms,1);
        
        % flatten waveforms for display
        
        D= (squeeze(reshape(mua.waveforms,1,64,size(mua.waveforms,3))));
        mua.waveforms=[D(1:2:end,:);D(2:2:end,:)]';
        mua.ts_spike=linspace(-.5,1.5,64); %  neuralynx saves 32 samples at 30303Hz, so its a 1.056ms window
        
        if dofeatures
            features=sc_mua2features(mua,s_opt);
            features.sourcechannel=sourcechannel;
        end;
        
    case 'ntt'
        
        
        if dofeatures
            if s_opt.auto_number==0
                prompt = {['source channel nr for file ',muafile]};
                dlg_title = 'channel nr';
                num_lines = 1;
                def = {''};
                features.chnumstr = inputdlg(prompt,dlg_title,num_lines,def);
                features.sourcechannel= str2num(features.chnumstr{1});
                sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
            else
                
                %do it automatically
                [ignore,n,ignoreb]=fileparts(muafile)
                disp('automatically detecting ch number for');
                disp(muafile);
                
                
                nind=find(ismember(n, '0':'9'));
                if numel(nind)>2 || numel(nind)==0
                    error('for automatic channel numbering make sure the mua filenames contain just one number between 1 and 99 ');
                end;
                ch=str2num(n(nind));
                disp(['-> ch ',num2str(ch)]);
                features.chnumstr = ch;
                features.sourcechannel= ch;
                sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
                
            end;
            
        end;
        cdata = read_cheetah_data(muafile);
        %mua = load_neuralynx_mua(muafile);
        
        clear mua;
        mua=[];
        mua.Nspikes = size(cdata.ts,1);
        mua.waveforms=cdata.waveforms;
        mua.ts=cdata.ts;
        
        [pathstr, name, ext] = fileparts(muafile);
        mua.fname=[name,ext];
        
        
        mua.opt=[];
        mua.header=cdata.header;
        
        mua.ncontacts = size(mua.waveforms,1);
        
        
        %identify bits2volt in header
        vstart=strfind(cdata.header,'ADBitVolts');
        mua.val2volt=str2num(cdata.header(vstart+10:vstart+24));
        
        
        % flatten waveforms for display
        
        D= (squeeze(reshape(mua.waveforms,1,128,size(mua.waveforms,3))));
        mua.waveforms=[D(1:4:end,:);D(2:4:end,:);D(3:4:end,:);D(4:4:end,:)]';
        
        
        mua.ts_spike=linspace(-.5,3.5,128); %  neuralynx saves 32 samples at 30303Hz, so its a 1.056ms window
        
        
        if dofeatures
            features=sc_mua2features(mua,s_opt);
            features.sourcechannel=sourcechannel;
        end;
        
    case 'wf'
        if dofeatures
            if s_opt.auto_number==0
                prompt = {['source channel nr for file ',muafile]};
                dlg_title = 'channel nr';
                num_lines = 1;
                def = {''};
                features.chnumstr = inputdlg(prompt,dlg_title,num_lines,def);
                features.sourcechannel= str2num(features.chnumstr{1});
                sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
            else
                %do it automatically
                [ignore,n,ignoreb]=fileparts(muafile);
                disp('automatically detecting ch number for');
                disp(muafile);
                
                chstr = regexpi(n, '_Ch(\d)', 'tokens');
                if isempty(chstr),
                    ch = 0;
                else
                    %We'll take the first channel as our channel
                    ch = str2num(chstr{1}{1});
                end
                disp(['-> ch ',num2str(ch)]);
                features.chnumstr = ch;
                features.sourcechannel= ch;
                sourcechannel=features.sourcechannel; % just so we dont overwrite it in  'features=sc_mua2features(mua,s_opt);'
                
            end;
            
        end;
        
        
        % load tim's format
        mua.opt = LoadSpikeWF(muafile, [], 6);
        mua.fname=muafile;
        
        mua.Nspikes = LoadSpikeWF(muafile, [], 5);
        
        %Load waveforms
        [mua.ts, wv] = LoadSpikeWF(muafile, [1 mua.Nspikes], 4);
        
        % concatenate all waveforms
        mua.ncontacts = size(wv,2);
        
        %Copy waveforms over
        size(wv)
        mua.waveforms = zeros(size(wv, 1), size(wv, 2)*size(wv, 3));
        for i = 1:size(wv, 1),
            mua.waveforms(i, :) = reshape(squeeze(wv(i, :, :))', [1 size(wv, 2)*size(wv, 3)]);
        end
        size(mua.waveforms)
        
        mua.ts_spike = linspace(mua.opt.SpikeExtract_WFRange(1), mua.opt.SpikeExtract_WFRange(2), mua.opt.NumPointsInWF)./mua.opt.SampleFrequency;
        if dofeatures
            features=sc_mua2features(mua,s_opt);
            features.sourcechannel=sourcechannel;
        end;
        
    otherwise
        error('unrecognized file format');
end;


if ~dofeatures
    skipsetup=1;
    features=[]; % in this case just return the mua
end;


if ~skipsetup
    
    %% config and setup
    features.clusters=ones(size(features.id));
    features.clusters_undo=features.clusters;
    features.clustervisible=ones(1,12);
    
    
    if ~isfield(s_opt,'skipevery_wf_display') % bkwrds comp.
     s_opt.skipevery_wf_display=8; % if it's not specified, use a pretty conservative number so that things look the same
    end;
    
    
    %features.clusters(1:100)=2;
    features.labelcategories = {' ','noise','neg','unit','unit_{FS}','unit_{RS}','unit_{huge}','mua big','mua wide','mua thin','mua small','negative','artefact',};
    
    features.clusterfstrs={'k.','b.','r.','g.','c.','r.','k.','r.','b.'};
    features.colors=[.7 .7 .7; 1 0 0; 0 1 0; 0 0 1; 1 .7 0; 1 .2 1; 0 1 1; 1 .5 0; .5 1 0; 1 0 .5];
    features.Nclusters=2;
    features.imagesize=100;
    
    features.waveformscale=0.0001;
    
    % find appropriate scale for plotting waveforms
    features.waveformscale=0.1 ./ quantile(mua.waveforms(1:100:end)-mean(mua.waveforms(1:100:end)),.95);
    
    features.range=zeros(size(features.data,1),2); % for x/y range display
    features.zoomrange=zeros(size(features.data,1),2); % where do we display right now
    
    
    
    features.numextrafeaatures=0;
    features.highlight = 0;
    features.clusterimages=ones(features.imagesize,features.imagesize,12);
    features.selected=0;
    features.plotsize=0;
    
    features.timeselectwidth=200;
    features.timeselection=0;
    
    features.Ndisplay=25000;
    
    for i=1:1
        features.isioptions(1).tmax=10;
        features.isioptions(1).nbins=50;
    end;
    
    features.plotgroup=1;
    
    features.highlight_multiple(1:10)=1;
    features.clusterlabels(1:10)=1;
    features.nlabels=numel(features.labelcategories );
    
    % preprocess features to fit 1 1 -1 -1 box
    features=sc_scale_features(features);
    
    features=sc_addnoisetoquantiledfeatures(features);
    % laod icons
    %features.eye_icon_o=imread('eye.png');
    %features.eye_icon_x=imread('eye_closed.png');
    
    features.timevisible=ones(1,numel(features.ts));
    features.randperm = randperm(numel(features.ts));
    
    
    features.featureselects=[2 3];
    
    features=sc_updateclusterimages(features,mua, s_opt);
end;

run=1;
