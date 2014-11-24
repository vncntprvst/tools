function features=sc_scale_features(features);
%{
use=zeros(1,numel(features.ts));

for i=1:features.Nclusters
    if features.clustervisible(i)
        incluster=find(features.clusters==i );
        use(incluster)=1;
    end;
end;
%}
margin=0.1;
for i=1:size(features.data,1)
    
    x=features.data(i,:);
         features.range(i,[1 2])=[min(x),max(x)];
          features.zoomrange(i,[1 2])=[min(x),max(x)];
         
    %{
    
    if size(features.range,1) <i % if none exist, alwasy recompute
         features.range(i,[1 2])=[min(x),max(x)];
    end;
    
    if  (features.range(i,1) ==  0) &&  (features.range(i,2) ==  0) % if this feature is saled already, dont update the range, or else it will be -1 1 or -.9 .9 or something..
        features.range(i,[1 2])=[min(x),max(x)];
        
    else % instead, change ranges based on old range and new scaling!
        new_min= min(x(find(use)));
        new_max= max(x(find(use)));
        
        features.range(i,1) = features.range(i,1) * (-(1-margin) / new_min);
        features.range(i,2) = features.range(i,2) * ((1-margin) / new_max);
        
    end;
    
    
    x=x-min(x(find(use))); x=x./max(x(find(use))); x=x*(2-margin*2); x=x-(1-margin);
    features.data(i,:)=x;
    %}
end;
