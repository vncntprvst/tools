function features = mua2features(mua,s_opt)

%writes a spike param file for tetrode data
% should do stereotrodes and tetrodes now

%D=(squeeze(reshape(tt.waveforms,1,32*size(tt.waveforms,1),size(tt.waveforms,3) )));

D=mua.waveforms;

if size(D,2)>size(D,1)
    warning('fewer spikes than samples in waveform, sorting this doesnt make much sense');
    % simply padding D will probbaly fix this if you really want to sort something like this
end;

if numel(mua.ts)<size(mua.waveforms,1)
    warning('fewer spikes than waveforms, truncating!');
    mua.waveforms = mua.waveforms(1:numel(mua.ts),:);
end;



%% get Wavelet coeffs


if s_opt.features.wavelet % disabled because this takes up too much time and users can justcompute these manually
    
    disp('  computing Wavelet features...')
    
    coeffs=sc_wave_features_wc_mod_8(D')./10;
    
    
    %clf; hold on;
    
    D=coeffs;
end;

%% do PCA features

if s_opt.features.pca
    disp('  precalculating PCA ...')
    
    
    clf; hold on
    fill([-2 -2 5 5],[-2 2 2 -2],'k','FaceColor',[.95 .95 .95]);
    x=linspace(0,2*pi,80);
    plot(sin(x).*.4,cos(x).*.4,'k','LineWidth',22,'color',[1 1 1])
    
    text(0,0,['precalculating PCA']);
    xlim([-1.3, 3.3]);     ylim([-1.3, 1.2]);
    daspect([1 1 1]);set(gca,'XTick',[]); set(gca,'YTick',[]);
    drawnow;
    
    
    mua.waveforms(isinf(mua.waveforms(:)))=0; % open ephys seems to return inf sometimes??
    
    [coeffs,score]= princomp((mua.waveforms)','econ');
    
    if size(mua.waveforms,1)>8
        
        D=coeffs(:,1:8)';
        
    else
        
        D=zeros(size(mua.waveforms,1),8);
    end;
    %plot(coeffs(:,1),coeffs(:,2),'.','MarkerSize',.5)
else
    coeffs=[];
    D=zeros(size(mua.waveforms,1),8);
end;
disp('  making features ..')

features=[];

%% precalculate energy too, is faster this way


trodeboundaries = max(1,round(linspace(0,size(mua.waveforms,2),mua.ncontacts+1)));

if  s_opt.features.nonlinear_energy
    
    clf; hold on
    fill([-2 -2 5 5],[-2 2 2 -2],'k','FaceColor',[.95 .95 .95]);
    x=linspace(0,2*pi,80);
    plot(sin(x).*.4,cos(x).*.4,'k','LineWidth',22,'color',[1 1 1])
    
    text(0,0,['precalculating nonlinear energy']);
    xlim([-1.3, 3.3]);     ylim([-1.3, 1.2]);
    daspect([1 1 1]);set(gca,'XTick',[]); set(gca,'YTick',[]);
    drawnow;
    
    nle=zeros(mua.ncontacts,mua.Nspikes);
    for d=1:mua.ncontacts %size(spike,1)
        x=mua.waveforms(:,trodeboundaries(d):trodeboundaries(d+1));
        nle(d,:) = mean( (x(:,2:end-1).^2 - ( x(:,1:end-2) .* x(:,3:end) ))' )*10;        
    end;
end;

%% write data


features.data=zeros(6,length(mua.ts));

lastpercent=0;

features.ts=mua.ts;
features.id=[1:length(mua.ts)];

for n = 1:length(mua.ts)
    
    
    percent=round(100*n./length(mua.ts));
    if percent>lastpercent
        clf; hold on;
        fill([-2 -2 5 5],[-2 2 2 -2],'k','FaceColor',[.95 .95 .95]);
        
        x=linspace(0,2*pi*percent./100,100);
        plot(sin(x).*.4,cos(x).*.4,'k','LineWidth',22,'color',[.85 .85 .85])
        text(0,0,['making features ',num2str(percent),'%']);
        
        xlim([-1.3, 3.3]);     ylim([-1.3, 1.2]);
        daspect([1 1 1]);set(gca,'XTick',[]); set(gca,'YTick',[]);
        
        drawnow;
    end;
    
    lastpercent=percent;

    c=0;
    
    spike = squeeze(mua.waveforms(n,:))./20;

    % spike time
    c=c+1;
    features.data(c,n)=mua.ts(n);
    
    if n==1; features.name{c}=['time']; end;
    
    %peak height
    for d=1:mua.ncontacts %size(spike,1)
        x=spike(trodeboundaries(d):trodeboundaries(d+1)-1);
        neo(d) =max(x);
        
        c=c+1;
        features.data(c,n)= neo(d);
        
        if n==1; features.name{c}=['peak ',num2str(d)]; end;
        
    end;
        
    %calculate Nonlinear energy (Teager energy operator)
    if s_opt.features.nonlinear_energy
        for d=1:mua.ncontacts %size(spike,1)
            c=c+1;
            features.data(c,n)= nle(d,n);
            
            if n==1; features.name{c}=['energy ',num2str(d)]; end;
            
        end;
    end;
    
    % put in PCA features
    if size(coeffs,2)>2
        pc = coeffs(n,1:8).*100;
    else
        pc = [0 0 0 0 0 0 0 0 0];
    end;
    
    %{
    for i=1:8
        c=c+1;
        features.data(c,n)= pc(i);
        if n==1; features.name{c}=['PCA ',num2str(i)]; end;
    end;
    %}
    
    
    % max. derivative
    if s_opt.features.max_derivative
        c=c+1;
        if numel(spike)>1
            features.data(c,n)=max(abs(diff(spike)));
        else
            features.data(c,n)=0;
        end;
        if n==1; features.name{c}=['maxD']; end;
    end;
    
end

clf; hold on;
fill([-2 -2 5 5],[-2 2 2 -2],'k','FaceColor',[.95 .95 .95]);
x=linspace(0,2*pi,80);
plot(sin(x).*.4,cos(x).*.4,'k','LineWidth',22,'color',[.9 .9 .9])

text(0,0,['done, setting up display..']);
xlim([-1.3, 3.3]);     ylim([-1.3, 1.2]);
daspect([1 1 1]);set(gca,'XTick',[]); set(gca,'YTick',[]);
drawnow;

