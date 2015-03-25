function catamaran(ntt_file_name)
%catamaran: spike sorting from Neuralynx NTT files.

% Version 1.3, 27 February 2012
% written by Douglas M. Schwarz
% Dept. of Neurobiology & Anatomy
% University of Rochester
% douglas.schwarz@rochester.edu


good_struct = struct('clus',[],'num',[],'rating',[]);
tetrode_struct = struct('NumClusters',NaN,...
	'Method','',...
	'ClusteringAlgorithm','',...
	'Seed',[],...
	'OutlierThreshold',[],...
	'Merges',[],...
	'Time',[],...
	'Good',good_struct,...
	'smallint',[]);

sessions = struct('AlignSpikes',[],...
	'Frac',[],...
	'tetrode',tetrode_struct);

spikes = struct('raw',[],'aligned',[],'timestamp',[],'algorithm',-1);
timestamps = [];
ce = [];
ce_table1 = [];
ce_table2 = [];
Clusters = struct('k',[],'idx0',[],'idx',[],'Q',[],'D',[],'ce0',[],...
	'ce',[],'is_outlier',[]);
T = struct('X',[],'valid',[],'num_comp',[],'seed',[],...
	'outlier_threshold',[],'merges',{{}},'method','',...
	'clustering_algorithm','','raw',Clusters,'merged',Clusters,...
	'isgood',[],'isexcellent',[],'rating',NaN);
spike_bits = 12;
frac = 0.95;
align_spikes = 4;
time_span = [0 inf];

clustering_algorithms = {'Classic','GMM','ksmd 0','ksmd 0.25','ksmd 0.5',...
	'ksmd 0.75','ksmd 1','ksmd 1.25','ksmd 1.5','ksmd 1.75','ksmd 2',...
	'kmeans'};
clustering_alg_id = 7;

% Get or create preferences.
this_app = mfilename;
if ispref(this_app,'prefs')
	prefs = getpref(this_app,'prefs');
else
	prefs = struct('AutoSave',false,'DefaultFolder','');
end

% Initialize source folder.
if nargin == 0
	ntt_dir = prefs.DefaultFolder;
	ntt_file_name = '';
else
	ntt_dir = fileparts(ntt_file_name);
end

methods = {'RPS','RPS-','RPS2','RPS2-','PCA all wires','RPS/PCA',...
	'RPS/ANC','RPS/ANC2',...
	'FFT1/PCA','FFT2/PCA','FFT3/PCA','DCT/PCA','FFT/KS','DCT/KS',...
	'KS only','Bimodality4','(RPS + FFT1)/PCA','Wavelets/KS'};
method_id = 1;

% Results variable.
idx_all = [];

% Initialize cluster merge tool figure handle.
cmfig = [];

% Create GUI figure and initialize variables.
if ispref(this_app,'fig_pos')
	fig_pos = getpref(this_app,'fig_pos');
	fig = figure('Units','pixels',...
		'Position',fig_pos,...
		'NumberTitle','off',...
		'Toolbar','none',...
		'Menubar','none',...
		'Name',this_app,...
		'IntegerHandle','off',...
		'CloseRequestFcn',@close_fig,...
		'KeyPressFcn',@keypress,...
		'ResizeFcn',@resize);
else
	fig_pos_norm = [0.01 0.04 0.98 0.91];
	fig = figure('Units','normalized',...
		'Position',fig_pos_norm,...
		'NumberTitle','off',...
		'Toolbar','none',...
		'Menubar','none',...
		'Name',this_app,...
		'IntegerHandle','off',...
		'CloseRequestFcn',@close_fig,...
		'KeyPressFcn',@keypress,...
		'ResizeFcn',@resize);
	set(fig,'Units','pixels')
	fig_pos = round(get(fig,'Position'));
	set(fig,'Position',fig_pos)
	setpref(this_app,'fig_pos',fig_pos)
end

% Set uicontrol font on Mac and Windows to respective system font.
if ismac
	font_name = 'Lucida Grande';
	font_size = 9;
elseif ispc
	font_name = 'Tahoma';
	font_size = 8;
else
	font_name = 'default';
	font_size = 9;
end
set(fig,'DefaultUIControlFontName',font_name)
set(fig,'DefaultUIControlFontSize',font_size)
font_name = get(fig,'DefaultUIControlFontName');
font_size = get(fig,'DefaultUIControlFontSize');

% File menu.
file_menu = uimenu(fig,'Label','File');
uimenu(file_menu,'Label','Open...',...
	'Accelerator','O',...
	'Callback',@open_file)
save_as_item = uimenu(file_menu,'Label','Save As...',...
	'Accelerator','S',...
	'Enable','off',...
	'Callback',@save_as);
if ispc
	uimenu(file_menu,'Label','Show in Explorer',...
		'Separator','on',...
		'Accelerator','H',...
		'Callback',@show_folder)
elseif ismac
	uimenu(file_menu,'Label','Show in Finder',...
		'Separator','on',...
		'Accelerator','H',...
		'Callback',@show_folder)
else
	uimenu(file_menu,'Label','Show in Nautilus',...
		'Separator','on',...
		'Accelerator','H',...
		'Callback',@show_folder)
end
uimenu(file_menu,'Label','Open Notes...',...
	'Separator','on',...
	'Accelerator','N',...
	'Callback',@open_notes)
uimenu(file_menu,'Label','Close Catamaran',...
	'Separator','on',...
	'Accelerator','W',...
	'Callback',@close_fig)

% Edit menu.
edit_menu = uimenu(fig,'Label','Edit');
uimenu(edit_menu,'Label','Time Span...',...
	'Accelerator','T',...
	'Callback',@time_span_dialog)
uimenu(edit_menu,'Label','Preferences...',...
	'Accelerator','P',...
	'Separator','on',...
	'Callback',@prefs_dialog)

% Tools menu.
tools_menu = uimenu(fig,'Label','Tools');
uimenu(tools_menu,'Label','Detach plot',...
	'Callback',@launch_detach_plot)
uimenu(tools_menu,'Label','Plot spike waveforms',...
	'Separator','on',...
	'Callback',@launch_plot_spikes)
uimenu(tools_menu,'Label','Wavehist all',...
	'Callback',@launch_wavehist)
uimenu(tools_menu,'Label','Wavehist by cluster',...
	'Callback',@launch_wavehist_idx)
uimenu(tools_menu,'Label','Wavehist array',...
	'Callback',@launch_wavehist_array)
uimenu(tools_menu,'Label','1st order interval histogram array',...
	'Separator','on',...
	'Callback',@launch_1st_order_int_hist_array)
uimenu(tools_menu,'Label','Merge clusters',...
	'Separator','on',...
	'Callback',@launch_cluster_merge_tool)
uimenu(tools_menu,'Label','Sequence plots',...
	'Separator','on',...
	'Callback',@launch_sequence_plots)
uimenu(tools_menu,'Label','Time plots',...
	'Callback',@launch_time_plots)
uimenu(tools_menu,'Label','Stationarity plot',...
	'Callback',@launch_stationarity_plot)

% Figures menu.
windows_menu = uimenu(fig,'Label','Figures');
uimenu(windows_menu,'Label','Restore Default Position',...
	'Accelerator','R',...
	'Callback',@restore_default)
uimenu(windows_menu,'Label','Close All Child Figures',...
	'Separator','on',...
	'Accelerator','F',...
	'Callback',@close_figs)


fig_color = get(fig,'Color');
infocb = zeros(7,1);
ratingcb = zeros(7,1);
ratings = {'Good','Excellent','Multi-unit'};
num_ratings = length(ratings);
rating_strs = {};


% Space for scatter plots.
panel_bottom = 76;
panel_height = fig_pos(4) - panel_bottom;
panel_pos = [0,panel_bottom,fig_pos(3),panel_height];
panels = uipanel('Units','pixels',...
	'Position',panel_pos,...
	'BackgroundColor',fig_color,...
	'BorderType','none');
sep_line = annotation('line','Units','pixels',...
	'X',[0 fig_pos(3)],...
	'Y',[1 1]*panel_bottom,...
	'Color',fig_color*0.8);

% Rating tool.
infopanel_height = 240;
infopanel_topgap = 20;
infopanel_pos = [10,panel_height - infopanel_topgap - infopanel_height,...
	190,infopanel_height];
infopanels = uipanel(panels,...
	'Units','pixels',...
	'Position',infopanel_pos,...
	'title','% intervals < 1 ms',...
	'BackgroundColor','w',...
	'HighlightColor','k',...
	'BorderType','line');
for j = 1:7
	uicontrol(infopanels,...
		'Style','text',...
		'Units','pixels',...
		'Position',[2,infopanel_height-20-30*j,18,18],...
		'String',sprintf('%d',j),...
		'FontUnits','pixels',...
		'FontSize',9,...
		'BackgroundColor','w')
	infocb(j) = uicontrol(infopanels,...
		'Style','checkbox',...
		'Units','pixels',...
		'Position',[20,infopanel_height-20-30*j,80,20],...
		'FontSize',font_size + 1,...
		'BackgroundColor','w',...
		'Callback',{@pick_good_cell2,j});
	ratingcb(j) = uicontrol(infopanels,...
		'Style','pushbutton',...
		'Units','pixels',...
		'Position',[100,infopanel_height-25-30*j,85,30],...
		'String',ratings{1},...
		'Visible','off',...
		'Callback',{@set_rating,j});
end


% Context menu (right-click)
cm = uicontextmenu;
set(panels,'UIContextMenu',cm)
uimenu(cm,'Label','Detach plot',...
	'Callback',@launch_detach_plot)
uimenu(cm,'Label','Plot spike waveforms',...
	'Separator','on',...
	'Callback',@launch_plot_spikes)
uimenu(cm,'Label','Wavehist all',...
	'Callback',@launch_wavehist)
uimenu(cm,'Label','Wavehist by cluster',...
	'Callback',@launch_wavehist_idx)
uimenu(cm,'Label','Wavehist array',...
	'Callback',@launch_wavehist_array)
uimenu(cm,'Label','1st order interval histogram array',...
	'Separator','on',...
	'Callback',@launch_1st_order_int_hist_array)
uimenu(cm,'Label','Merge clusters',...
	'Separator','on',...
	'Callback',@launch_cluster_merge_tool)
uimenu(cm,'Label','Sequence plots',...
	'Separator','on',...
	'Callback',@launch_sequence_plots)
uimenu(cm,'Label','Time plots',...
	'Callback',@launch_time_plots)
uimenu(cm,'Label','Stationarity plot',...
	'Callback',@launch_stationarity_plot)

uimenu(cm,'Label','Export spikes, idxout',...
	'Separator','on',...
	'Callback',@export_spikes)

fig_color = get(fig,'Color');
use_choices = [1e3 2e3 5e3 10e3 20e3 50e3 100e3 200e3 inf];
use_spikes_value = 4;
num_spikes_max = use_choices(use_spikes_value);


% Set common properties for uicontrols.
popup_prop = struct('Style','popupmenu',...
	'Units','pixels',...
	'BackgroundColor','w');
button_prop = struct('Style','pushbutton',...
	'Units','pixels');
edit_prop = struct('Style','edit',...
	'Units','pixels',...
	'BackgroundColor','w');
text_prop = struct('Style','text',...
	'Units','pixels',...
	'HorizontalAlignment','left',...
	'BackgroundColor',fig_color);


% Create uicontrols.

% Number of events to use for exploration.
uicontrol(popup_prop,...
	'Position',[20 20 80 20],...
	'String',{'1k','2k','5k','10k','20k','50k','100k','200k','All'},...
	'Value',use_spikes_value,...
	'Callback',@handle_use_all_spikes)
uicontrol(text_prop,...
	'Position',[20 40 60 20],...
	'String','# Events')

% Outlier threshold.
frac_edit = uicontrol(edit_prop,...
	'Position',[120 18 80 24],...
	'String',sprintf('%.4g',frac),...
	'Callback',@set_frac);
uicontrol(text_prop,...
	'Position',[120 42 100 18],...
	'String','Outlier threshold')

% Clustering algorithm.
clus_alg_popup = uicontrol(popup_prop,...
	'Position',[220 20 100 20],...
	'String',clustering_algorithms,...
	'Value',clustering_alg_id,...
	'Callback',@set_clustering_algorithm);
uicontrol(text_prop,...
	'Position',[220 40 120 20],...
	'String','Clustering algorithm')

% Transformation.
method_popup = uicontrol(popup_prop,...
	'Position',[340 20 140 20],...
	'String',methods,...
	'Value',method_id,...
	'Callback',@set_method);
uicontrol(text_prop,...
	'Position',[340 40 120 20],...
	'String','Transformation')

% Number of clusters.
num_clusters_popups = uicontrol(popup_prop,...
	'Position',[500 20 60 20],...
	'String',{'1','2','3','4','5','6','7'},...
	'Value',1,...
	'Callback',@set_num_clusters,...
	'KeyPressFcn',@keypress);
uicontrol(text_prop,...
	'Position',[500 40 60 20],...
	'String','# Clusters')

% Compute button.
uicontrol(button_prop,...
	'Position',[580 15 80 45],...
	'String','Compute',...
	'Callback',@do_folder,...
	'KeyPressFcn',@keypress)

% Process All button.
uicontrol(button_prop,...
	'Position',[680 20 80 30],...
	'String','Process All',...
	'Callback',@process_all)

% Messages.
msg = uicontrol(text_prop,...
	'Position',[780 25 300 20],...
	'BackgroundColor','w',...
	'String','',...
	'Tag','messagebox');

if nargin == 0
	% Produce a blank display.
	T.X = zeros(0,4);
	T.merged.k = 1;
	T.merged.idx = [];
	T.merged.is_outlier = false(0,1);
	T.valid = true(0,1);
	display_clusters(T,panels)
