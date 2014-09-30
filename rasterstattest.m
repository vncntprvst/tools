%example of raster averaging and stat test

fsigma=10;
foo=rasters(~isnantrial{cnp},:);
convrasters=NaN(size(foo,1),stop-start+2*fsigma+1);

for rast=1:sum(~isnantrial{cnp})
    convrasters(rast,:)=fullgauss_filtconv(foo(rast,start-fsigma:stop+fsigma),fsigma,0);
end

convrasters=convrasters(:,fsigma+1:end-fsigma);

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
