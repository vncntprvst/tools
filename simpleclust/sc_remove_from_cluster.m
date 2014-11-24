function features=sc_remove_from_cluster(features,i,s_opt,featureselects)


[px,py] =sc_getpolygon(features,features.colors(i,:));



if i>1
    inthiscluster=find(features.clusters==i);
else    % if we're removing the null cluster, do nothing obvs
    
    inthiscluster=[];
    
end;
dX=features.data(features.featureselects(1),inthiscluster);
dY=features.data(features.featureselects(2),inthiscluster);

if ~s_opt.mex_intersect
    in = inpolygon(dX,dY,px,py); % slow matlab method
else
    % WAY faster Fast InPolygon detection MEX by Guillaume JACQUENOT
    % from http://www.mathworks.com/matlabcentral/fileexchange/20754-fast-inpolygon-detection-mex
    in = InPolygon(dX,dY,px,py);
end;

features.clusters_undo=features.clusters;
features.clusters(inthiscluster(in))=1;