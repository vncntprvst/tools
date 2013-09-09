
% first tests
load('testexport.mat', 'H66L4A4_22690_stim_Ch2')
waveforms_cls1=H66L4A4_22690_stim_Ch2.values(H66L4A4_22690_stim_Ch2.codes(:,1)==1,:);
waveforms_cls2=H66L4A4_22690_stim_Ch2.values(H66L4A4_22690_stim_Ch2.codes(:,1)==2,:);
PC_cls1=pca(waveforms_cls1);
PC_cls2=pca(waveforms_cls2);
figure
plot(PC_cls1(:,1))
hold on
plot(PC_cls2(:,1),'r')
figure
plot(waveforms_cls1(1,:))
hold on
plot(waveforms_cls1(2,:))
plot(waveforms_cls1(60000,:))

% now importing text files saved from Spike2 PCA window (just keep values)

figure
d = mahal(Clus2,Clus1);
scatter3(Clus1(:,1),Clus1(:,2),Clus1(:,3),10,'o')
hold on
scatter3(Clus2(:,1),Clus2(:,2),Clus2(:,3),10,d,'*','LineWidth',2)
hb = colorbar;
ylabel(hb,'Mahalanobis Distance')
legend('Cluster1','Cluster2','Cluster3','Location','NW')


% comparing across epochs

Clus1=PCAvalues(cluscodes==1,:);
Clus1_s1=Clus1(1:ceil(size(Clus1,1)/3),:);
Clus1_s2=Clus1(ceil(size(Clus1,1)/3)+1:ceil(size(Clus1,1)/3*2),:);
% Clus1_s3=Clus1(ceil(size(Clus1,1)/3*2)+1:end,:);
d1vs1 = mahal(Clus1_s1,Clus1_s1);
d2vs1 = mahal(Clus1_s2,Clus1_s1);

olvals=d2vs1(d2vs1>(mean(d1vs1)+2.5*std(d1vs1)));