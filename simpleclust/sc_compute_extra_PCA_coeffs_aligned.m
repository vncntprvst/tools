function features=compute_extra_PCA_coeffs_aligned(features,mua)

features.numextrafeaatures=features.numextrafeaatures+1;


trodeboundaries = max(1,round(linspace(0,size(features.waveforms_hi,2),mua.ncontacts+1)));


mask=zeros(size(features.waveforms_hi,2),1);
mask(trodeboundaries(1:2)+12)=1;
mask=conv(mask,normpdf([-16:16],0,4),'same');
mask=min(mask,.07);

%align
algd= features.waveforms_hi;

for b=1:numel(trodeboundaries)-1
    u=[trodeboundaries(b):trodeboundaries(b+1)];
    for i=1:size(features.waveforms_hi,1)
        n=features.waveforms_hi(i,:);
        [ignore,m]=max( n(u) );
        algd(i,u)= circshift(algd(i,u)',m)';
    end;
end;

D=zeros(4,size(features.data,2));

visible = find(ismember(features.clusters, find(features.clustervisible)));

%coeffs=wave_features_wc_mod_8(mua.waveforms(visible,:)')./10;

E=algd(visible,:)';

% whiten
[coeffs,score]= princomp(zscore(E')','econ');

D(:,visible)=coeffs(:,1:4)';
for i=1:4
    features.name{size(features.data,1)+i}=['pca ',num2str(features.numextrafeaatures),'-',num2str(i)];
end;

features.data(end+1:end+4,:)=D;

features=sc_scale_features(features);