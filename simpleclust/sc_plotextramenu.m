function extramenu(features)

pos=[-1 -.7 -.6 -.5];


i=1;

plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);

text(pos(i)+0.02,-1.05,'wavelet vis.');



i=2;

plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);

text(pos(i)+0.02,-1.05,'wf+');

i=3;

plot([1 1].*pos(i) ,[-1.1 -1],'color',[.7 .7 .7]);
plot([1 1].*pos(i+1) ,[-1.1 -1],'color',[.7 .7 .7]);

text(pos(i)+0.02,-1.05,'wf-');