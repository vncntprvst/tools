function [features,mua]=sc_addotherchannelstomua(features,mua)
% load multiple files and just keep the spike times to use in a feature
% that counts co-occurrence of spikes across channels

mua.otherchannels=[];

for i=1:numel(features.otherchannelfiles)
    
   
    clf; hold on
    fill([-2 -2 5 5],[-2 2 2 -2],'k','FaceColor',[.95 .95 .95]);
    x=linspace(0,2*pi,80);
    plot(sin(x).*.4,cos(x).*.4,'k','LineWidth',22,'color',[1 1 1])
    
    text(0,0,['loading extra channel ',num2str(i),'/',num2str(numel(features.otherchannelfiles))]);
    xlim([-1.3, 3.3]);     ylim([-1.3, 1.2]);
    daspect([1 1 1]);set(gca,'XTick',[]); set(gca,'YTick',[]);
    drawnow;
    
    
    [features_tmp,mua_tmp]=sc_loadmuadata(fullfile(features.muafilepath,features.otherchannelfiles{i}),0,[]);
    mua.overlapchannels{i}.ts=mua_tmp.ts;
    
end;

% now compute 'overlap' feature

N_compare=numel( mua.overlapchannels); % how many otther channels are there


use_loop=0; % do loop method, or straight huge histograms?

features.numextrafeaatures=features.numextrafeaatures+1;
features.name{size(features.data,1)+1}=['Ch.overlap'];


if use_loop
    
    % instead do coarse histogram, use it as lookup table to allow fast spike
    % by spike comparisons
    lookup_binsize = 1; % in ms, smaller -> more ram use, larger -> more cpu time
    tbins=[min(mua.ts):lookup_binsize/1000:max(mua.ts)];
    
    [h_this,spikebins]=histc(mua.ts,tbins);
    
    
    
    h_others=zeros(numel(tbins), numel(mua.otherchannels) );
    for j=1:numel(mua.otherchannels)
        [h_others(:,j),otherbins{j}]=histc(mua.otherchannels{j}.ts ,tbins);
    end;
    
    % now identify overlap for each spike
    lastpercent=0;
    Noverlap=zeros(size(mua.ts));
    for i=1:numel(mua.ts)
        
        
        if rem(i,100)==0
            percent=round(100*i./length(mua.ts));
            if percent>lastpercent
                clf; hold on;
                fill([-2 -2 5 5],[-2 2 2 -2],'k','FaceColor',[.95 .95 .95]);
                
                x=linspace(0,2*pi*percent./100,100);
                plot(sin(x).*.4,cos(x).*.4,'k','LineWidth',22,'color',[.85 .85 .85])
                text(0,0,['computing overlap ',num2str(percent),'%']);
                
                xlim([-1.3, 3.3]);     ylim([-1.3, 1.2]);
                daspect([1 1 1]);set(gca,'XTick',[]); set(gca,'YTick',[]);
                
                drawnow;
            end;
            lastpercent=percent;
        end;
        
        
        Noverlap(i)=0;
        if spikebins(i) >0 % ignore those that are not in histc
            if sum(h_others(spikebins(i)))>0 % any?
                for j=1:numel(mua.otherchannels) % for all others
                    if h_others(spikebins(i),j)>0
                        
                        otherid = find( otherbins{j}==spikebins(i) ); % find other spikes in same bin
                        % look also in neighboring bins!
                        otherid = [otherid; find( otherbins{j}==spikebins(i)+1 )];
                        otherid = [otherid; find( otherbins{j}==spikebins(i)-1 )];
                        
                        if min(abs( mua.ts(i)- mua.overlapchannels{j}.ts(otherid) )) < .2/1000; % chance timw window here, or even add penalty based on D_t?
                            Noverlap(i)=Noverlap(i)+1;
                        end;
                        
                    end;
                end;
            end;
        end;
    end;
    
    
else % just use histograms, way faster
    
    tbins=[min(mua.ts):0.1/1000:max(mua.ts)]; % make .1ms +-1 ms bins (this will blow up for big files on small machines)
    tbins=max(tbins,1);
    
    Noverlap=zeros(size(mua.ts));
    N_used=0; % count how many were actually used
    
    h_this=sparse(zeros(numel(tbins), 1));
    
    [h_this,this_bins]=histc(mua.ts ,tbins);
    this_bins=max(1,this_bins); % hack
    h_this=conv(h_this,[.5  1 .5],'same'); % avoid edge effects
    
    this_bins=max(this_bins,1);
    % h_others=sparse(zeros(numel(tbins), numel(mua.otherchannels) ));
    for j=1:numel(mua.otherchannels)
        
        
        clf; hold on
        fill([-2 -2 5 5],[-2 2 2 -2],'k','FaceColor',[.95 .95 .95]);
        x=linspace(0,2*pi,80);
        plot(sin(x).*.4,cos(x).*.4,'k','LineWidth',22,'color',[1 1 1])
        
        text(0,0,['processing extra channel ',num2str(j),'/',num2str(numel(features.otherchannelfiles))]);
        xlim([-1.3, 3.3]);     ylim([-1.3, 1.2]);
        daspect([1 1 1]);set(gca,'XTick',[]); set(gca,'YTick',[]);
        drawnow;
        
        
        h_other=histc(mua.overlapchannels{j}.ts ,tbins);
        if numel(h_other)>0
            ovr=(h_this .* h_other);
            Noverlap(1:end-1)=Noverlap(1:end-1)+  ovr(this_bins(1:end-1));
            N_used=N_used+1;
        end;
    end;
    
    
end;

if N_used > 0
    features.data(end+1,:)=((Noverlap+ randn(size(Noverlap)).*.6 )/N_used);
else
    features.data(end+1,:)= zeros(size(mua.ts));
    disp('no other channels with spikes were found, channel overlap feature is empty');
end;
features=sc_scale_features(features);