else
	open_file([],[],true)
end

% Hide figure handle so subsequent plot commands open a new figure.
set(fig,'HandleVisibility','off')


%---------------------------- Nested functions ----------------------------

	function open_file(h,evt,flag) %#ok<INUSL>
		% flag = true indicates file name was passed in as argument.
		if nargin < 3 || ~flag
			start_dir = fullfile(ntt_dir,'*.ntt');
			[f,p] = uigetfile(start_dir,'Select a Neuralynx NTT file:');
			if isequal(f,0)
				return
			end
			file = f;
			ntt_dir = p;
			ntt_file_name = fullfile(ntt_dir,file);
		else
			[p,f,e] = fileparts(ntt_file_name);
			file = [f,e];
		end
		
		% Check if NTT file is empty.
		ntt = nttfile(ntt_file_name,'single',28);
		if ntt.size == 0
			errmsg = sprintf('%s contains no events.',file);
			uiwait(errordlg(errmsg,'NTT file error','modal'))
			return
		end
		
		% Set pointer to watch and update message.
		set(fig,'Pointer','watch')
		mymessage('Reading %s ...',file)
		
		% Set figure title and read sample events.
		set(fig,'Name',sprintf('%s (%s, %d events)',...
			this_app,file,ntt.size))
		ntt.seek(max(floor((ntt.size - num_spikes_max)/2),0))
		% [spikes.raw,timestamps] = ntt.read(num_spikes_max);
		[spikes.raw,timestamps] = ntt.read_distributed(num_spikes_max);
		ntt.close()
		spikes.timestamp = double(abs(timestamps).')/1000;
		
		% Determine scale of data.
		extrema = double([-min(spikes.raw(:)),max(spikes.raw(:)) + 1]);
		spike_bits = ceil(log2(max(extrema))) + 1;
		
		% Indicate that spikes have not been aligned.
		spikes.algorithm = -1;
				
		% Reset number of clusters to 1.
		set(num_clusters_popups,'Value',1)
		set_num_clusters(num_clusters_popups,[])
		
		% Diasable "Save As..." item in File menu.
		set(save_as_item,'Enable','off')
		
		% Display the new spikes with current settings.
		do_folder()
		
		% Set pointer back to arrow and clear message.
		set(fig,'Pointer','arrow')
		mymessage('')
	end


	function save_as(h,evt) %#ok<INUSD>
		% Specify cluster file, default is based on the NTT file.
		[unused,default_base] = fileparts(ntt_file_name);
		[f,p] = uiputfile('*.clu','Save Cluster File As:',...
			fullfile(ntt_dir,[default_base,'.clu']));
		if isequal(f,0)
			return
		end
		clu_file_name = f;
		clu_path = p;
		clu_file = fullfile(clu_path,clu_file_name);
		
		% Inform the user.
		mymessage('Writing %s ...',clu_file_name)
		
		% Open, write and close the file.
		fid = fopen(clu_file,'wt');
		fprintf(fid,'%% Number of clusters = %d\n',T.merged.k);
		fprintf(fid,'%% Time = %s\n',datestr(sessions.tetrode.Time));
		fprintf(fid,'%% Transformation algorithm = %s\n',T.method);
		fprintf(fid,'%% Clustering algorithm = %s\n',...
			T.clustering_algorithm);
		for clu = 1:T.merged.k
			fprintf(fid,'%% Cluster %d is %s\n',clu,rating_strs{clu});
		end
		for clu = T.merged.k+1:7
			fprintf(fid,'%% Cluster %d\n',clu);
		end
		fprintf(fid,'%d\n',idx_all);
		fclose(fid);
		
		% Reset message.
		mymessage('')
	end


	function show_folder(h,evt) %#ok<INUSD>
		if isempty(ntt_dir)
			this_ntt_dir = pwd;
		else
			this_ntt_dir = ntt_dir;
		end
		if ispc
			winopen(this_ntt_dir)
		elseif ismac
			cmd = sprintf('open "%s"',this_ntt_dir);
			[status,result] = system(cmd);
			if status
				uiwait(errordlg(result))
			end
		else
			cmd = sprintf('xdg-open "%s"',this_ntt_dir);
			[status,result] = system(cmd);
			if status
				uiwait(errordlg(result))
			end
		end
	end


	function close_fig(h,evt) %#ok<INUSD>
		question = 'Are you sure you want to quit?';
		response = questdlg(question,'Confirm','Yes',...
			'Cancel Quit','Cancel Quit');
		switch response
			case 'Yes'
				setpref(this_app,'fig_pos',get(fig,'Position'))
				delete(fig)
			case 'Cancel Quit'
				return
		end
	end


	function restore_default(h,evt) %#ok<INUSD>
		fig_pos_norm = [0.01 0.04 0.98 0.91];
		set(fig,'Units','normalized',...
			'Position',fig_pos_norm)
		set(fig,'Units','pixels')
		fig_pos = round(get(fig,'Position'));
		set(fig,'Position',fig_pos)
		setpref(this_app,'fig_pos',fig_pos)
	end


	function keypress(h,evt) %#ok<INUSL>
		switch evt.Key
			case 'return'
				do_folder()
			case 'downarrow'
				value = get(num_clusters_popups,'Value');
				value = min(value + 1,7);
				set(num_clusters_popups,'Value',value)
				set_num_clusters(num_clusters_popups,[])
			case 'uparrow'
				value = get(num_clusters_popups,'Value');
				value = max(value - 1,1);
				set(num_clusters_popups,'Value',value)
				set_num_clusters(num_clusters_popups,[])
		end
	end


	function resize(h,evt) %#ok<INUSD>
		fig_pos = get(fig,'Position');
		panel_height = fig_pos(4) - panel_bottom;
		panel_pos = [0,76,fig_pos(3),panel_height];
		set(panels,'Position',panel_pos)
		set(sep_line,'X',[0 fig_pos(3)])
		
		infopanel_pos = [10,...
			panel_height - infopanel_topgap - infopanel_height,...
			190,infopanel_height];
		set(infopanels,'Position',infopanel_pos)
	end


	function time_span_dialog(h,evt)
		save_time_span = time_span;
		ntt = nttfile(ntt_file_name,'single',28);
		ntt.seek(1);
		t1 = ntt.read_timestamps(1);
		ntt.seek(ntt.size - 1)
		t2 = ntt.read_timestamps(1);
		time_span = [t1 t2]/1e6;
		
		prompts = {'Beginning of time range of interest (seconds):',...
			'End of time range of interest (seconds):'};
		default = round(time_span*1e6)/1e6;
		default_str = {sprintf('%.11g',default(1)),...
			sprintf('%.11g',default(2))};
		result = inputdlg(prompts,'Time Range',1,default_str);
		if isempty(result)
			time_span = save_time_span;
			return
		end
		t = [sscanf(result{1},'%f'),sscanf(result{2},'%f')];
		if isvector(t) && length(t) == 2
			time_span = round(t*1e6)/1e6;
		else
			uiwait(errordlg('Incorrect input.'))
			time_span = save_time_span;
			return
		end
		
		% Limit time span of ntt file.
		ntt.limit_span(round(time_span*1e6))
		
		% Re-set figure title and read sample events.
		set(fig,'Pointer','watch')
		[p,f,e] = fileparts(ntt_file_name);
		file = [f,e];
		set(fig,'Name',sprintf('%s (%s, %d events)',...
			this_app,file,ntt.size))
		ntt.seek(max(floor((ntt.size - num_spikes_max)/2),0))
		% [spikes.raw,timestamps] = ntt.read(num_spikes_max);
		[spikes.raw,timestamps] = ntt.read_distributed(num_spikes_max);
		ntt.close()
		spikes.timestamp = double(abs(timestamps).')/1000;
		
		% Determine scale of data.
		extrema = double([-min(spikes.raw(:)),max(spikes.raw(:)) + 1]);
		spike_bits = ceil(log2(max(extrema))) + 1;
		
		% Indicate that spikes have not been aligned.
		spikes.algorithm = -1;
				
		% Reset number of clusters to 1.
		set(num_clusters_popups,'Value',1)
		set_num_clusters(num_clusters_popups,[])
		
		% Diasable "Save As..." item in File menu.
		set(save_as_item,'Enable','off')
		
		% Display the new spikes with current settings.
		do_folder()
		
		% Set pointer back to arrow and clear message.
		set(fig,'Pointer','arrow')
		mymessage('')
		
	end


	function prefs_dialog(h,evt) %#ok<INUSD>
		% Save prefs before manipulation.
		prefs_before = prefs;
		
		% Put prefs figure in center of main figure.
		parent_pos = get(fig,'Position');
		center = parent_pos(1:2) + parent_pos(3:4)/2;
		wid = 350;
		ht = 380;
		prefs_size = [wid ht];
		prefs_pos = [center - prefs_size/2,prefs_size];
		prefs_color = fig_color;
		prefs_fig = figure('Units','pixels',...
			'Position',prefs_pos,...
			'NumberTitle','off',...
			'Name','Preferences',...
			'WindowStyle','modal',...
			'Color',prefs_color,...
			'CloseRequestFcn',{@close_prefs,false},...
			'Visible','off',...
			'Resize','off');
		set(prefs_fig,'DefaultUIControlFontName',font_name,...
			'DefaultUIControlFontSize',font_size)
		
		% Create OK and Cancel buttons.
		prefs_group_0 = uipanel('Units','pixels',...
			'Position',[prefs_size(1)/2-70,20,140,30],...
			'BackgroundColor',prefs_color,...
			'BorderType','none');
		uicontrol('Parent',prefs_group_0,...
			'Style','pushbutton',...
			'Units','pixels',...
			'Position',[0 0 60 30],...
			'String','OK',...
			'Callback',{@close_prefs,true})
		uicontrol('Parent',prefs_group_0,...
			'Style','pushbutton',...
			'Units','pixels',...
			'Position',[80 0 60 30],...
			'String','Cancel',...
			'Callback',{@close_prefs,false})
		
		function close_prefs(h2,evt2,ok) %#ok<INUSL>
			if ~ok
				prefs = prefs_before;
			else
				setpref(this_app,'prefs',prefs)
			end
			delete(prefs_fig)
		end
		
		% Create AutoSave group.
		wid1 = wid - 40;
		ht1 = 130;
		prefs_group_1 = uipanel('Units','pixels',...
			'Position',[20 80 wid1 ht1],...
			'BackgroundColor',prefs_color,...
			'BorderType','none');
		uicontrol(prefs_group_1,...
			'Style','text',...
			'Units','pixels',...
			'Position',[0 ht1-20 wid1 20],...
			'HorizontalAlignment','left',...
			'BackgroundColor',prefs_color,...
			'FontUnits','pixels',...
			'FontSize',12,...
			'FontWeight','bold',...
			'String','AutoSave')
		uicontrol(prefs_group_1,...
			'Style','text',...
			'Units','pixels',...
			'Position',[0 50 wid-40 60],...
			'HorizontalAlignment','left',...
			'BackgroundColor',prefs_color,...
			'FontUnits','pixels',...
			'FontSize',10,...
			'String',['The AutoSave feature causes the output file ',...
			'to be saved automatically in the source folder.  A ',...
			'previously saved file will be overwritten.'])
		autosave_off = uicontrol(prefs_group_1,...
			'Style','radiobutton',...
			'Units','pixels',...
			'Position',[20 25 60 20],...
			'String','Off',...
			'BackgroundColor',prefs_color,...
			'Value',~prefs.AutoSave,...
			'Callback',{@handle_autosave,false});
		autosave_on = uicontrol(prefs_group_1,...
			'Style','radiobutton',...
			'Units','pixels',...
			'Position',[20 0 60 20],...
			'String','On',...
			'BackgroundColor',prefs_color,...
			'Value',prefs.AutoSave,...
			'Callback',{@handle_autosave,true});
		
		function handle_autosave(h2,evt2,value) %#ok<INUSL>
			if value
				set(autosave_off,'Value',false)
			else
				set(autosave_on,'Value',false)
			end
			prefs.AutoSave = value;
		end
		
		
		% Default input folder.
		wid2 = wid - 40;
		ht2 = 110;
		prefs_group_2 = uipanel('Units','pixels',...
			'Position',[20 250 wid2 ht2],...
			'BackgroundColor',prefs_color,...
			'BorderType','none');
		uicontrol(prefs_group_2,...
			'Style','text',...
			'Units','pixels',...
			'Position',[0 ht2-20 wid2 20],...
			'HorizontalAlignment','left',...
			'BackgroundColor',prefs_color,...
			'FontUnits','pixels',...
			'FontSize',12,...
			'FontWeight','bold',...
			'String','Default Input Folder')
		uicontrol(prefs_group_2,...
			'Style','text',...
			'Units','pixels',...
			'Position',[0 50 wid-40 40],...
			'HorizontalAlignment','left',...
			'BackgroundColor',prefs_color,...
			'FontUnits','pixels',...
			'FontSize',10,...
			'String',['The default input folder is the initial ',...
			'location presented when opening NTT files.'])
		default_folder_edit = uicontrol(prefs_group_2,...
			'Style','edit',...
			'Units','pixels',...
			'Position',[0 0 wid2-100 30],...
			'HorizontalAlignment','left',...
			'BackgroundColor','w',...
			'FontUnits','pixels',...
			'FontSize',10,...
			'String',prefs.DefaultFolder,...
			'Callback',@handle_folder_edit);
		uicontrol(prefs_group_2,...
			'Style','pushbutton',...
			'Units','pixels',...
			'Position',[wid2-80 0 80 30],...
			'String','Browse...',...
			'Callback',@handle_browse)
		
		function handle_folder_edit(h,evt) %#ok<INUSD>
			prefs.DefaultFolder = get(h,'String');
		end
		
		function handle_browse(h,evt) %#ok<INUSD>
			p = uigetdir(prefs.DefaultFolder,'Select Default Folder:');
			if isequal(p,0)
				return
			end
			prefs.DefaultFolder = p;
			set(default_folder_edit,'String',p)
		end
		
		
		% Reveal prefs figure.
		set(prefs_fig,'Visible','on')
		
	end


	function pick_good_cell2(h,evt,clus) %#ok<INUSL>
		if clus > T.merged.k
			set(h,'Value',false)
			return
		end
		T.isgood(clus) = logical(get(h,'Value'));
		T.rating(clus) = 1;
		cl = find(T.isgood);
		sessions.tetrode.Good.clus = cl;
		sessions.tetrode.Good.num = histc(T.merged.idx,cl);
		sessions.tetrode.Good.rating = T.isexcellent(cl);
		set(infocb(clus),'Value',T.isgood(clus))
		if T.isgood(clus)
			set(ratingcb(clus),'Visible','on',...
				'String',ratings{T.rating(clus)})
		else
			set(ratingcb(clus),'Visible','off')
			T.isexcellent(clus) = false;
			T.rating(clus) = NaN;
		end
	end


	function set_rating(h,evt,clus) %#ok<INUSL>
		T.rating(clus) = rem(T.rating(clus),num_ratings) + 1;
		set(h,'String',ratings{T.rating(clus)})
		lut = [0 1 -1];
		sessions.tetrode.Good.rating = lut(T.rating(T.isgood));
	end


	function mymessage(varargin)
		str = sprintf(varargin{:});
		set(msg,'String',str)
		drawnow
	end


	function read_files()
		% Return if no file has been selected yet.
		if isempty(ntt_file_name)
			return
		end
		
		% Set pointer to watch.
		set(fig,'Pointer','watch')
		drawnow
		
		[p,f,ext] = fileparts(ntt_file_name);
		file = [f,ext];
		mymessage('Reading %s ...',file)
		ntt = nttfile(ntt_file_name,'single',28);
		ntt.seek(max(floor((ntt.size - num_spikes_max)/2),0))
		% [spikes.raw,timestamps] = ntt.read(num_spikes_max);
		[spikes.raw,timestamps] = ntt.read_distributed(num_spikes_max);
		ntt.close()
		spikes.timestamp = double(abs(timestamps).')/1000;
		extrema = double([-min(spikes.raw(:)),max(spikes.raw(:)) + 1]);
		spike_bits = ceil(log2(max(extrema))) + 1;
		
		spikes.algorithm = -1;
		
		% num_events_read = size(spikes.raw,3);
		mymessage('')
		
		% Set pointer back to arrow.
		set(fig,'Pointer','arrow')
	end


	function do_folder(h,evt) %#ok<INUSD>
		% Set pointer to watch.
		set(fig,'Pointer','watch')
		drawnow
		
		% Clear message.
		mymessage('')
		
		% Set sessions structure with current values of some parameters.
		sessions.AlignSpikes = align_spikes;
		sessions.Frac = frac;
		
		% Clear panel.
		delete(findobj(panels,'Type','axes'))
		
		% Skip tetrode if there are not enough spikes.
		if size(spikes.raw,3) < 100
			return
		end
		
		% Set time stamp and method.
		sessions.tetrode.Time = now;
		sessions.tetrode.Method = methods{method_id};
		
		sessions.tetrode.ClusteringAlgorithm = ...
			clustering_algorithms{clustering_alg_id};
		
		% Check how many clusters to set.  If this parameter has not
		% been set (indicated by being NaN) set it to 1.
		num_clust = sessions.tetrode.NumClusters;
		if isnan(num_clust)
			num_clust = 1;
		end
		set(num_clusters_popups,'Value',num_clust)
		sessions.tetrode.NumClusters = num_clust;
		
		% Mark unclipped waveforms as valid.
		valid = unclipped(spikes.raw,spike_bits);
		
		% Align the spike waveforms.
		[spikes,valid] = alignspikes(spikes,valid,sessions.AlignSpikes);
		
		% Skip tetrode if no spikes are valid.
		if sum(valid) == 0
			return
		end
		
		% Transform raw spike waveforms into points in feature space.
		make_new_seed = true;
		T = transform_spikes(T,spikes,valid,sessions.tetrode.Method,...
			make_new_seed);
		
		% Cluster the feature space points into num_clust clusters.
		T = cluster_trans(T,make_new_seed,sessions.Frac,num_clust,...
			sessions.tetrode.ClusteringAlgorithm);
		
		% Apply merges.
		T = apply_merges(T);
		num_clust = T.merged.k;
		
		% Iniialize attributes.
		T.isgood = false(1,num_clust);
		T.isexcellent = false(1,num_clust);
		T.rating = NaN(1,num_clust);
		
		% Compute percent of 1st order intervals < 1 ms.
		sessions.tetrode.smallint = percent_small_intervals(timestamps,...
			num_clust,T.merged.idx0);
		
		% Display the clusters in the main GUI.
		display_clusters(T,panels)
		
		% Display the percent < 1 ms.
		smallint = sessions.tetrode.smallint;
		set(infocb,'String','','Value',false)
		set(ratingcb,'Value',false,'CData',[],'Visible','off')
		% To check infocb automatically, uncomment following line.
		% T.isgood = smallint <= 0.5;
		for clu = 1:num_clust
			set(infocb(clu),'String',sprintf(' %.2g',smallint(clu)),...
				'Value',T.isgood(clu))
			if T.isgood(clu)
				set(ratingcb(clu),'Visible','on')
			else
				set(ratingcb(clu),'Visible','off','Value',false,'CData',[])
			end
		end
		
		% Set sessions structure with these computed values.
		sessions.tetrode.NumClusters = T.raw.k;
		sessions.tetrode.Seed = T.seed;
		sessions.tetrode.OutlierThreshold = T.outlier_threshold;
		sessions.tetrode.Merges = T.merges;
		sessions.tetrode.Good.clus = find(T.isgood);
		sessions.tetrode.Good.num = histc(T.merged.idx,find(T.isgood));
		sessions.tetrode.Good.rating = T.isexcellent(T.isgood);
				
		% Set pointer back to arrow.
		set(fig,'Pointer','arrow')
	end


	function open_notes(h,evt) %#ok<INUSD>
		notes_file = fullfile(ntt_dir,'Notes.txt');
		if ~exist(notes_file,'file')
			notes_fid = fopen(notes_file,'wt');
			fclose(notes_fid);
		end
		notes_fig = figure('WindowStyle','modal',...
			'NumberTitle','off',...
			'Name','Notes',...
			'CloseRequestFcn',@save_notes);
		notes_fid = fopen(notes_file,'rt');
		notes_text = fread(notes_fid,[1 inf],'*char');
		fclose(notes_fid);
		notes_edit = uicontrol('Style','edit',...
			'Units','normalized',...
			'Position',[0 0 1 1],...
			'String',notes_text,...
			'HorizontalALignment','left',...
			'FontName','Monospaced',...
			'FontSize',10,...
			'Max',2,...
			'BackgroundColor','w');
		
		function save_notes(h,evt) %#ok<INUSD>
			set(notes_fig,'Visible','off')
			drawnow
			set(notes_fig,'Visible','on')
			
			notes_text = cellstr(get(notes_edit,'String'));
			notes_fid = fopen(notes_file,'wt');
			fprintf(notes_fid,'%s\n',notes_text{:});
			fclose(notes_fid);
			delete(notes_fig)
		end
		
	end


	function set_frac(h,evt) %#ok<INUSD>
		str = get(h,'String');
		frac = sscanf(str,'%f');
		set(frac_edit,'String',sprintf('%.4g',frac))
	end


	function set_clustering_algorithm(h,evt) %#ok<INUSD>
		clustering_alg_id = get(h,'Value');
	end


	function set_method(h,evt) %#ok<INUSD>
		method_id = get(h,'Value');
	end


	function launch_detach_plot(h,evt)  %#ok<INUSD>
		new_fig = figure('Tag','cluster gui figure');
		display_clusters(T,new_fig)
	end


	function launch_plot_spikes(h,evt) %#ok<INUSD>
		clus = unique(T.merged.idx);
		for clu = clus(:).'
			in_clu = T.merged.idx == clu;
			sub_spikes = spikes.aligned(:,:,in_clu);
			switch 1
				case 1
					% Sort by distance from cluster center.
					[unused,order] = sort(T.merged.D(in_clu));
				case 2
					% Sort by energy.
					e = permute(sum(sum(sub_spikes.^2,1),2),[3 2 1]);
					[unused,order] = sort(e,'descend');
			end
			if clu == 0
				label = sprintf('Cluster %d (clipped waveforms)',clu);
			elseif clu > T.merged.k
				label = sprintf('Cluster %d (outliers)',clu);
			else
				label = sprintf('Cluster %d',clu);
			end
			plot_spikes(sub_spikes(:,:,order),label,spike_bits)
		end
	end


	function launch_wavehist(h,evt) %#ok<INUSD>
		label = 'All waveforms';
		figure('Name',label,'Tag','cluster gui figure')
		good = T.merged.idx > 0;
		wavehist(spikes.aligned(:,:,good),[],false,spike_bits)
	end


	function launch_wavehist_idx(h,evt) %#ok<INUSD>
		clus = unique(T.merged.idx);
		for clu = clus(:).'
			in_clu = T.merged.idx == clu;
			sub_spikes = spikes.aligned(:,:,in_clu);
			label = sprintf('Cluster %d, N = %d',clu,sum(in_clu));
			figure('Name',label,'Tag','cluster gui figure')
			wavehist(sub_spikes,[],true,spike_bits)
		end
	end


	function launch_wavehist_array(h,evt) %#ok<INUSD>
		label = sprintf('N = %d',length(T.merged.idx));
		figure('Name',label,'Tag','cluster gui figure')
		wavehist_array(spikes.aligned,T.merged.idx,T.merged.is_outlier,...
			@pick_good_cell,T.isgood,spike_bits)
		
		function pick_good_cell(h,evt,clus) %#ok<INUSL>
			T.isgood(clus) = logical(get(h,'Value'));
			cl = find(T.isgood);
			sessions.tetrode.Good.clus = cl;
			sessions.tetrode.Good.num = histc(T.merged.idx,cl);
			sessions.tetrode.Good.rating = T.isexcellent(cl);
			set(infocb(clus),'Value',T.isgood(clus))
			if T.isgood(clus)
				T.rating(clus) = 1;
				set(ratingcb(clus),'Visible','on',...
					'String',ratings{T.rating(clus)})
			else
				set(ratingcb(clus),'Visible','off')
				T.isexcellent(clus) = false;
				T.rating(clus) = NaN;
			end
		end
		
	end


	function launch_1st_order_int_hist_array(h,evt) %#ok<INUSD>
		% Display 1st order interval histograms for spikes within and
		% across clusters.
		tmax = 5; % ms
		bin_size = 0.2; % ms
		tsmall = 1; % ms
		
		bin_edges = 0:bin_size:tmax;
		
		% N.B. Time stamp segments are marked by negating the time stamp of
		% the first spike in each segment;
		ts = abs(timestamps)/1000;
		seg = cumsum(timestamps < 0);
		idx = T.merged.idx0;
		
		figure('Tag','cluster gui figure')
		num_clust = T.merged.k;
		for cl1 = 1:num_clust
			for cl2 = 1:num_clust
				iscl1 = idx == cl1;
				iscl2 = idx == cl2;
				ts1 = ts(iscl1);
				seg1 = seg(iscl1);
				ts2 = ts(iscl2);
				seg2 = seg(iscl2);
				intervals = NaN(1,length(ts1));
				cnt = 0;
				for i = 1:length(ts1)
					first = find(ts2 > ts1(i) & seg2 == seg1(i),1,'first');
					if ~isempty(first)
						cnt = cnt + 1;
						intervals(cnt) = ts2(first) - ts1(i);
					end
				end
				if cnt == 0
					continue
				end
				int_hist2 = histc(intervals,bin_edges);
				nsmall = sum(intervals <= tsmall);
				percent = 100*nsmall/cnt;
				
				% Create axes and make bar plot.
				ax = subplot(num_clust,num_clust,(cl1 - 1)*num_clust + cl2);
				bh = bar(bin_edges,int_hist2,'histc');
				set(bh,'FaceColor',[0.2 0.5 0.8])
				
				% Annotate histogram.
				title(ax,sprintf('(%d\\rightarrow%d) %d [%.2g%%]',...
					cl1,cl2,nsmall,percent))
				set(ax,'XLim',[0 tmax],'Xtick',0:tmax,'FontSize',9)
				if cl1 == num_clust
					xlabel(ax,'1^{st} Order Interval (ms)')
				else
					set(ax,'XTickLabel','')
				end
			end
		end
	end


	function launch_cluster_merge_tool(h,evt) %#ok<INUSD>
		wid = 650;
		ht = 500;
		if isempty(cmfig)
			% Center merge tool figure on main figure.
			parent_pos = get(fig,'Position');
			center = parent_pos(1:2) + parent_pos(3:4)/2;
			cmfig_size = [wid ht];
			cmfig_pos = [center - cmfig_size/2,cmfig_size];
			cmfig = figure('Position',cmfig_pos,...
				'NumberTitle','off',...
				'Toolbar','none',...
				'Menubar','none',...
				'Name','Cluster Merge Tool',...
				'Tag','Cluster merge tool',...
				'CloseRequestFcn',@close_cmfig);
		else
			% Bring existing figure to the front.
			figure(cmfig)
			return
		end
		cmfig_color = get(cmfig,'Color');
		
		table_data1 = num2cell(T.raw.ce);
		table_data1(logical(tril(ones(T.raw.k)))) = {[]};

		col_width = floor((wid - 34)/7);
		col_names = {'1|Red','2|Green','3|Blue',...
			'4|Yellow','5|Purple','6|Orange','7|Violet'};
		row_names = {'1-Red','2-Green','3-Blue',...
			'4-Yellow','5-Purple','6-Orange','7-Violet'};
		uicontrol('Style','text',...
			'Position',[0 ht-20 300 20],...
			'String',' Original Cluster Entanglement Matrix',...
			'HorizontalAlignment','left',...
			'FontSize',10,...
			'BackgroundColor',cmfig_color)
		ce_table1 = uitable('Position',[0 ht-20-183 wid 183],...
			'Data',table_data1,...
			'ColumnWidth',{col_width},...
			'ColumnName',col_names(1:size(table_data1,2)),...
			'RowName',row_names(1:size(table_data1,2)),...
			'FontSize',12,...
			'CellSelectionCallback',@table_sel);
		
		ce = T.merged.ce;
		num_clusters = T.merged.k;
		table_data2 = num2cell(ce);
		table_data2(logical(tril(ones(num_clusters)))) = {[]};
		uicontrol('Style','text',...
			'Position',[0 ht-50-183 300 20],...
			'String',' Modified Cluster Entanglement Matrix',...
			'HorizontalAlignment','left',...
			'FontSize',10,...
			'BackgroundColor',cmfig_color)
		ce_table2 = uitable('Position',[0 ht-50-2*183 wid 183],...
			'Data',table_data2,...
			'ColumnWidth',{col_width},...
			'ColumnName',col_names(1:size(table_data2,2)),...
			'RowName',row_names(1:size(table_data2,2)),...
			'FontSize',12,...
			'Enable','inactive');
		
		uicontrol('Style','pushbutton',...
			'Position',[250 30 150 30],...
			'String','Merge Selected Clusters',...
			'Callback',@merge_selected)
		
		uicontrol('Style','pushbutton',...
			'Position',[400 ht-20 100 20],...
			'String','Unselect All',...
			'Callback',@unselect_all)
		
		set(cmfig,'HandleVisibility','off')
		
		function table_sel(h,evt) %#ok<INUSL>
			T.merges = num2cell(evt.Indices,2);
		end
		
		function close_cmfig(h,evt) %#ok<INUSD>
			delete(cmfig)
			cmfig = [];
		end
		
		function merge_selected(h,evt) %#ok<INUSD>
			T = apply_merges(T);
			num_clusters = T.merged.k;
			
			table_data2 = num2cell(T.merged.ce);
			table_data2(logical(tril(ones(num_clusters)))) = {[]};
			set(ce_table2,'Data',table_data2,...
				'ColumnName',col_names(1:size(table_data2,2)),...
				'RowName',row_names(1:size(table_data2,2)))
			
			display_clusters(T,panels)
			
			sessions.tetrode.Merges = T.merges;
			
			% Compute percent of 1st order intervals < 1 ms.
			sessions.tetrode.smallint = ...
				percent_small_intervals(timestamps,...
				num_clusters,T.merged.idx0);
			
			% Display the percent < 1 ms.
			smallint = sessions.tetrode.smallint;
			set(infocb,'String','','Value',false)
			set(ratingcb,'Value',false,'CData',[],'Visible','off')
			% To check infocb automatically, uncomment following line.
			% T(tetrode).isgood = smallint <= 0.5;
			for clu = 1:num_clusters
				set(infocb(clu),...
					'String',sprintf('%.2g',smallint(clu)),...
					'Value',T.isgood(clu))
				if T.isgood(clu)
					set(ratingcb(clu),'Visible','on')
				else
					set(ratingcb(clu),'Visible','off',...
						'Value',false,'CData',[])
				end
			end
			
		end
		
		function unselect_all(h,evt) %#ok<INUSD>
			set(ce_table1,'Data',cell(size(table_data1)),...
				'Data',table_data1)
			T.merges = {};
		end
		
	end


	function launch_sequence_plots(h,evt) %#ok<INUSD>
		figure('Name','Sequence plots','Tag','cluster gui figure')
		
		plot_colors = [255 0 0; % Red
			0 255 0;              % Lime
			70 130 180;           % SteelBlue
			255 255 0;            % Yellow
			85 0 130;             % Purple
			255 140 0;            % DarkOrange
			238 130 238]/255;     % Violet
		
		num_plots = size(T.X,2);
		for plt = 1:num_plots
			ax = subplot(num_plots,1,plt);
			for kk = 1:T.merged.k
				this = T.merged.idx == kk;
				h = plot(find(this),T.X(this,plt),'s-');
				set(h,'Color',plot_colors(kk,:),...
					'MarkerFaceColor',plot_colors(kk,:),...
					'MarkerSize',2)
				hold on
			end
			set(ax,'Color','k')
			hold off
		end
		zoom xon
	end


	function launch_time_plots(h,evt) %#ok<INUSD>
		figure('Name','Time plots','Tag','cluster gui figure')
		% wavehist_array(spikes(tet).aligned,T(tet).merged.idx,...
		% T(tet).merged.is_outlier,@pick_good_cell,T(tet).isgood)
		
		plot_colors = [255 0 0; % Red
			0 255 0;              % Lime
			70 130 180;           % SteelBlue
			255 255 0;            % Yellow
			85 0 130;             % Purple
			255 140 0;            % DarkOrange
			238 130 238]/255;     % Violet
		
		num_plots = size(T.X,2);
		for plt = 1:num_plots
			ax = subplot(num_plots,1,plt);
			for kk = 1:T.merged.k
				this = T.merged.idx == kk;
				h = plot(abs(timestamps(this)),T.X(this,plt),'s');
				set(h,'Color',plot_colors(kk,:),...
					'MarkerFaceColor',plot_colors(kk,:),...
					'MarkerSize',2)
				hold on
			end
			set(ax,'Color','k')
			hold off
		end
		zoom xon
	end


	function launch_stationarity_plot(h,evt) %#ok<INUSD>
		plot_colors = [255 0 0; % Red
			0 255 0;              % Lime
			99 184 255;           % SteelBlue
			255 255 0;            % Yellow
			85 0 130;             % Purple
			255 140 0;            % DarkOrange
			238 130 238]/255;     % Violet
		[coeff1,Y1] = princomp(T.X(T.valid,:));
		tt = abs(timestamps(T.valid)');
		tt = (tt - tt(1))*1e-6;
		Z1 = [tt,zscore(Y1)];
		this_fig = figure('Name','Stationarity',...
			'Tag','cluster gui figure');
		whitebg(this_fig,'k')
		for clu = 1:T.merged.k
			this = T.merged.idx(T.valid) == clu;
			plot3(Z1(this,1),Z1(this,2),Z1(this,3),'s',...
				'Color',plot_colors(clu,:),...
				'MarkerFaceColor',plot_colors(clu,:),...
				'MarkerSize',2)
			hold on
		end
		hold off
		
		set(gca,'Xtick',[],'YTick',[],'ZTick',[])
		view(-20,20)
		axis tight
		axis vis3d
		view(3)
		xlabel('Time')
		ylabel('First PC')
		zlabel('Second PC')
		rotate3d on
	end


	function export_spikes(h,evt) %#ok<INUSD>
		assignin('base','spikes',spikes)
		assignin('base','T',T)
		assignin('base','ts',timestamps')
	end


	function process_all(h,evt) %#ok<INUSD>
		
		this = sessions;
		
		stats = struct('mean',[],'std',[]);
		clusters = struct('num_clust',[],'method','',...
			'clustering_algorithm','','idx',[],'good',[],'rating',[]);
		
		stats1 = struct('sum',[],'sumsq',[],'n',[]);
		
		[ntt_path,ntt_base,ntt_ext] = fileparts(ntt_file_name);
		ntt_fn = [ntt_base,ntt_ext];
		ntt = nttfile(ntt_file_name,'single',28);
		% Abort if file doesn't have even one event.
		if ntt.size < 1
			ntt.close()
			return
		end
		block_size = 10000;
		num_blocks = ceil(ntt.size/block_size);
		idx_all = zeros(ntt.size,1);
		start = 1;
		
		num_clust = this.tetrode.NumClusters;
		
		% Abort if the tetrode hasn't been processed yet.
		if isnan(num_clust)
			ntt.close()
			return
		end
		
		% Delete contents of panel.
		delete(findobj(panels,'Type','axes'))
		
		% Set main GUI items to reflect this session/tetrode.
		frac = this.Frac;
		set(frac_edit,'String',sprintf('%.4g',frac))
		align_spikes = this.AlignSpikes;
		
		clustering_alg_id = find(strcmp( ...
			this.tetrode.ClusteringAlgorithm,clustering_algorithms));
		set(clus_alg_popup,'Value',clustering_alg_id)
		
		method_id = find(strcmp(this.tetrode.Method,methods));
		set(method_popup,'Value',method_id)
		
		set(num_clusters_popups,'Value',this.tetrode.NumClusters)
		drawnow
		
		% Copy values from sessions array into T(tetrode).
		T.num_clusters = this.tetrode.NumClusters;
		T.seed = this.tetrode.Seed;
		T.outlier_threshold = this.tetrode.OutlierThreshold;
		T.merges = this.tetrode.Merges;
		
		for block = 1:num_blocks
			
			mymessage('Reading %s, block %d/%d ...',ntt_fn,...
				block,num_blocks)
			spikes.raw = ntt.read(block_size);
			spikes.algorithm = -1;
			this_num_events = size(spikes.raw,3);
			
			mymessage('Clustering block %d/%d ...',block,num_blocks)
			
			% Mark unclipped waveforms as valid.
			valid = unclipped(spikes.raw,spike_bits);
			
			% Align the spike waveforms.
			[spikes,valid] = alignspikes(spikes,valid,this.AlignSpikes);
			
			% Transform raw spike waveforms into points in feature space.
			make_new_seed = false;
			T = transform_spikes(T,spikes,valid,this.tetrode.Method,...
				make_new_seed);
			
			% Cluster the feature space points into num_clust clusters.
			T = cluster_trans(T,make_new_seed,this.Frac,num_clust,...
				this.tetrode.ClusteringAlgorithm);
			
			% Apply merges.
			T = apply_merges(T);
			
			% Display the clusters in the main GUI.
			display_clusters(T,panels)
			
			% Add current idx to idx_all and increment pointer.
			idx_all(start:(start + this_num_events - 1)) = T.merged.idx;
			start = start + this_num_events;
			
			if block == 1
				[ns,nw,ne] = size(spikes.aligned); %#ok<NASGU>
				nc = T.merged.k + 1;
				stats1.sum = zeros(ns,nw,nc);
				stats1.sumsq = zeros(ns,nw,nc);
				stats1.n = zeros(1,1,nc);
			end
			
			for clu = 0:T.merged.k
				stats1.sum(:,:,clu+1) = stats1.sum(:,:,clu+1) + ...
					double(sum(spikes.aligned(:,:,T.merged.idx == clu),3));
				stats1.sumsq(:,:,clu+1) = stats1.sumsq(:,:,clu+1) + ...
					double(sum(spikes.aligned(:,:,...
					T.merged.idx == clu).^2,3));
				stats1.n(clu+1) = stats1.n(clu+1) + ...
					sum(T.merged.idx == clu);
			end
			
			mymessage('')
			
		end
		
		ntt.close()
		
		clusters.idx = idx_all;
		clusters.num_clust = num_clust;
		clusters.method = this.tetrode.Method;
		clusters.clustering_algorithm = this.tetrode.ClusteringAlgorithm;
		clusters.good = this.tetrode.Good.clus;
		clusters.rating = this.tetrode.Good.rating;
		
		stats.mean = bsxfun(@rdivide,stats1.sum,stats1.n);
		stats.std = sqrt(bsxfun(@rdivide,stats1.sumsq - ...
			bsxfun(@rdivide,stats1.sum.^2,stats1.n),stats1.n - 1));

		rating_choices = {'Good','Excellent','Multi-unit','unrated'};
		rating = T.rating;
		rating(isnan(rating)) = 4;
		rating_strs = rating_choices(rating);
		
		% Enable "Save As..." item in File menu.
		set(save_as_item,'Enable','on')
		
		if prefs.AutoSave
			clu_file_name = [ntt_base,'.clu'];
			clu_file = fullfile(ntt_path,clu_file_name);
			mymessage('Writing %s ...',clu_file_name)
			fid = fopen(clu_file,'wt');
			fprintf(fid,'%% Number of clusters = %d\n',T.merged.k);
			fprintf(fid,'%% Time = %s\n',datestr(sessions.tetrode.Time));
			fprintf(fid,'%% Transformation algorithm = %s\n',T.method);
			fprintf(fid,'%% Clustering algorithm = %s\n',...
				T.clustering_algorithm);
			for clu = 1:T.merged.k
				fprintf(fid,'%% Cluster %d is %s\n',clu,rating_strs{clu});
			end
			for clu = T.merged.k+1:7
				fprintf(fid,'%% Cluster %d\n',clu);
			end
			fprintf(fid,'%d\n',idx_all);
			fclose(fid);
		end
		
		
		mymessage('')
		
		% Read in the original distribution of spikes so GUI will be
		% intuitive.
		read_files()
		
	end


	function handle_use_all_spikes(h,evt) %#ok<INUSD>
		use_spikes_value = get(h,'Value');
		num_spikes_max = use_choices(use_spikes_value);
		read_files()
	end


	function set_num_clusters(h,evt) %#ok<INUSD>
		value = get(h,'Value');
		sessions.tetrode.NumClusters = value;
	end


	function close_figs(h,evt) %#ok<INUSD>
		figs = findobj('Type','figure','Tag','cluster gui figure');
		delete(figs)
	end


end % function catamaran


% <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> %
%                                                                         %
%                            Subfunctions                                 %
%                                                                         %
% <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> <> %


%--------------------------------------------------------------------------
function valid = unclipped(spikes,nbits)
low = -2.^(nbits - 1);
high = 2.^(nbits - 1) - 1;
valid = permute(all(all(spikes < high & spikes > low,1),2),[3 1 2]);
end



%--------------------------------------------------------------------------
function [spikes,valid] = alignspikes(spikes,valid,algorithm)
if algorithm == spikes.algorithm
	return
end

switch algorithm
	case 0
		spikes.aligned = spikes.raw(4:23,:,:);
	case 1
% 		spikes.aligned = align_spikes(spikes.raw,'linear');
	case 2
% 		spikes.aligned = align_spikes(spikes.raw,'spline');
	case 3
% 		spikes.aligned = align_spikes(spikes.raw,'pchip');
	case 4
		spikes.aligned = align_spikes2(spikes.raw,'linear');
% 		[spikes.aligned,bad] = align_spikes2(spikes.raw,'linear');
% 		valid = valid & ~bad;
end
spikes.algorithm = algorithm;
end



%--------------------------------------------------------------------------
function T = transform_spikes(T,spikes,valid,method,make_new_seed)

T.valid = valid;
T.method = method;
[spike_length,num_wires,num_events] = size(spikes.aligned);

method2 = method;

switch method2
	case 'PCA all wires'
		% Compute the principal components of all responses from all 4
		% wires together, keep a specified number of them to do clustering
		% and put those into all_scores.
		
		% Number of principal components to keep (total).
		T.num_comp = 4;
		
		% Compute PCA and fill appropriate rows of scores.
		x = reshape(spikes.aligned(:,:,T.valid),spike_length*num_wires,[])';
		scores = zeros(num_events,spike_length*num_wires,class(x));
		if make_new_seed
			T.seed.Xmean = mean(x,1);
			[T.seed.PCA_coeff,scores(T.valid,:)] = princomp(x);
		else
			scores(T.valid,:) = bsxfun(@minus,x,T.seed.Xmean) * ...
				T.seed.PCA_coeff;
		end
		T.X = scores(:,1:T.num_comp);
		
	case 'RPS'
		% Compute response on each wire to a simple edge filter and use
		% those 4 values.  PCA is not strictly necessary.
		
		% Number of principal components to keep (total).
		T.num_comp = 4;
		
		pattern = [1 1 1 1 0 -1 -1 -1 -1]';
		kernel = pattern(end:-1:1)/8;
		x = [max(conv2(permute(spikes.aligned(:,1,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,2,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,3,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,4,:),[1 3 2]),kernel,'valid')).'];
		
		T.X = zeros(num_events,4,class(x));
		T.X(T.valid,:) = x(T.valid,:);
		
	case 'RPS-'
		% Compute response on each wire to a simple edge filter and use
		% those 4 values.  PCA is not strictly necessary.
		
		% Number of principal components to keep (total).
		T.num_comp = 4;
		
		pattern = -[1 1 1 1 0 -1 -1 -1 -1]';
		kernel = pattern(end:-1:1)/8;
		x = [max(conv2(permute(spikes.aligned(:,1,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,2,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,3,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,4,:),[1 3 2]),kernel,'valid')).'];
		
		T.X = zeros(num_events,4,class(x));
		T.X(T.valid,:) = x(T.valid,:);
		
	case 'RPS2'
		% Number of components to keep (total).
		T.num_comp = 4;
		
		pattern = [1 1 1 1 0 -1 -1 -1 -1]';
		kernel = pattern(end:-1:1)/8;
		
		sp = permute(spikes.aligned,[1 3 2]);
		sk = cat(3,conv2(sp(:,:,1),kernel,'valid'),...
			conv2(sp(:,:,2),kernel,'valid'),...
			conv2(sp(:,:,3),kernel,'valid'),...
			conv2(sp(:,:,4),kernel,'valid'));
		[xp,ip] = max(mean(sk,3),[],1);
		x = sk(sub2ind(size(sk),repmat(ip',[1 4]),...
			repmat((1:num_events)',[1 4]),...
			repmat((1:4)',[1 num_events])'));
		
		T.X = zeros(num_events,4,class(x));
		T.X(T.valid,:) = x(T.valid,:);
		
	case 'RPS2-'
		% Number of components to keep (total).
		T.num_comp = 4;
		
		pattern = -[1 1 1 1 0 -1 -1 -1 -1]';
		kernel = pattern(end:-1:1)/8;
		
		sp = permute(spikes.aligned,[1 3 2]);
		sk = cat(3,conv2(sp(:,:,1),kernel,'valid'),...
			conv2(sp(:,:,2),kernel,'valid'),...
			conv2(sp(:,:,3),kernel,'valid'),...
			conv2(sp(:,:,4),kernel,'valid'));
		[xp,ip] = max(mean(sk,3),[],1);
		x = sk(sub2ind(size(sk),repmat(ip',[1 4]),...
			repmat((1:num_events)',[1 4]),...
			repmat((1:4)',[1 num_events])'));
		
		T.X = zeros(num_events,4,class(x));
		T.X(T.valid,:) = x(T.valid,:);
		
	case 'RPS/PCA'
		% Compute response on each wire to a simple edge filter and use
		% those 4 values.  PCA is not strictly necessary.
		
		% Number of principal components to keep (total).
		T.num_comp = 4;
		
		pattern = [1 1 1 1 0 -1 -1 -1 -1]';
		kernel = pattern(end:-1:1)/8;
		x = [max(conv2(permute(spikes.aligned(:,1,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,2,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,3,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,4,:),[1 3 2]),kernel,'valid')).'];
		
		if make_new_seed
			T.seed.Xmean = mean(x(T.valid,:),1);
			[T.seed.PCA_coeff,x(T.valid,:)] = princomp(x(T.valid,:));
		else
			x(T.valid,:) = bsxfun(@minus,x(T.valid,:),T.seed.Xmean) ...
				* T.seed.PCA_coeff;
		end
		
		T.X = zeros(num_events,4,class(x));
		T.X(T.valid,:) = x(T.valid,:);
		
	case 'FFT1/PCA'
		% Number of principal components to keep (total).
		T.num_comp = 4;
		
		f = fft(spikes.aligned,[],1);
		xr = real(f);
		xi = imag(f);
		% 		x = reshape([xr(2:7,:,:);xi(2:7,:,:)],[],num_events).';
		x = reshape([xr(2,:,:);xi(2,:,:)],[],num_events).';
		% 		x = reshape(xr(2:7,:,:),[],num_events).';
		
		scores = zeros(num_events,size(x,2),class(x));
		if make_new_seed
			T.seed.Xmean = mean(x(T.valid,:),1);
			[T.seed.PCA_coeff,scores(T.valid,:)] = princomp(x(T.valid,:));
		else
			scores(T.valid,:) = bsxfun(@minus,x(T.valid,:),T.seed.Xmean) ...
				* T.seed.PCA_coeff;
		end
		T.X = scores(:,1:T.num_comp);
		
	case 'FFT2/PCA'
		% Number of principal components to keep (total).
		T.num_comp = 4;
		
		f = fft(spikes.aligned,[],1);
		xr = real(f);
		xi = imag(f);
		% 		x = reshape([xr(2:7,:,:);xi(2:7,:,:)],[],num_events).';
		x = reshape([xr(2:3,:,:);xi(2:3,:,:)],[],num_events).';
		% 		x = reshape(xr(2:7,:,:),[],num_events).';
		
		if make_new_seed
			T.seed.Xmean = mean(x(T.valid,:),1);
			[T.seed.PCA_coeff,scores(T.valid,:)] = princomp(x(T.valid,:));
		else
			scores(T.valid,:) = bsxfun(@minus,x(T.valid,:),T.seed.Xmean) ...
				* T.seed.PCA_coeff;
		end
		[coeff,scores(T.valid,:)] = princomp(x(T.valid,:));
		T.X = scores(:,1:T.num_comp);
		
	case 'FFT3/PCA'
		% Number of principal components to keep (total).
		T.num_comp = 4;
		
		f = fft(spikes.aligned,[],1);
		xr = real(f);
		xi = imag(f);
		% 		x = reshape([xr(2:7,:,:);xi(2:7,:,:)],[],num_events).';
		x = reshape([xr(2:4,:,:);xi(2:4,:,:)],[],num_events).';
		% 		x = reshape(xr(2:7,:,:),[],num_events).';
		
		scores = zeros(num_events,size(x,2),class(x));
		if make_new_seed
			T.seed.Xmean = mean(x(T.valid,:),1);
			[T.seed.PCA_coeff,scores(T.valid,:)] = princomp(x(T.valid,:));
		else
			scores(T.valid,:) = bsxfun(@minus,x(T.valid,:),T.seed.Xmean) ...
				* T.seed.PCA_coeff;
		end
		T.X = scores(:,1:T.num_comp);
		
	case 'DCT/PCA'
		% Number of principal components to keep (total).
		T.num_comp = 5;
		
		S = dct3(spikes.aligned);
		r = reshape(S,[],num_events).';
		x = r;
		
		scores = zeros(num_events,size(x,2));
		if make_new_seed
			T.seed.Xmean = mean(x(T.valid,:),1);
			[T.seed.PCA_coeff,scores(T.valid,:)] = princomp(x(T.valid,:));
		else
			scores(T.valid,:) = bsxfun(@minus,x(T.valid,:),T.seed.Xmean) ...
				* T.seed.PCA_coeff;
		end
		T.X = scores(:,1:T.num_comp);
		
	case 'FFT/KS'
		T.num_comp = 4;
		
		S = fft(spikes.aligned,20);
		r = reshape([real(S(2:3,:));imag(S(2:3,:))],[],num_events).';
		
		if make_new_seed
			ks = zeros(1,size(r,2));
			for i = 1:size(r,2)
				warning off %#ok<WNOFF>
				[unused,unused,ks(i)] = lillietest(r(T.valid,i));
				warning on %#ok<WNON>
			end
			[kss,T.seed.ksorder] = sort(ks,'descend');
			x = r(:,T.seed.ksorder);
		else
			x = r(:,T.seed.ksorder);
		end
		T.X = x(:,1:T.num_comp);
		
	case 'DCT/KS'
		T.num_comp = 4;
		
		S = dct3(spikes.aligned);
		r = reshape(S,[],num_events).';
		
		if make_new_seed
			ks = zeros(1,size(r,2));
			for i = 1:size(r,2)
				warning off %#ok<WNOFF>
				[unused,unused,ks(i)] = lillietest(r(T.valid,i));
				warning on %#ok<WNON>
			end
			[kss,T.seed.ksorder] = sort(ks,'descend');
		end

		T.X = r(:,T.seed.ksorder(1:T.num_comp));
		
	case 'Wavelets/KS'
		T.num_comp = 6;
		
		% 		sp = abs_hilbert_3(spikes);
		% 		i1 = min(20,size(spikes,1));
		S1 = wavedec(spikes.aligned(:,1,1),4,'haar');
		i2 = size(S1,1);
		S = zeros(i2,num_wires,num_events);
		[Lo_D,Hi_D] = wfilters('haar');
		for i = 1:num_events
			for j = 1:num_wires
				S(:,j,i) = wavedec(spikes.aligned(:,j,i),4,Lo_D,Hi_D);
			end
		end
		r = reshape(S,[],num_events).';
		r(:,std(r) == 0) = [];
		
		if make_new_seed
			ks = zeros(1,size(r,2));
			for i = 1:size(r,2)
				warning off %#ok<WNOFF>
				[unused,unused,ks(i)] = lillietest(r(:,i));
				warning on %#ok<WNON>
			end
			[kss,T.seed.ksorder] = sort(ks,'descend');
		end
		
		T.X = r(:,T.seed.ksorder(1:T.num_comp));
		
	case 'KS only'
		T.num_comp = 4;
		
		r = reshape(spikes.aligned,[],num_events).';
		
		if make_new_seed
			ncols = size(r,2);
			ks = zeros(1,ncols);
			for i = 1:ncols
				warning off %#ok<WNOFF>
				[unused,unused,ks(i)] = lillietest(r(:,i));
				warning on %#ok<WNON>
			end
			[kss,T.seed.ksorder] = sort(ks,'descend');
		end
		
		T.X = r(:,T.seed.ksorder(1:T.num_comp));
		
	case 'Bimodality4'
		T.num_comp = 4;
		
		r = reshape(spikes.aligned,[],num_events).';
		if make_new_seed
			bimod = bimodality(r(T.valid,:));
			[unused,T.seed.order] = sort(bimod,'descend');
		end
		T.X = r(:,T.seed.order(1:T.num_comp));
		
	case '(RPS + FFT1)/PCA'
		% Number of principal components to keep (total).
		T.num_comp = 6;
		
		pattern = [1 1 1 1 0 -1 -1 -1 -1]';
		kernel = pattern(end:-1:1);
		
		f = fft(spikes.aligned,[],1);
		xr = real(f);
		xi = imag(f);
		
		x = [max(conv2(permute(spikes.aligned(:,1,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,2,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,3,:),[1 3 2]),kernel,'valid')).',...
			max(conv2(permute(spikes.aligned(:,4,:),[1 3 2]),kernel,'valid')).',...
			reshape([xr(2,:,:);xi(2,:,:)],[],num_events).'];
		
		scores = zeros(num_events,size(x,2),class(x));
		if make_new_seed
			T.seed.Xmean = mean(x(T.valid,:),1);
			[T.seed.PCA_coeff,scores(T.valid,:)] = princomp(x(T.valid,:));
		else
			scores(T.valid,:) = bsxfun(@minus,x(T.valid,:),T.seed.Xmean) ...
				* T.seed.PCA_coeff;
		end
		T.X = scores(:,1:T.num_comp);
		
end

end



%--------------------------------------------------------------------------
function T = cluster_trans(T,fresh_start,frac,num_clusters,clus_alg)

[num_events,num_dim] = size(T.X);
T.raw.idx0 = zeros(num_events,1);
T.raw.k = num_clusters;
T.raw.Q = Inf;
T.raw.D = zeros(num_events,1);
T.clustering_algorithm = clus_alg;

if num_events == 0
	return
end

if strncmp(clus_alg,'ksmd',4)
	alpha = sscanf(clus_alg(5:end),'%f');
	clus_alg = 'ksmd';
end

if fresh_start
	switch clus_alg
		case 'Classic'
			% Use slow, but accurate, algorithm to cluster 5000 points.
			temp = T.X(T.valid,1:T.num_comp);
			skip = unique(round(linspace(1,size(temp,1),5000)));
			temp = double(temp(skip,:));
			
			idx1 = partition(temp,T.raw.k);
			idx1 = kmeans_hybrid(temp,T.raw.k,idx1);
			
			T.seed.data = temp;
			T.seed.idx = renumber_clusters(idx1);
			T.seed.use = true;
			
			d = inf(num_events,num_clusters);
			% Loop through the clusters and compute Mahalanobis distance of
			% each point from each cluster center.
			for clu = 1:num_clusters
				% Get seed points from cluster clu.
				this_cluster = T.seed.idx == clu;
				Xthis = T.seed.data(this_cluster,:);
				n_this = size(Xthis,1);
				% If we don't have at least m points in the cluster then
				% eliminate it.
				if n_this >= num_dim
					d(T.valid,clu) = mahal(T.X(T.valid,:),Xthis);
				else
					d(T.valid,clu) = inf;
				end
			end
			[T.raw.D(T.valid),T.raw.idx0(T.valid)] = min(d(T.valid,:),[],2);
			
		case 'GMM'
			% Trap warning and display it as message.
			[msgstr0,msgid0] = lastwarn;
			lastwarn('')
			this_warn = warning('off','stats:gmdistribution:FailedToConverge');
			gmm = gmdistribution.fit(T.X(T.valid,:),T.raw.k);
			[unused,warn_msg_id] = lastwarn;
			if strcmp(warn_msg_id,'stats:gmdistribution:FailedToConverge')
				mymessage2('GMM did not converge.')
			end
			warning(this_warn)
			lastwarn(msgstr0,msgid0)
			
			[T.raw.idx0(T.valid),unused,unused,unused,M] = ...
				gmm.cluster(T.X(T.valid,:));
			T.raw.D(T.valid) = M(sub2ind(size(M),(1:size(M,1))',...
				T.raw.idx0(T.valid)));
			seed = struct('data',T.X(T.valid,:),...
				'idx',T.raw.idx0(T.valid),'use',true,'gmm',gmm);
			T.seed = merge_structs(T.seed,seed);
			T.raw.idx0 = renumber_clusters(T.raw.idx0);
			T.seed.idx = renumber_clusters(T.seed.idx);
			
		case 'ksmd'
			[T.raw.idx0(T.valid),seed,T.raw.D(T.valid)] = ...
				ksmd(T.X(T.valid,:),T.raw.k,[],alpha);
			T.seed = merge_structs(T.seed,seed);
			T.raw.idx0 = renumber_clusters(T.raw.idx0);
			T.seed.idx = renumber_clusters(T.seed.idx);
			
		case 'kmeans'
			T.raw.idx0(T.valid) = kmeans(T.X(T.valid,:),T.raw.k);
			T.raw.idx0 = renumber_clusters(T.raw.idx0);
			
			T.seed.ctrs = zeros(T.raw.k,num_dim);
			d = inf(num_events,num_clusters);
			for clu = 1:num_clusters
				this_cluster = T.raw.idx0 == clu;
				Xthis = T.X(this_cluster,:);
				T.seed.ctrs(clu,:) = mean(Xthis);
				n_this = size(Xthis,1);
				if n_this >= num_dim
					d(T.valid,clu) = mahal(T.X(T.valid,:),Xthis);
				else
					d(T.valid,clu) = inf;
				end
			end
			T.raw.D(T.valid) = d(sub2ind(size(d),find(T.valid),...
				T.raw.idx0(T.valid)));
			
			T.seed.data = T.X(T.valid,:);
			T.seed.idx = T.raw.idx0(T.valid);
			
	end
	T.merges = {};
	T.merged = T.raw;
else
	switch clus_alg
		case 'Classic'
			% Initialize distance matrix.
			d = inf(num_events,num_clusters);
			
			% Loop through the clusters and compute Mahalanobis distance of
			% each point from each cluster center.
			for clu = 1:num_clusters
				% Get seed points from cluster clu.
				this_cluster = T.seed.idx == clu;
				Xthis = T.seed.data(this_cluster,:);
				n_this = size(Xthis,1);
				
				% If we don't have at least m points in the cluster then
				% eliminate it.
				if n_this >= num_dim
					d(T.valid,clu) = mahal(T.X(T.valid,:),Xthis);
				else
					d(T.valid,clu) = inf;
				end
			end
			[T.raw.D(T.valid),T.raw.idx0(T.valid)] = min(d(T.valid,:),[],2);
			
		case 'GMM'
			[T.raw.idx0(T.valid),unused,unused,unused,M] = ...
				T.seed.gmm.cluster(T.X(T.valid,:));
			T.raw.D(T.valid) = M(sub2ind(size(M),(1:size(M,1))',...
				T.raw.idx0(T.valid)));
			
		case 'ksmd'
			[T.raw.idx0(T.valid),T.seed,T.raw.D(T.valid)] = ...
				ksmd(T.X(T.valid,:),T.raw.k,T.seed,alpha);
			
		case 'kmeans'
			d = inf(num_events,num_clusters);
			dd = inf(num_events,num_clusters);
			for clu = 1:num_clusters
				dd(T.valid,clu) = sum(bsxfun(@minus,...
					T.X(T.valid,:),T.seed.ctrs(clu,:)).^2,2);
				
				this_cluster = T.seed.idx == clu;
				Xthis = T.seed.data(this_cluster,:);
				n_this = size(Xthis,1);
				if n_this >= num_dim
					d(T.valid,clu) = mahal(T.X(T.valid,:),Xthis);
				else
					d(T.valid,clu) = inf;
				end
			end
			[unused,T.raw.idx0(T.valid)] = min(dd(T.valid,:),[],2);
			T.raw.D(T.valid) = d(sub2ind(size(d),find(T.valid),...
				T.raw.idx0(T.valid)));
			
		case 'kprog (experimental)'
			% 			temp = T.X(T.valid,:);
			% 			idx1 = kprog(temp,T.raw.k);
			
	end
end

[T.raw.ce0,T.raw.ce,T.raw.Q] = cluster_quality2(T.X(T.valid,1:T.num_comp),...
	T.raw.k,T.raw.idx0(T.valid));

T.outlier_threshold = chi2inv(frac,T.num_comp);
T.raw.is_outlier = (T.raw.D > T.outlier_threshold) & T.valid;
T.raw.idx = T.raw.idx0;
% T.raw.idx(T.raw.is_outlier) = T.raw.idx(T.raw.is_outlier) + T.raw.k;
% Negate cluster number of outliers.
T.raw.idx(T.raw.is_outlier) = -T.raw.idx(T.raw.is_outlier);

end



%--------------------------------------------------------------------------
function T = apply_merges(T)

% Merge the clusters with outliers intact.
T.merged.idx0 = merge_clusters(T.raw.idx0,T.merges);
% T.merged.k = length(unique(T.merged.idx0(T.valid)));
T.merged.k = T.raw.k;

% Compute new statistics.
[unused,T.merged.ce,T.merged.Q] = cluster_quality2(T.X(T.valid,:),...
	T.merged.k,T.merged.idx0(T.valid));

% Initialize outlier identifier and distance metric.
num_events = size(T.X,1);
T.merged.is_outlier = false(num_events,1);
T.merged.D = zeros(num_events,1);

% Compute merged seed.
merged_seed = T.seed;
merged_seed.idx = merge_clusters(merged_seed.idx,T.merges);

% Identify outliers as being further than a certain threshold from the
% merged seed clusters.
[T.merged.is_outlier(T.valid),T.merged.D(T.valid)] = identify_outliers( ...
	T.X(T.valid,:),T.merged.k,T.merged.idx0(T.valid),merged_seed,...
	T.outlier_threshold);

% % Increment cluster numbers for outliers.
% T.merged.idx = T.merged.idx0;
% T.merged.idx(T.merged.is_outlier) = T.merged.idx(T.merged.is_outlier) + ...
% 	T.merged.k;

% Negate cluster number for outliers.
T.merged.idx = T.merged.idx0;
T.merged.idx(T.merged.is_outlier) = -T.merged.idx(T.merged.is_outlier);
end



%--------------------------------------------------------------------------
function [is_outlier,D] = identify_outliers(X,k,idx,seed,threshold)

% Initialize distance matrix.
[n,m] = size(X);
d = inf(n,k);

% Loop through the clusters and compute Mahalanobis distance of each
% point from each cluster center.
for clu = 1:k
	% Get seed points from cluster clu.
	this_cluster = seed.idx == clu;
	Xthis = seed.data(this_cluster,:);
	n_this = size(Xthis,1);
	
	% If we don't have at least m points in the cluster then eliminate it.
	if n_this >= m
		d(:,clu) = mahal(X,Xthis);
	else
		d(:,clu) = inf;
	end
end

% Compute distances and pick the distance according to idx.
D = d(sub2ind([n,k],(1:n)',idx));
is_outlier = D > threshold;

end



%--------------------------------------------------------------------------
function display_clusters(T,panel)

num_events = size(T.X,1);
num_to_plot = num_events;

idx = T.merged.idx;

% Map all outliers to an extra cluster for display.
idx(T.merged.is_outlier) = T.merged.k + 1;

invis_fig = figure('Visible','off');
set(invis_fig,'DefaultAxesPosition',[0.25 0.02 0.7 0.94])

[ax,bigax] = gplotmatrix1(T.X(T.valid(1:num_to_plot),:),T.merged.k,...
	idx(T.valid(1:num_to_plot)));
set(ax,'XTick',[],'YTick',[])
delete(findobj(panel,'Type','axes'))
drawnow
set(bigax,'Parent',panel)
set(ax,'Parent',panel)
title(bigax,sprintf('k = %d, CE = %.3g  (%s)',T.merged.k,T.merged.Q,...
	T.method))
% title(bigax,sprintf('k = %d, CE = %.3g  (%s)',T.merged.k,...
% 	log10(T.merged.Q),T.method))
delete(invis_fig)
drawnow

end



%--------------------------------------------------------------------------
function [ax,bigax] = gplotmatrix1(x,k,idx)
inlier_colors = [255 0 0; % Red
	0 255 0;              % Lime
	70 130 180;           % SteelBlue
	255 255 0;            % Yellow
	85 0 130;             % Purple
	255 140 0;            % DarkOrange
	238 130 238]/255;     % Violet
outlier_color = [0.5 0.5 0.5]; % Gray
colors = [inlier_colors(1:k,:);outlier_color];
num_cols = size(x,2);
y = [x;NaN(k,num_cols)];
idx2 = [idx;(1:k)'];
[unused,ax,bigax] = gplotmatrix(y,[],idx2,colors,'.',4,'off');
set(ax,'Color','k')
patches = findobj(ax(end,:),'Type','patch');
set(patches,'FaceColor',[0.4 0.4 0.4])
end



%--------------------------------------------------------------------------
function s3 = merge_structs(s1,s2)
s3 = s1;
fn = fieldnames(s2);
for i = 1:length(fn)
	s3.(fn{i}) = s2.(fn{i});
end
end



%--------------------------------------------------------------------------
function percent = percent_small_intervals(ts,num_clust,idx)
tsmall = 1; % ms

seg = cumsum(ts < 0);
ts = abs(ts)/1000;
percent = zeros(1,num_clust);

for cl = 1:num_clust
	iscl = idx == cl;
	ts1 = ts(iscl);
	seg1 = seg(iscl);
	n = length(ts1);
	if n > 0
		intervals = NaN(1,n);
		cnt = 0;
		for i = 1:length(ts1)
			first = find(ts1 > ts1(i) & seg1 == seg1(i),1,'first');
			if ~isempty(first)
				cnt = cnt + 1;
				intervals(cnt) = ts1(first) - ts1(i);
			end
		end
		nsmall = sum(intervals <= tsmall);
		percent(cl) = 100*nsmall/cnt;
	else
		percent(cl) = inf;
	end
end
end



%--------------------------------------------------------------------------
function [spikes5,badout] = align_spikes2(spikes,method)

if nargin < 2
	method = 'linear';
end

Fs = 32051;
T = 1/Fs;
[n,num_wires,num_events] = size(spikes);
t = (0:n-1).'*T;
a = 4;
len2 = a*(n - 1) + 1;
t2 = linspace(0,t(n),len2)';

tmin2 = 0.1e-3;
tmax2 = 0.7e-3;
nmin2 = find(t2 > tmin2,1,'first');
nmax2 = find(t2 < tmax2,1,'last');
n2 = nmax2 - nmin2 + 1;

wn = 0.25/a;
b = fir1(200,wn)';

tmin = 0.1e-3;
tmax = 0.4e-3;
nmin = find(t2 > tmin,1,'first');
nmax = find(t2 < tmax,1,'last');


block_size = 10000;
num_blocks = ceil(num_events/block_size);

for block = 1:num_blocks
	event1 = (block - 1)*block_size + 1;
	event2 = min(block*block_size,num_events);
	events = event1:event2;
	this_num_events = length(events);
% 	bad = false(this_num_events,1);
	
	spikes2 = interp1(t,spikes(:,:,events),t2,method);
	spikes2a = reshape(mean(spikes2,2),[],this_num_events);
	
	spikes3 = conv2(max(spikes2a,0),b,'same');
	
% 	[unused,index4] = max(spikes3(nmin:nmax,:,:),[],1);
	[unused,index4] = max(spikes3,[],1);
	
	if block == 1
		index4_mode = mode(index4);
	end
	
	shift = index4 - index4_mode;
	bad = index4 < nmin | index4 > nmax;
	shift(bad) = 0;
	
	spikes4 = zeros(n2,num_wires,this_num_events);
	for i = 1:num_wires
		for j = 1:this_num_events
			k = [(nmin2:nmax2).' + shift(j),(1:n2).'];
			k(k(:,1) < 1,:) = [];
			k(k(:,1) > len2,:) = [];
			spikes4(k(:,2),i,j) = spikes2(k(:,1),i,j);
		end
	end
	
	if block == 1
		spikes5 = zeros(size(spikes4(1:a:end,1,1),1),num_wires,...
			num_events,class(spikes));
		badout = false(num_events,1);
	end
	spikes5(:,:,events) = spikes4(1:a:end,:,:);
	badout(events) = bad;
	
end

end



%--------------------------------------------------------------------------
function bimod = bimodality(x,dim)
%bimodality: Coefficient of bimodality

if nargin < 2
	dim = 1;
end

xm = bsxfun(@minus,x,mean(x,dim));

m2 = mean(xm.^2,dim);
m3 = mean(xm.^3,dim);
m4 = mean(xm.^4,dim);

% skew = m3./m2.^(1.5);
skew2 = m3.^2/m2.^3; % skewness squared
kur = m4./m2.^2; % kurtosis

% bimod = (1 + skew.^2)./kur;
bimod = (1 + skew2)./kur;
end



%--------------------------------------------------------------------------
function [Lr,Lru,Q] = cluster_quality2(x,num_clust,idx)

clusters = 1:num_clust;
[n,num_vars] = size(x);

warn_state = warning('off','MATLAB:divideByZero');
L = zeros(num_clust,num_clust);
for i = 1:num_clust
	this_cluster = idx == clusters(i);
	if sum(this_cluster) >= num_vars
		m = mahal(x,x(this_cluster,:));
	else
		xm = bsxfun(@minus,x,mean(x(this_cluster,:)));
		y = bsxfun(@rdivide,xm,std(xm(this_cluster,:)));
		m = sum(y.^2,2);
	end
	
	for j = 1:num_clust
		if i ~= j
% 			L(j,i) = sum(1 - chi2cdf(m(idx == clusters(j)),num_vars));
			% more accurate for large m
			L(j,i) = sum(gammainc(m(idx == clusters(j))/2,num_vars/2,...
				'upper'));
		end
	end
end
n = histc(idx,clusters);

Lr = bsxfun(@rdivide,L,n(:)');
warning(warn_state)

Lru = triu(Lr + Lr');

Q = sum(Lr(~isnan(Lr)));

end


%--------------------------------------------------------------------------
function y = dct3(x)
[n,m,k] = size(x);
y = reshape(dct(reshape(x,n,m*k)),n,m,k);
end



%--------------------------------------------------------------------------
function d2 = mahal(Y,X)
% Mahalanobis distance squared.
Ym = bsxfun(@minus,Y,mean(X,1));
d2 = sum((Ym/cov(X)).*Ym,2);
end



%--------------------------------------------------------------------------
function x = chi2inv(p,v)
x = 2*gammaincinv(p,v/2);
end



%--------------------------------------------------------------------------
function [coeff,score,latent] = princomp(X)
[n,m] = size(X);
Xm = bsxfun(@minus,X,mean(X,1));
[u,s,coeff] = svd(Xm,0);
[unused,maxloc] = max(abs(coeff),[],1);
% Make max value in each column positive.
coeff = bsxfun(@times,coeff,sign(coeff(sub2ind(size(coeff),maxloc,1:m))));
score = Xm*coeff;
if n == 1
	latent = zeros(m,1);
else
	s = diag(s);
	latent = zeros(m,1);
	latent(1:length(s)) = s.^2/(n - 1);
end
end



%--------------------------------------------------------------------------
function [best_idx,D,Dbest] = kmeans_hybrid(X,k,arg3)

% Argument checks.
error(nargchk(2,3,nargin))
error(nargoutchk(0,3,nargout))

[n,m] = size(X);
D = zeros(n,k);

if nargin < 3
	arg3 = 1;
end

if k == 1
	best_idx = ones(n,1);
	D = mahal(X,X);
	Dbest = D;
	return
end

if isscalar(arg3)
	num_reps = arg3;
	
	% Compute starting index vector.
	Xm = mean(X,1);
	[coeff,scores] = princomp(X);
	range_all = prctile(scores,[5 95]);
	ctr1pc = linspace(range_all(1,1),range_all(2,1),k).';
	ctr = bsxfun(@plus,[ctr1pc,zeros(k,m-1)]*coeff',Xm);
	for clu = 1:k
		D(:,clu) = sum(bsxfun(@minus,X,ctr(clu,:)).^2,2);
	end
	[unused,idx] = min(D,[],2);
	
else
	idx = arg3;
	num_reps = 1;
end


best_Q = inf;
best_idx = idx;

for rep = 1:num_reps
	if rep ~= 1
		good_start = false;
		while ~good_start
			ctr_pc = bsxfun(@plus,bsxfun(@times,rand(k,m),...
				diff(range_all)),range_all(1,:));
			ctr = bsxfun(@plus,ctr_pc*coeff',Xm);
			for clu = 1:k
				D(:,clu) = sum(bsxfun(@minus,X,ctr(clu,:)).^2,2);
			end
			[unused,idx] = min(D,[],2);
			good_start = all(histc(idx,1:k) > 0);
		end
	end
	last_idx = NaN(n,1);
	
	% Main loop converge if previous partition is the same as current
	it = 1;
	while any(last_idx ~= idx) && it < 100*m
		last_idx = idx;
		for clu = 1:k
			this_cluster = idx == clu;
			Xthis = X(this_cluster,:);
			n_this = size(Xthis,1);
			if n_this >= m
				D(:,clu) = mahal(X,Xthis);
			else
				D(:,clu) = sum(bsxfun(@minus,X,mean(Xthis,1)).^2,2);
			end
		end
		[Dbest,idx] = min(D,[],2);
		it = it + 1;
	end
	if it >= 100*m
		warning('kmeans_hybrid did not converge in %d iterations.',it) %#ok<WNTAG>
	end
	[unused,unused,Q] = cluster_quality2(X,k,idx);
	
	if any(histc(idx,1:k) == 0)
		Q = inf;
	end
	
	if Q < best_Q
		best_idx = idx;
		best_Q = Q;
	end
	
end

end



%--------------------------------------------------------------------------
function [idx,seed,D,Ds] = ksmd(X,k,arg3,scaling_level)
%ksmd: Clustering using scaled Mahalanobis distance.
% The algorithm is like kmeans except the metric is a scaled Mahalanobis
% distance.  Each distance is scaled by the size of the cluster.
%
% IDX = ksmd(X,K)

% written by Douglas M. Schwarz


if nargin < 4
	scaling_level = 2;
end

[n,m] = size(X);

if nargin > 2 && isstruct(arg3)
	% Use supplied seed to sort X.
	
	% Get seed as third input argument.
	seed = arg3;
	
	% If the seed structure does not contain the cluster volumes, we can
	% calculate them.
	need_volumes = scaling_level > 0 && (~isfield(seed,'volumes') || ...
		isempty(seed.volumes));
	if need_volumes
		seed.volumes = zeros(1,k);
	end
	
	% Initialize distance matrix.
	d = inf(n,k);
	
	% Loop through the clusters and compute Mahalanobis distance of each
	% point from each cluster center.
	for clu = 1:k
		% Get seed points from cluster clu.
		this_cluster = seed.idx == clu;
		Xthis = seed.data(this_cluster,:);
		n_this = size(Xthis,1);
		if need_volumes
			[unused,unused,lat] = princomp(Xthis);
% 			seed.volumes2(clu) = prod(lat).^(1/m);
			seed.volumes(clu) = sqrt(prod(lat));
		end
		
		% If we don't have at least m points in the cluster then eliminate
		% it.
		if n_this >= m
			d(:,clu) = mahal(X,Xthis);
		else
			d(:,clu) = inf;
		end
	end
	
	% Set scale for each cluster to normalized volumes and adjust for small
	% clusters.
	scale = seed.volumes.^(scaling_level/m);
	
	% Compute scaled distances, choose a cluster for each point based on
	% those, compute unscaled distances of each point from centers.
	d_scaled = bsxfun(@times,d,scale);
	[Ds,idx] = min(d_scaled,[],2);
	D = d(sub2ind([n,k],(1:n)',idx));
	
else
	
	% If cluster centers are not supplied use initialization algorithm of
	% kmeans++.
	if nargin < 3 || isempty(arg3)
		ctri = zeros(1,k);
		ctri(1) = ceil(n*rand);
		for kk = 2:k
			DX2a = zeros(n,kk-1);
			for i = 1:kk-1
				DX2a(:,i) = sum(bsxfun(@minus,X,X(ctri(i),:)).^2,2);
			end
			DX2 = min(DX2a,[],2);
			cs = cumsum(DX2);
			[unused,ctri(kk)] = histc(cs(end)*rand,[0;cs]);
		end
		ctrs = X(ctri,:);
	else
		ctrs = arg3;
	end
	
	% Use those cluster centers to do an initial clustering.
	d = zeros(n,k);
	for clu = 1:k
		d(:,clu) = sqrt(sum(bsxfun(@minus,X,ctrs(clu,:)).^2,2));
	end
	[D,idx] = min(d,[],2);
	
	% Use those clusters to do scaled Mahalanobis-distance clustering.
	it = 1;
	last_idx = NaN(n,1);
	volumes = zeros(1,k);
	while any(last_idx ~= idx) && it < 100*m
		last_idx = idx;
		d = inf(n,k);
		for clu = 1:k
			this_cluster = idx == clu;
			Xthis = X(this_cluster,:);
			n_this = size(Xthis,1);
			[unused,unused,lat] = princomp(Xthis);
			volumes(clu) = sqrt(prod(lat));
			if n_this >= m
				d(:,clu) = mahal(X,Xthis);
			else
				d(:,clu) = inf;
			end
		end
		scale = volumes.^(scaling_level/m);
		d_scaled = bsxfun(@times,d,scale);
		[Ds,idx] = min(d_scaled,[],2);
		D = d(sub2ind([n,k],(1:n)',idx));
		it = it + 1;
	end
	
	seed.data = X;
	seed.idx = idx;
	seed.volumes = volumes;
end
end



%--------------------------------------------------------------------------
function idx = merge_clusters(idx,varargin)
%merge_clusters: Combine cluster indices.
%  merge_clusters takes an index vector, combines the indices specified and
%  then renumbers the index vector so that the set of indices is
%  contiguous.  Indices must be non-negative integers.  Indices equal to
%  zero are left unchanged and it is not possible to combine any other
%  index with zero.
%
%  Syntax,
%
%    IDX = merge_clusters(IDX,MERGES)
%
%  where,
%
%    IDX is a vector of non-negative integers.
%    MERGES is a cell array of vectors specifying which clusters to merge.
%
%  For example,
%
%    merge_clusters([1 2 3 4 5 6],{[2 3],[4 5]})
%
%  will merge clusters 2 & 3 and 4 & 5 resulting in
%
%    IDX = [1 2 2 4 4 6]

% written by Douglas M. Schwarz

% Interpret input arguments.
if nargin < 2
	return
end
if iscell(varargin{1})
	merges = varargin{1};
else
	merges = varargin;
end

% Build a lookup table by merging entries.
lut = 1:max([max(idx),merges{:}]);
for i = 1:length(merges)
	lm = lut(merges{i});
	lut(ismember(lut,lm)) = min(lm);
end

% Apply the lookup table to the non-zero indices.
nz = logical(idx);
idx(nz) = lut(idx(nz));

end



%--------------------------------------------------------------------------
function [idx,D,ctrs,Q] = partition(x,k)

[n,m] = size(x);

% Use mixed gaussian model to determine initial centers.
converged = false;
attempt = 1;
while ~converged && attempt < 5
	obj = gmdistribution.fit(x,k);
	ctr = obj.mu;
	converged = obj.Converged;
	attempt = attempt + 1;
end

% Optimize cluster centers with cluster quality as the metric.
c0 = ctr(:);
% lb = repmat(min(x),k,1);
% ub = repmat(max(x),k,1);
% c = fminsearchbnd(@(z)objfcn1(z,x,k),c0(:),lb(:),ub(:));
% [c,unused,unused,output] = fminsearch(@(z)objfcn1(z,x,k),c0);
c = fminsearch(@(z)objfcn1(z,x,k),c0);

% Get final cluster indices from the objective function.
[Q,idx,D] = objfcn1(c,x,k);

% Get final centers from final clusters.
ctrs = zeros(k,m);
for clu = 1:k
	ctrs(clu,:) = mean(x(idx == clu,:),1);
end

end



%--------------------------------------------------------------------------
function [Q,idx,D] = objfcn1(x,V,k)

c = reshape(x,k,[]);
[n,m] = size(V);

D = zeros(n,k);
for clu = 1:k
	d = zeros(n,1);
	% Loop for each dimension
	for s = 1:m
		d = d + (V(:,s) - c(clu,s)).^2;
	end
	D(:,clu) = d;
end

% Partition data to closest centroids
[unused,idx] = min(D,[],2);

% Disallow too few clusters.
h = histc(idx,1:k);
if any(h < m)
	Q = inf;
else
	[unused,unused,Q] = cluster_quality2(V,k,idx);
end

end



%--------------------------------------------------------------------------
function plot_spikes(spikes,label,spike_bits)

if nargin < 2
	label = '';
end
if nargin < 3
	spike_bits = 12;
end

fig = figure('Name',label,...
	'KeyPressFcn',@keypress,...
	'CreateFcn',{@movegui,'north'},...
	'Tag','cluster gui figure');

edit_box = uicontrol('Style','edit',...
	'Position',[10 10 50 20],...
	'String','1',...
	'BackgroundColor','w',...
	'Callback',@get_index);

	function get_index(h,evt) %#ok<INUSD>
		str = get(h,'String');
		index = sscanf(str,'%f');
		do_plot(h1,h2)
	end

[n,nw,num_events] = size(spikes);
uicontrol('Style','text',...
	'Position',[60 10 80 16],...
	'BackgroundColor',get(fig,'Color'),...
	'String',sprintf('out of %d',num_events))

T = 1/32051;
t = (0:n-1)*T;
n = 512;
f = t2f(t,n);
fh = f(1:(n/2+1));
index = 1;
[h1,h2] = do_plot();

	function keypress(h,evt) %#ok<INUSL>
		switch evt.Key
			case 'rightarrow'
				index = min(index + 1,num_events);
			case 'leftarrow'
				index = max(index - 1,1);
				
			case 'numpad3'
				index = min(index + 1,num_events);
			case 'numpad1'
				index = max(index - 1,1);
				
			case 'numpad6'
				index = min(index + 10,num_events);
			case 'numpad4'
				index = max(index - 10,1);
				
			case 'numpad9'
				index = min(index + 100,num_events);
			case 'numpad7'
				index = max(index - 100,1);
		end
		do_plot(h1,h2)
	end

	function [h1,h2] = do_plot(hh1,hh2)
		if nargin == 0
			set(edit_box,'String',sprintf('%d',index))
			s = spikes(:,:,index);
			S = fft(s,n);
			subplot(2,1,1)
			h1 = plot(t,s);
			ylim([-1 1]*2.^(spike_bits - 1))
			xlabel('time (s)')
			title('Spike Waveform')
			grid on
			subplot(2,1,2)
			h2 = plot(fh,abs(S(1:(n/2+1),:)));
			ylim([0 2.^(spike_bits + 2)])
			xlabel('Freq. (Hz)')
			title('Spike Spectrum')
		else
			set(edit_box,'String',sprintf('%d',index))
			s = spikes(:,:,index);
			S = fft(s,n);
			set(hh1,{'YData'},num2cell(s,1).')
			set(hh2,{'YData'},num2cell(abs(S(1:(n/2+1),:)),1).')
		end
	end

end



%--------------------------------------------------------------------------
function [idx,lut] = renumber_clusters(idx,valid,isoutlier)
%renumber_clusters: Sort and pack cluster indices.
% usage:  NEW_IDX = renumber_clusters(IDX,VALID)
%
% where,
%   IDX is a vector of indices identifying clusters.
%   VALID (optional) is a logical vector of the same size as IDX indicating
%   which indices may be changed.  If not included it is computed from IDX.
%
%   NEW_IDX is a vector of the same size as IDX in which the indices have
%   been sorted by frequency of occurence from high to low and packed to
%   the lowest values possible.  Any indices less than or equal to zero are
%   left unchanged regardless of frequency or value.

% Select index values to be changed.
if nargin < 2 || isempty(valid)
	valid = idx > 0;
end

if nargin < 3
	
	% Pack idx to be a contiguous set.
	[idx_set,unused,idx(valid)] = unique(idx(valid));
	
	% Determine number of unique indices.
	num_clust = length(idx_set);
	
	% Sort by frequency of occurence.
	freq = histc(idx,0:num_clust);
	[unused,order] = sort(freq(2:end),'descend');
	
	% Use sort order to shuffle indices with a lookup table (lut).
	lut(order) = 1:num_clust;
	idx(valid) = lut(idx(valid));
	
else
	
	% Pack idx to be a contiguous set.
	idx_set = unique(idx(valid & ~isoutlier));
	
	% Determine number of unique indices.
	num_clust = length(idx_set);
	
	% Sort by frequency of occurence.
	freq = histc(idx,0:num_clust);
	[unused,order] = sort(freq(2:end),'descend');
	
	% Use sort order to shuffle indices with a lookup table (lut).
	lut(order) = 1:num_clust;
	lut = [lut,lut+num_clust];
	idx(valid) = lut(idx(valid));
	
end
end



%--------------------------------------------------------------------------
function f = t2f(t,n)
if nargin < 2
	n = length(t);
end

T = mean(diff(t));
f = linspace(0,1/T,n+1);
f(end) = [];
end



%--------------------------------------------------------------------------
function wavehist(spikes,a,showlines,spike_bits)
if nargin < 2 || isempty(a)
	a = 4;
end
if nargin < 3
	showlines = true;
end
if nargin < 4
	spike_bits = 12;
end
showgrid = false;
[n,num_wires,num_events] = size(spikes); %#ok<NASGU>
n2 = (n-1)*a + 1;
t = (0:n-1)';
t2 = linspace(0,t(end),n2)';
spikes2 = interp1(t,spikes,t2,'spline');

% Next largest odd number > n2*3/4;
nbins = ceil((n2*0.75 - 1)/2)*2 + 1;
% nbins = max(nbins,51);

max_amp = 2.^(spike_bits - 1);
amp = max(abs(spikes2(:)));
amp = max(amp,max_amp);
hx = linspace(-amp,amp,nbins)';

hh = zeros(nbins,n2);
hlines = zeros(num_wires,3);

gridlines = zeros(num_wires,2);
xgrid = t2(1):5:t2(end);
ygrid = -max_amp:max_amp/4:max_amp; %#ok<BDSCI>
ygrid([1 end]) = [];
[xx,xy] = meshgrid(t2([1 end]),ygrid);
xx = xx.';
xy = xy.';
xx(end+1,:) = NaN;
xy(end+1,:) = NaN;
[yx,yy] = meshgrid(xgrid,[-1 1]*max_amp);
yx(end+1,:) = NaN;
yy(end+1,:) = NaN;

if showlines
	vis = 'on';
else
	vis = 'off';
end

for wire = 1:num_wires
	subplot(2,2,wire)
	for i = 1:n2
		hh(:,i) = hist(reshape(spikes2(i,wire,:),[],1),hx).'; 
	end
	pcolor(t2,hx,hh)
	shading interp
	colormap(sqrt(gray(256)))
	m = mean(spikes2(:,wire,:),3);
	s = std(spikes2(:,wire,:),0,3);
	hlines(wire,1) = line(t2,m+s,'Color',[0 0 0.75],'Visible',vis);
	hlines(wire,2) = line(t2,m-s,'Color',[0 0 0.75],'Visible',vis);
	hlines(wire,3) = line(t2,m,'Color',[0.75 0 0],'Visible',vis);
	gridlines(wire,1) = line(xx(:),xy(:),'Color',[0.5 0.5 0.5],...
		'Visible','off');
	gridlines(wire,2) = line(yx(:),yy(:),'Color',[0.5 0.5 0.5],...
		'Visible','off');
end

cntrl = findobj(gcf,'Tag','showlines control');
delete(cntrl)

bg = get(gcf,'Color');
uicontrol('Style','checkbox',...
	'Position',[5 5 80 20],...
	'String','Show stats',...
	'Tag','showlines control',...
	'BackgroundColor',bg,...
	'Value',showlines,...
	'Callback',@toggle_lines)

	function toggle_lines(h,evt) %#ok<INUSD>
		if showlines
			set(hlines,'Visible','off')
			showlines = false;
		else
			set(hlines,'Visible','on')
			showlines = true;
		end
	end

uicontrol('Style','checkbox',...
	'Position',[95 5 80 20],...
	'String','Show grid',...
	'Tag','showgrid control',...
	'BackgroundColor',bg,...
	'Value',showgrid,...
	'Callback',@toggle_grid)

	function toggle_grid(h,evt) %#ok<INUSD>
		if showgrid
			set(gridlines,'Visible','off')
			showgrid = false;
		else
			set(gridlines,'Visible','on')
			showgrid = true;
		end
	end

end



%--------------------------------------------------------------------------
function wavehist_array(spikes,idx,isoutlier,checkbox_fcn,isgood,spike_bits)
if nargin < 6
	spike_bits = 12;
end
a = 4;
showlines = false;
showgrid = false;

clusters = unique(idx(~isoutlier));
clusters(clusters == 0) = [];
num_clusters = length(clusters);

[n,num_wires,num_events] = size(spikes); %#ok<NASGU>
n2 = (n-1)*a + 1;
t = (0:n-1)';
t2 = linspace(0,t(end),n2)';
spikes2 = interp1(t,spikes,t2,'spline');

% Next largest odd number > n2*3/4;
nbins = ceil((n2*0.75 - 1)/2)*2 + 1;
% nbins = max(nbins,51);

max_amp = 2.^(spike_bits - 1);
amp = max(abs(spikes2(:)));
amp = max(amp,max_amp);
hx = linspace(-amp,amp,nbins)';

hh = zeros(nbins,n2);
hlines = zeros(num_wires,num_clusters,3);

gridlines = zeros(num_wires,num_clusters,2);
xgrid = t2(1):5:t2(end);
ygrid = -max_amp:max_amp/4:max_amp; %#ok<BDSCI>
ygrid([1 end]) = [];
[xx,xy] = meshgrid(t2([1 end]),ygrid);
xx = xx.';
xy = xy.';
xx(end+1,:) = NaN;
xy(end+1,:) = NaN;
[yx,yy] = meshgrid(xgrid,[-1 1]*max_amp);
yx(end+1,:) = NaN;
yy(end+1,:) = NaN;

if showlines
	vis = 'on';
else
	vis = 'off';
end

bgcolor = get(gcf,'Color');

label_width = 0.03;
hgap = 0.01;
width = (0.95 - label_width - 3.5*hgap)/4;
px = label_width + (0:3)*(width + hgap);

cntrl_ht = 0.05;
title_ht = 0.03;
vgap = 0.01;
height = (1 - cntrl_ht - title_ht - 4*vgap)/5;
py = fliplr(cntrl_ht + (0:4)*(height + vgap));
if num_clusters > 5
	height = (1 - cntrl_ht - title_ht - (num_clusters-1)*vgap)/num_clusters;
	py = fliplr(cntrl_ht + (0:num_clusters-1)*(height + vgap));
end

clusi = 0;
for clus = clusters(:)'
	clusi = clusi + 1;
	for wire = 1:num_wires
		ax = axes('Units','normalized',...
			'Position',[px(wire),py(clusi),width,height],...
			'XTickLabel','',...
			'YTickLabel','',...
			'Box','on',...
			'YColor','w');
		for i = 1:n2
			hh(:,i) = hist(reshape(spikes2(i,wire,idx == clus),[],1),hx).';
		end
		pcolor(t2,hx,hh)
		if clusi == num_clusters
			set(ax,'YTickLabel','',...
				'Box','on')
		else
			set(ax,'XTickLabel','',...
				'YTickLabel','',...
				'Box','on')
		end
		if clusi == 1
			text(t(end)/2,max_amp,sprintf('wire %d',wire),...
				'HorizontalAlignment','center',...
				'VerticalAlignment','bottom',...
				'FontSize',8)
		end
		if wire == 1
			text(0,0,sprintf('#%d, N = %d',clus,sum(idx == clus)),...
				'HorizontalAlignment','center',...
				'VerticalAlignment','bottom',...
				'Rotation',90,...
				'FontSize',8)
		end
		shading interp
		colormap(sqrt(gray(256)))
		m = mean(spikes2(:,wire,idx == clus),3);
		s = std(spikes2(:,wire,idx == clus),0,3);
		hlines(wire,clusi,1) = line(t2,m+s,'Color',[0 0 0.75],'Visible',vis);
		hlines(wire,clusi,2) = line(t2,m-s,'Color',[0 0 0.75],'Visible',vis);
		hlines(wire,clusi,3) = line(t2,m,'Color',[0.75 0 0],'Visible',vis);
		gridlines(wire,clusi,1) = line(xx(:),xy(:),'Color',[0.5 0.5 0.5],...
			'Visible','off');
		gridlines(wire,clusi,2) = line(yx(:),yy(:),'Color',[0.5 0.5 0.5],...
			'Visible','off');
		set(ax,'YLim',[-1 1]*max_amp)
	end
	uicontrol('Style','checkbox',...
		'Units','normalized',...
		'Position',[0.96 py(clusi) 0.05 0.05],...
		'BackgroundColor',bgcolor,...
		'Value',isgood(clus),...
		'Callback',{checkbox_fcn,clus})
end

cntrl = findobj(gcf,'Tag','showlines control');
delete(cntrl)

bg = get(gcf,'Color');
uicontrol('Style','checkbox',...
	'Position',[2 2 80 20],...
	'String','Show stats',...
	'Tag','showlines control',...
	'BackgroundColor',bg,...
	'Value',showlines,...
	'Callback',@toggle_lines)

	function toggle_lines(h,evt) %#ok<INUSD>
		if showlines
			set(hlines,'Visible','off')
			showlines = false;
		else
			set(hlines,'Visible','on')
			showlines = true;
		end
	end

uicontrol('Style','checkbox',...
	'Position',[95 2 80 20],...
	'String','Show grid',...
	'Tag','showgrid control',...
	'BackgroundColor',bg,...
	'Value',showgrid,...
	'Callback',@toggle_grid)

	function toggle_grid(h,evt) %#ok<INUSD>
		if showgrid
			set(gridlines,'Visible','off')
			showgrid = false;
		else
			set(gridlines,'Visible','on')
			showgrid = true;
		end
	end

end



%--------------------------------------------------------------------------
function mymessage2(varargin)
str = sprintf(varargin{:});
msg = findobj(gcbf,'Tag','messagebox');
set(msg,'String',str)
drawnow
end
