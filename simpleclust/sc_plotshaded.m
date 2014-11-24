function varargout = sc_plotshaded(x,y_hilo,color);

% x        x coordinates
% y_hi     upper limit of shaded region
% y_lo     lower "
%
% example
% x=[-10:.1:10];plotshaded(x,[sin(x.*1.1)+1;sin(x*.9)-1],'r');

if size(y_hilo,1)>size(y_hilo,2)
    y_hilo=y_hilo';
end;

c=color;
if isa(color,'char')
    
    color=strrep(color,'-','');
    % make colors nicer
    switch color
        case 'r'
            color=[1 0 0];
        case 'g'
            color=[.2 .6 0];
        case 'b'
            color=[0 0 1];
        case 'k'
            color=[0 0 0];
        case 'kk'
            color=[0.5 0.5 0.5];
        case 'c'
            color=[0 .5 .5];
        case 'p'
            color=[1 .5 .3];
        case 'y'
            color=[1 .95 .0];
        otherwise
            color=[0 0 1];
    end;
end;

%plot(x,y,'color',color); % plot median

%plot .25,.75 quartiles
px=[x,fliplr(x)];
py=[y_hilo(1,:), fliplr(y_hilo(2,:))];
patch(px,py,1,'FaceColor',color,'EdgeColor','none');

alpha(.2); % make patch transparent