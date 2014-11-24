%{
   -----------------------------------------------------------------------
  
    Simple Clust v0.5
   
    (c) jan. 2012, Jakob Voigts (jvoigts@mit.edu)
 
    Beta version, use at your own risk

    -----------------------------------------------------------------------


    This is a program for manual clustering of spikes in matlab.
    I dont recommend this software for scientific use by
    anyone without full understanding of the methods.

    Please post any issues you encounter, or any improvements or additions 
    to github at:

    http://github.com/moorelab/simpleclust


    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


   %}

%{
features 2do:

- add rescale all features button
- add inverted ++ to noise cluster operations
- add (r) shortcut to recsale
X - fix ISI display
X- loading of simpleclust state with clusters etc intact
X- 'remove features' button (small x) on left
X - add ++ button that puts spikes into cluster from any other cluster even if prev. asigned
X- ISI display
X- xcorr feature
X- display multiple waveforms around where user clicke, like 10ish
X- allow rescaling of all visible clusters, pretty much works as zoom
X- time selection at bottom? or just add time feature?
X - add merge clusters function
X- add better features for loading stereotrode and tetrode data
X- undo function for the cluster operations
X- make peaks/energy etc work with TTL/ST files
X- make selection polygon same color as the cluster
X - automatically scale waveforms when loading (scaling by 95 quantile of all waveforms)
X - proper zoom function
X - detection of spike overlaps over many channels
X - ma keeoverlap faster by doing histogram method by default
X - do overlap as percent of channels
X - improve label selection
X - fix spike.waveform_ts lenght in tetrodes (is sized for st)
X - dsplay ch in overlap selection
X - add progress bar for initial waveform supersampling,
X - try to improve waveform supersampling speed (do linear?)
X - do . display by default, not x, increase default displynum to 30000
X - add batch process functions, sorte work in progress
X - figure out saving as ch_simpleclust with no channel nnr bug
- add warning if ch is not just a number
X- add isi feature
X - make add function take spikes only from visible clusters
 - allow to change color
 - save selected color for plotting in later analysis?
X - add template matching to selected cluster?
- auto-realigning of waveforms to interpolated peaks or even some more robust kernel thing
- add feature to permanently delete cluster
- add thinning feature for mua etc that reduces stochastically till some max rate is hit

%}


%% user options

s_opt = []; 

s_opt.mex_intersect=1; % use mex fn for poly intersect (much faster)
s_opt.dont_save_noise=1; % exclude noise from final output, not from the simpleclust file though

s_opt.auto_overlap = 1; % automatically loads other channels from same recording and computes spike overlap
s_opt.auto_overlap_dontask = 1; % dont ask if others should be loaded
s_opt.auto_overlap_max = 1; %if >0, limits how many other channels are loaded

s_opt.auto_noise = 1; % automatically assign channels with high overlap into noise cluster
s_opt.auto_noise_trs = 2; %proportion of channels a spike must co-occur in within .2ms in order to be classified noise

s_opt.auto_number = 1; % if set to 1, simpleclust will assume that there is ONLY ONE number in the MUA filenames and use is to designate the source channel for the resulting data

s_opt.invert= 1; % invert waveforms?

s_opt.skipevery_wf_display = 16; % skip every Nth waveform in the waveform display - this only sets an upper bound! smaller clusters will not be affected by this.

% specify what features to compute:
s_opt.features.pca=0;
s_opt.features.wavelet=0;
s_opt.features.nonlinear_energy=1;
s_opt.features.max_derivative=1;

%% init
run = 1;
dataloaded = 0;
s_opt.batch = 0;

features.updatezoom=1; % so that new features are check3d for zoom state and visibility, set 1 after each zoom operation or new feature

global debugstate;
debugstate = 0; % 0: do nothing, 1: go trough following states
debuginput = [0 0 0];

%addpath(pwd); % warn instead
%addpath(fullfile(pwd,'read_cheetah'));

if numel(strfind(path,'read_cheetah')) ==0
    error('make sure the read_cheetah dir is in your matlab path');
end;

if s_opt.mex_intersect
    if numel(strfind(path,'InPolygon-MEX')) ==0
    error('make sure the InPolygon-MEX dir is in your matlab path, or disable s_opt.mex_intersect');
end;
end;

%% main loop

