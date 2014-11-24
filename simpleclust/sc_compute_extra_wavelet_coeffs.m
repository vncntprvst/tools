function features=sc_compute_extra_wavelet_coeffs(features,mua)

features.numextrafeaatures=features.numextrafeaatures+1;

D=zeros(8,size(features.data,2));

visible = find(ismember(features.clusters, find(features.clustervisible)));

coeffs=sc_wave_features_wc_mod_8(mua.waveforms(visible,:)')./10;


D(:,visible)=coeffs';
for i=1:8
    features.name{size(features.data,1)+i}=['wvl ',num2str(features.numextrafeaatures),'-',num2str(i)];
end;

features.data(end+1:end+8,:)=D;

features=sc_scale_features(features);