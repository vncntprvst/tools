function rastplotstat(rasters,fsigma,twind_one,twin_two)

%raster averaging, stat test on two regions and plot



convrasters=NaN(size(rasters,1),stop-start+1);

for rast=1:sum(~isnantrial{cnp})
    convrasters(rast,:)=fullgauss_filtconv(rasters(rast,start-fsigma:stop+fsigma),fsigma,0);
end

% convrasters=convrasters(:,fsigma+1:end-fsigma);

% convrasters=convrasters(:,1000:1200);
% lowconvrasters=convrasters./10;
% closeconvrasters=convrasters./1.1;
% 
% [t df pvals] = statcond({convrasters closeconvrasters}, 'method', 'perm', 'naccu', 2000); mean(pvals)

convrasters=nanmean(convrasters).*1000;
plot(convrasters,'k');
lowconvrasters=convrasters;
lowconvrasters(1000:1100)=lowconvrasters(1000:1100)./2;
closeconvrasters=convrasters;
closeconvrasters(1000:1010)=closeconvrasters(1000:1010)-0.01;
hold on 
plot(lowconvrasters,'r');
plot(closeconvrasters,'b');


[t df pvals] = statcond({convrasters closeconvrasters}, 'method', 'perm', 'naccu', 2000); mean(pvals)
