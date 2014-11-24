function plot_cluster_info(features,i)

xpos=2.5;
ypos=1;

features.isioptions(i).tmax = max(1,features.isioptions(1).tmax);

psize=0.65;

l=linspace(0,features.isioptions(1).tmax,features.isioptions(1).nbins);

thisclust=find(features.clusters==i);

dt= diff(features.ts(thisclust).*1000);
dt(dt==0)=[];

h=histc(dt,l);
h=(h./max(h)).*psize.*.95;

plot([0 psize]+xpos, [0 0]+ypos,'k' );
plot([0 psize]+xpos, [0 0]+ypos-psize,'k' );
plot([psize psize]+xpos, [0 -psize]+ypos,'k' );
plot([0 0]+xpos, [0 -psize]+ypos,'k' );


stairs(linspace(0,psize,features.isioptions(1).nbins)+xpos,h+ypos-psize);
text(xpos,ypos-psize-.1,'0');
text(xpos+psize/2,ypos-psize-.1,'ms');
text(xpos+psize-0.1,ypos-psize-.1,num2str(features.isioptions(1).tmax));