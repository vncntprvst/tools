function features=add_to_cluster(features,i,s_opt,featureselects)


[px,py] =sc_getpolygon(features,features.colors(i,:));

use=zeros(1,numel(features.ts));

for j=1:features.Nclusters
    if features.clustervisible(j)
        incluster=find(features.clusters==j );
        use(incluster)=1;
    end;
end;


if i>1
    notassigned=find(use.*(features.clusters==1));
else    % if we're 'adding' to the null closuer, take from all other clusters.
    %this is equivalent to removing points from clusters
    
    notassigned=find(features.clusters>0);
    
end;



dX=features.data(features.featureselects(1),notassigned);
dY=features.data(features.featureselects(2),notassigned);

if ~s_opt.mex_intersect
    in = inpolygon(dX,dY,px,py); % slow matlab method
else
    % WAY faster Fast InPolygon detection MEX by Guillaume JACQUENOT
    % from http://www.mathworks.com/matlabcentral/fileexchange/20754-fast-inpolygon-detection-mex
    in = InPolygon(dX,dY,px,py);
end;


features.clusters_undo=features.clusters;
features.clusters(notassigned(in))=i;
