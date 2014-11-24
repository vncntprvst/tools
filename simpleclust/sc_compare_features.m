function sc_compare_features(features,mua)
% display comparisons between clusters

figure(2); clf; hold on;

n=sum(features.clustervisible(1:features.Nclusters));
useclusters=find(features.clustervisible(1:features.Nclusters));
%n=features.Nclusters;

nsp=max(4,n);

mseclimit=15;

for ii=1:n
    for jj=ii:n
        
        i=useclusters(ii);
        j=useclusters(jj);
        
        subplot(nsp,nsp,ii+((jj-1)*nsp));
        
        in_a=find(features.clusters==i);
        in_b=find(features.clusters==j);
        
        if i==j % acorr
            [l,c] =  sc_acorr(mua.ts(in_a)'.*1000, mseclimit,50);
        else % xcorr
            [l,c] =  sc_sxcorr(mua.ts(in_a)'.*1000, mua.ts(in_b)'.*1000, mseclimit,50);
        end;
        
        
        
        stairs(l,c,'color',features.colors(j,:)); hold on;
        xlim([min(l) max(l)]);
        if (ii==1)
            ylabel(['cluster ',num2str(j)]);
        end;
        
        if (jj==n)
            xlabel(['cluster ',num2str(i),'- lag (ms)']);
        end;
        
        plot(0,0,'k.','MarkerSize',20,'color',features.colors(i,:))
        
    end;
end;

features=sc_updateclusterimages(features,mua);

subplot(nsp,nsp, [3 4 nsp+3 nsp+4]); hold on;
for ii=1:n
    
    i=useclusters(ii);
    
    inthiscluster=find(features.clusters==i);
    
    q= quantile(features.waveforms_hi(inthiscluster, : ) ,[.1 .25 .5 .75 .9]);
    
    if isfield(mua,'val2volt')
        q = q.*mua.val2volt(1).*10e6;
    end;
    
    sc_plotshaded(linspace(min(mua.ts_spike),max(mua.ts_spike),size(q,2)),q([2 4],:),features.colors(i,:));
    sc_plotshaded(linspace(min(mua.ts_spike),max(mua.ts_spike),size(q,2)),q([1 5],:),features.colors(i,:));
    plot(linspace(min(mua.ts_spike),max(mua.ts_spike),size(q,2)), q([3],:) ,'k-','color',features.colors(i,:));
    
end;

set(gca,'Color',[0.2 0.2 0.2]);
grid on;
ylabel('uV (and .75 and .9 quantiles)');
xlabel('t (ms)');