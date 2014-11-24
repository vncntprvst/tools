function [h, p, sign] = rastplotstat(rasters,fsigma,twind_one,twin_two,plotwind)
%raster averaging, stat test on two regions and plot

convrasters_one=NaN(size(rasters,1),diff(twind_one)+2*(3*fsigma)+1); %kernel's linear space is 6 sigma
for rast=1:size(rasters,1)
    convrasters_one(rast,:)=fullgauss_filtconv(rasters(rast,twind_one(1)-3*fsigma:twind_one(2)+3*fsigma),fsigma,0);
end

convrasters_one=convrasters_one(:,3*fsigma+1:end-3*fsigma);
convrasters_one=nanmean(convrasters_one).*1000;

convrasters_two=NaN(size(rasters,1),diff(twin_two)+2*(3*fsigma)+1);
for rast=1:size(rasters,1)
    convrasters_two(rast,:)=fullgauss_filtconv(rasters(rast,twin_two(1)-3*fsigma:twin_two(2)+3*fsigma),fsigma,0);
end

convrasters_two=convrasters_two(:,3*fsigma+1:end-3*fsigma);
convrasters_two=nanmean(convrasters_two).*1000;

[sign, ~, p] = statcond({convrasters_one convrasters_two}, 'method', 'perm', 'naccu', 20000);
h=p<0.01;
% [p, h] = signrank(convrasters_one, convrasters_two)
% [p, pvals]
% sign=mean(convrasters_one-convrasters_two);

%% full raster
% convrasters_all=NaN(size(rasters,1),size(rasters,2)-2*(3*fsigma)+1);
% for rast=1:size(rasters,1)
%     convrasters_all(rast,:)=fullgauss_filtconv(rasters(rast,3*fsigma:size(rasters,2)-3*fsigma),fsigma,0);
% end
% convrasters_all=convrasters_all(:,3*fsigma+1:end-3*fsigma);
% convrasters_all=nanmean(convrasters_all).*1000;
% figure
% plot(convrasters_all)

%% plots
if plotwind
    figure;
    plot([1:length(convrasters_one)],convrasters_one,'b');
    hold on;
    plot([length(convrasters_one)+2:(length(convrasters_one)+1+length(convrasters_two))],convrasters_two,'r');
    hold off;
    ylim=get(gca,'ylim');
    set(gca,'ylim',[0 ylim(2)+1]);
    if h
        text(5,3,['sign = ' num2str(sign)])
    end
    legend('pre','post','location','SouthEast');
end
end
