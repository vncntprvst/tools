function features=sc_updateclusterimages(features,mua,s_opt);



% first, update the ISI plots
for i=1:features.Nclusters
    
    % precompute ISI hist.
    
    features.isioptions(1).tmax = max(.5,features.isioptions(1).tmax);
    
    l=linspace(0,features.isioptions(1).tmax,features.isioptions(1).nbins);
    
    thisclust=find(features.clusters==i);
    if numel(thisclust)>1
        
        dt= diff(features.ts(thisclust).*1000);
        dt(dt==0)=[];
        psize=0.65;
        
        h=histc(dt,l);
        h=(h./max(h)).*psize.*.95;
        
        features.isiplots{i}=h;
    else
        features.isiplots{i}=zeros(0,features.isioptions(1).nbins);
    end;
    
end;



% now update actual cluster images
if size(features.clusterimages,3) < 12
    features.clusterimages=zeros(features.imagesize,features.imagesize,12);
end;

usefastmethod =1;

% first, if usefastmethod, interpolate up all waveforms so they look nicer
if usefastmethod
    if ~isfield(features,'waveforms_hi') % this takes up time in the first pass
        x=size(mua.waveforms,2);
        L_im=linspace(1,x,features.imagesize);
        sfact = features.imagesize/x;
        features.waveforms_hi=zeros(size(mua.waveforms,1),round(x*sfact));
        
        
        for i=1:size( mua.waveforms,1)
            
            if mod(i,4000)==0
                clf; hold on;
                fill([-2 -2 5 5],[-2 2 2 -2],'k','FaceColor',[.95 .95 .95]);
                
                plot(linspace(1,3,numel(features.waveforms_hi(i-1,:))) , 0.9*features.waveforms_hi(i-1,:)/max(features.waveforms_hi(i-1,:)) ,'k','LineWidth',22,'color',.93.*[1 1 1])
                
                
                xx=linspace(0,2*pi*(i/size( mua.waveforms,1)),100);
                plot(sin(xx).*.4,cos(xx).*.4,'k','LineWidth',22,'color',[.85 .85 .85])
                text(0,0,['interpolating waveforms']);
                
                xlim([-1.3, 3.3]);     ylim([-1.3, 1.2]);
                daspect([1 1 1]);set(gca,'XTick',[]); set(gca,'YTick',[]);
                
                
                drawnow;
            end;
            
            
            
            features.waveforms_hi(i,:) = interp1(1:x,mua.waveforms(i,:),L_im, 'linear'); % use 'linear' for speed or even 'nearest'
        end;
    end;
end;



%npoints=numel(mua.ts_spike);
npoints=size(mua.waveforms,2);

ll=(linspace(-.1,.1,features.imagesize).*4.8)./features.waveformscale;

% if the last manipulation was a +,-,or *, then the only clusters that are
% affected are NULl and the slected cluster, so we can restrict the image
% upates to these two clusters and save a LOT of time:
if ~exist('features.last_op_was_from_any')
    features.last_op_was_from_any=1;
end;

if features.last_op_was_from_any
    clusters_to_update = 1:features.Nclusters;
else
    clusters_to_update =[1 features.editedcluster];
end;


for i=clusters_to_update
    
    
    features.clusterimages(:,:,i)=zeros(features.imagesize,features.imagesize);
    
    inthiscluster=find(features.clusters==i);
    
   % if numel(inthiscluster)==1
   %     g=g';
   % end;
    
    % only use some of the waveforms for very large clusters, tweak the
    % numbers, its just a guess for now
    if numel(inthiscluster) > 50000
        ds_factor = s_opt.skipevery_wf_display;
        
    elseif numel(inthiscluster) > 5000
        ds_factor  = ceil(s_opt.skipevery_wf_display/2);
        
    else
        ds_factor  = 1;
        
    end;
    
    
    for k=1:features.imagesize % go trough image instead of waveform points, for speed and image quality
        x = k;
        %features.clusterimages(:,x,i) = histc( features.waveforms_hi(inthiscluster, round(sc_remap(k,1,features.imagesize,1,size(mua.waveforms,2)))  ) , ll*6 );
        

        
        if numel(inthiscluster) >0
            features.clusterimages(:,x,i) = histc( features.waveforms_hi(inthiscluster(1:ds_factor:end), k ) , ll ) ;
        else
            features.clusterimages(:,x,i) =  1;
        end;
        
    end;
    
    
end;




