
function sc_plotinbox(x,y,fstr,c,s)


%plot([-1 1],[0 0],'color',[.5 .5 .5]);
%plot([0 0],[-1 1],'color',[.5 .5 .5]);

%x=x-min(x); x=x./max(x); x=x*2; x=x-1;
%y=y-min(y); y=y./max(y); y=y*2; y=y-1;


%x=x./max(abs(x));
%y=y./max(abs(y));

if s==1
    m=5;
    fstr='kx';
else
    m=.5;
    fstr='k.';
end;

plot(x,y,fstr,'color',c,'MarkerSize',m)

plot([-1 -1],[-1 1],'k');
plot([1 1],[-1 1],'k');
plot([-1 1],[1 1],'k');
plot([-1 1],[-1 -1],'k');