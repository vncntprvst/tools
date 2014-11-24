function [inspk] = sc_wave_features_mod_8(spikes);
% Calculates the spike features
% adapted from wave_clus code by Rodrigo Quian Quiroga
% (see http://www.vis.caltech.edu/~rodri/Wave_clus/Wave_clus_home.htm)
spikes=spikes';
nspk=size(spikes,1);
ls = size(spikes,2);


scales=24;
inputs=8;   % how many features to compute, ~10 make sense

% CALCULATES FEATURES

cc=zeros(nspk,ls);
for i=1:nspk                                % Wavelet decomposition
    [c,l]=wavedec(spikes(i,:),scales,'haar');
    cc(i,1:ls)=c(1:ls);
end
for i=1:ls                                  % KS test for coefficient selection
    thr_dist = std(cc(:,i)) * 3;
    thr_dist_min = mean(cc(:,i)) - thr_dist;
    thr_dist_max = mean(cc(:,i)) + thr_dist;
    aux = cc(find(cc(:,i)>thr_dist_min & cc(:,i)<thr_dist_max),i);
    
    if length(aux) > 10;
        [ksstat]=test_ks(aux);
        sd(i)=ksstat;
    else
        sd(i)=0;
    end
end
[max ind]=sort(sd);
coeff(1:inputs)=ind(ls:-1:ls-inputs+1);


%CREATES INPUT MATRIX FOR SPC
inspk=zeros(nspk,inputs);
for i=1:nspk
    for j=1:inputs
        inspk(i,j)=cc(i,coeff(j));
    end
end
% for j=1:inputs
%     inspk(:,j)=inspk(:,j)/std(inspk(:,j));
% end

%PLOTS SPIKES OR PROJECTIONS
%axes(handles.projections)
%clf;
% plot(inspk(:,1),inspk(:,2),'.k','markersize',.5);