while run
    
    figure(1); clf; hold on; grid off;
    fill([-2 -2 5 5],[-2 2 2 -2],'k','FaceColor',[.92 .92 .92]);
    set(gca, 'position', [0 0 1 1]);
    title('simple clust v0.5');
    
    if ~dataloaded % plot title screen
        
        x=linspace(0,2*pi,80);
        
        for i=2:22 % rings
            sc=(i/4)^2;
            plot(sin(x).*sc.*.3,cos(x).*sc.*.3,'k','LineWidth',28,'color',[.9 .9 .9])
        end;
        
        % plot some cute spike
        plot(sin(x).*1.*.15,cos(x).*1.*.15,'k','LineWidth',58,'color',[1 1 1].*.9);
        
        ll=linspace(0,1,64); wf=sc_title_waveform;
        plot(ll-.3,wf./40000,'k','LineWidth',25,'color',[1 1 1].*.92);
        plot(ll(2:end-1)-.3,wf(2:end-1)./40000,'k','LineWidth',14,'color',[1 1 1].*.96);
        plot(ll(3:end-2)-.3,wf(3:end-2)./40000,'k','LineWidth',9,'color',[1 1 1]);
        
        
        text(0,0,'Simple Clust v0.5')
        set(gca,'xlim',[-1.3, 3.3],'ylim',[-1.3, 1.2]);
        daspect([1 1 1]);set(gca,'XTick',[],'YTick',[]);
        
        
        fill([-1.2 -1 -1 -1.2],[1 1 1.2 1.2]-0.2,'b','FaceColor',[.9 .9 .9]);
        
        text(-1.18,1.05-0.2,'batch run');
        plot([-1.2 -1],[1.1 1.1]-0.2,'color',[0 0 0]);
        text(-1.18,1.15-0.2,'batch prep');
        
        plot([-1.2 -1],[1 1],'color',[.0 .0 .0]);
        
    end;
    
    fill([-1.2 -1 -1 -1.2],[1 1 1.2 1.2],'b','FaceColor',[.9 .9 .9]);
    
    text(-1.18,1.05,'save/exit');
    plot([-1.2 -1],[1.1 1.1],'color',[0 0 0]);
    if s_opt.batch
        text(-1.18,1.17,'next file');
        text(-1.18,1.13,[num2str(multi_N),'/',num2str(numel(multifiles))]);
        
        
    else
        text(-1.18,1.15,'open');
    end;
    
    plot([-1.2 -1],[1 1],'color',[.7 .7 .7]);
    
    set(gca,'xlim',[-1.3, 3.3],'ylim',[-1.3, 1.2]);
    daspect([1 1 1]);set(gca,'XTick',[]); set(gca,'YTick',[]);
    
    
    if dataloaded
        
        features=sc_plotclusters(features);
        
        sc_plotfeatureselection(features);
        
        sc_plotclusterselection(features);
        
        sc_plotallclusters(features,mua,s_opt);
        
        sc_extramenu(features);
        
        sc_timeline(features,mua,x,y,b);
        
        % ISI is now plotted for all clusters
        % if features.selected>0
        %     sc_plot_cluster_info(features,features.selected);
        % end;
        
        features.highlight = 0; % remove highlight on each click
    end;
    
    
    
    [x,y,b] = sc_ginput(1);
    
    % fixes occasional crashes (when clicking on window borders?)
    if numel(x)==0
        x=0; y=0; b=0;
    end;
    
    if ~dataloaded
        if (x<-1)&& (y>0.9) && (y<1) % batch (pre)process
            
            [FileName,PathName,FilterIndex] = uigetfile({'*.wf;*.nse;*.nst;*.ntt;*.spikes;','all base electrode file types';...
                '*_simpleclust.mat', 'simpleclust file';'*.spikes', 'open ephys file';'*.mat', 'matlab file';...
                '*_extracted.mat', 'extracted matlab file';'*.wf','Waveform file';'*.nse' ,'neuralynx single electrode file';...
                '*.nst',  'neuralynx stereotrode file'; '*.ntt',  'neuralynx tetrode file'},['choose files to process'],'MultiSelect','on');

            
            if FilterIndex(1)~=0
                for b=1:numel(FileName)
                    
                    features.muafile =[PathName,FileName{b}];
                    
                    fprintf('processing file %d of %d \n',b,numel(FileName));
                    
                    sc_load_mua_dialog;
                    sc_save_dialog;
                    
                end;
            end;
            dataloaded=0;
            
        end;
        
        
        if (x<-1)&& (y>0.8) && (y<0.9) % batch run - open folder of simpleclust files and loop trough sorting them one at a time
            
            
            [multifiles,PathName,FilterIndex] = uigetfile({'*.wf;*.nse;*.nst;*.ntt;*.spikes;','all base electrode file types';...
                '*_simpleclust.mat', 'simpleclust file';'*.spikes', 'open ephys file';'*.mat', 'matlab file';...
                '*_extracted.mat', 'extracted matlab file';'*.wf','Waveform file';'*.nse' ,'neuralynx single electrode file';...
                '*.nst',  'neuralynx stereotrode file'; '*.ntt',  'neuralynx tetrode file'},['choose files to cluster'],'MultiSelect','on');
            
            
            if FilterIndex(1)~=0
                s_opt.batch=1; % indicate we're doing a batch
                multi_N=1; % cycle trough many files
                
                
                features.muafile =[PathName,multifiles{multi_N}];
                sc_load_mua_dialog;
            else
                dataloaded=0;
            end;
            
        end;
        
    end
    
    if dataloaded
        
        features=sc_parse_feature_selection(x,y,features);
        
        features=sc_parse_custerselection(features,x,y,mua,s_opt);
        
        features=sc_parse_clickonwaveforms(x,y,features,mua,s_opt);
        
        features=sc_parse_zoom(b,x,y,features);
        
        features=sc_timeline(features,mua,x,y,b);
        
        
        if y<-1 && y>-1.1
            features=  sc_extramenu(features,mua,x,y,b,s_opt);
        end;
        
        if (b==3) && (abs(x)<1) && (abs(y)<1)
            features=sc_parse_highlight_wave(x,y,features);
        end;
    end;
    
    if (x<-1)&& (y>1)
        if y > 1.1
             
            disp('open');
            
            
            if s_opt.batch % open next file in batch
                if dataloaded
                    button = questdlg('Save and open next file?','open?','Yes','No','Yes');
                else
                    button='Yes';
                end;

                sc_save_dialog;
                multi_N=multi_N+1;

                features.muafile =[PathName,multifiles{multi_N}];
                sc_load_mua_dialog;
                  
            else % open one file
                
                if dataloaded
                    button = questdlg('Open new MUA dataset?','open?','Open','Continue editing','Open');
                else
                    button='Open';
                end;
                if strcmp(button,'Open')
                    
                    % load MUa data
                    
                    global debugstate;
                    if debugstate > 0
                        PathName = '/home/jvoigts/Dropbox/em003/good/';
                        FileName =  'ST11.nse';
                    else
                        [FileName,PathName,FilterIndex] = uigetfile({'*.wf;*.nse;*.nst;*.ntt;*.spikes;','all base electrode file types';'*_simpleclust.mat', 'simpleclust file';'*.mat', 'matlab file';'*.wf','Waveform file';'*.nse' ,'neuralynx single electrode file'; '*.nst',  'neuralynx stereotrode file'; '*.ntt',  'neuralynx tetrode file'},'choose input file');
                    end;
                    
                    features.muafile =[PathName,FileName];
                    % ask user for channel number this file comes from
                    % could parse filename here but the small time saving is
                    % not worth the loss of flexibility
                    %
                    %   features.muafile='/home/jvoigts/Documents/moorelab/acute_test_may27_2011/data_2011-05-20_00-12-09_oddball/spikes_from_csc/mua_ch5.mat';
                    sc_load_mua_dialog;
               
                    % if not, just keep going
               % else
               %     run=0;
               %    
               %     return;
                end;
            end;
            
            % exit/save
        else
            disp('save/exit');
            % ask for saving here
            if dataloaded
                button = questdlg('Save clusters?','save?','Save','Continue editing','Save'); 
                if strcmp(button,'Save')
                    
                    sc_save_dialog;
                    
                    button = questdlg('Quit or load new file?','Quit?','Load new file...','Quit','Load new file...');
                    if strcmpi(button, 'quit'),
                        run=0;
                        continue;
                    else
                        % load MUa data
                        global debugstate;
                        if debugstate > 0
                            
                            PathName = '/home/jvoigts/Dropbox/em003/good/';
                            FileName =  'ST11.nse';
                        else
                            
                            [FileName,PathName,FilterIndex] = uigetfile({'*.wf;*.nse;*.nst;*.ntt;*.spikes;','all base electrode file types';'*_simpleclust.mat', 'simpleclust file';'*.mat', 'matlab file';'*.wf','Waveform file';'*.nse' ,'neuralynx single electrode file'; '*.nst',  'neuralynx stereotrode file'; '*.ntt',  'neuralynx tetrode file'},'choose input file');
                            
                        end;
                        
                        features.muafile =[PathName,FileName];
                        % ask user for channel number this file comes from
                        % could parse filename here but the small time saving is
                        % not worth the loss of flexibility
                        %
                        %   features.muafile='/home/jvoigts/Documents/moorelab/acute_test_may27_2011/data_2011-05-20_00-12-09_oddball/spikes_from_csc/mua_ch5.mat';
                        sc_load_mua_dialog;
                    end
                    
                end;
            else
                clf; drawnow;
                run=0;
            end;
        end;
        
        
    end;
    
end; % while run
