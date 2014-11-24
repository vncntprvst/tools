function features=add_isi_feature(features,mua)

features.numextrafeaatures=features.numextrafeaatures+1;

D=zeros(1,size(features.data,2));


visible = find(ismember(features.clusters, find(features.clustervisible)));

isis=[0,diff(features.ts(visible))];

D(visible)=isis';

features.name{size(features.data,1)+1}=['isi'];

features.data(end+1,:)=D;

features=sc_scale_features(features);