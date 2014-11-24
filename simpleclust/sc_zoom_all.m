function features=sc_zoom_all(features);
% zooms into all visible, replaces what scale_features used to do


use=zeros(1,numel(features.ts));

for i=1:features.Nclusters
    if features.clustervisible(i)
        incluster=find(features.clusters==i );
        use(incluster)=1;
    end;
end;

for i=features.featureselects %:size(features.data,1)
    
    x=features.data(i,find(use));
    if numel(x)>0
    features.zoomrange(i,[1 2])=[min(x),max(x)];
    end;
    
end;

features.updatezoom=1;