function features=intersect_cluster(features,i,s_opt,featureselects)


[px,py] =sc_getpolygon(features,features.colors(i,:));


if i>1
    inthiscluster=find(features.clusters==i);
else    % if we're intersecting the null cluster, just take out from any other cluster and assign rest to noise
    inthiscluster=find(features.clusters>0);
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

if i==1 %if called from null cluster, move all outside selection to noise
    features.clusters(inthiscluster(~in))=2;
    % if we're adding from all to noise, also zoom in to fit all visible
    features=sc_zoom_all(features);
else
    features.clusters(inthiscluster(~in))=1;
end;