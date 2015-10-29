function pkOffsets=latency_analysis(behavData,neuralData)

% Latency Analysis
%
% We used an alignment algorithm to find a relative temporal offset for the
% neural and behavior data on each trial as follows. Single-trial PETHs
% were generated as described previously.
%
% We examined a 2 s window around the Go signal (-1.5 s pre, to +0.5 s
% post). Spikes from each trial were smoothed with a causal half-Gaussian
% kernel with a full-width SD of 200 ms—that is, the firing rate reported
% at time t averages over spikes in an  200-ms-long window preceding t. The
% resulting smooth traces were sampled every 10 ms.
%
% Then a trial-averaged PETH was generated for each cell. For each trial we
% found the time of the peak of the cross-correlation function between the
% PETH for that trial and the trial-averaged PETH. We then shifted each
% trial accordingly and iterated this process until the variance of the
% trial-averaged PETH converged. Usually this process required fewer than 5
% iterations. The output of this alignment procedure was an offset time for
% each trial, which indicated the relative neural latency for that trial.
% We performed the same alignment procedure on head-velocity data acquired
% with the video-tracking system, which produced a relative behavioral
% latency for each trial. We then tested whether the neural latency was
% correlated with the behavioral latency and whether for the population the
% average correlation was significantly different than zero (Bootstrapped
% confidence intervals of the mean). We also compared, in the same way, the
% neural latencies of pairs of simultaneously recorded neurons.
%
% Population analysis
% To perform population analyses of firing rates, we first normalized the
% perievent time histograms (PETHs) of each cell by computing the mean and
% standard deviation (over time and over trial classes) of the cell’s
% PETHs, and then subtracted that mean and divided by that standard
% deviation. The resulting zscored PETHs were then averaged across cells to
% obtain z-scored population PETHs.
%

[pkOffsets,peth]=deal(cell(size(neuralData,1),1));
sigma=200;
for rec=1:size(neuralData,1)
    for trial=1:size(neuralData{rec,2},1)
        trialconv = fullgauss_filtconv(neuralData{rec,2}(trial,neuralData{rec,3}-(1000+3*sigma):neuralData{rec,3}+3*sigma+199),sigma,1).*1000;
        peth{rec,1}(trial,:) = trialconv(1:10:end);%downsample
    end
    [sortedRT,sortedRTidx]=sort(behavData{rec, 3})
    peth{rec,1}=peth{rec,1}(sortedRTidx,:);
    sortedTgt=cellfun(@(x) x(1),neuralData{rec, 4}(sortedRTidx))-(neuralData{rec,3}-1000);    
    sortedSac=sortedRT+sortedTgt;
    sortedTgt=round(sortedTgt/10);%downsample
    sortedSac=round(sortedSac/10);%downsample
end

% sort trials by RT
 
figure; hold on;
imagesc(1:size(peth{rec,1},2),1:size(peth{rec,1},1),peth{rec,1});
tgth=plot(sortedTgt,1:size(peth{rec,1},1),'Marker','d','MarkerEdgeColor','k','MarkerFaceColor',[0.9, 1, 0.7]);
plot(sortedSac,1:size(peth{rec,1},1),'Marker','.','MarkerEdgeColor','k','MarkerFaceColor',[1, 0.5, 0.9]);
cbh=colorbar;
cbh.Label.String = 'Firing rate (Hz)';
set(gca,'xticklabel',-800:200:200,'TickDir','out','FontSize',10); %'xtick',1:100:max ...
xlabel('Time, aligned to saccade')
ylabel('Trial #')
legend(tgth,'Target On','location','Southwest')
title('Trials sorted by reaction time')
axis('tight');
