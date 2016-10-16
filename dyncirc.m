function [p,r,h]=dyncirc(h,mode)
% Plot a circle dynamically
%
% [p r h]=dyncirc(h, mode)
%
% h: figure number
% if mode='modal' the function is modal and will not return
% until a cicle has been drawn.

% Copyright, 2001.02.02
% Lars Gregersen <lars.gregersen@it.dk>

persistent cp circx circy circh radius mod

if ~isstr(h)
    if nargin==2
        mod = mode;
    else
        mod = '';
    end
    
    set(get(h,'children'),'buttondownfcn', [mfilename ' down;'])
    set(h,'doublebuffer','on',...
        'backingstore','off')
    r = (0:0.1:2*pi)';
    circx = sin(r);
    circy = cos(r);
    
    if strcmp(mod,'modal')
        uiwait(h)
        p = cp;
        r = radius;
        h = circh;
        
        set(get(h,'children'),'buttondownfcn', '')
%         set(h,'doublebuffer','off')
    end
    
else
    switch h
    case 'down'
        if ~strcmp(get(gcf,'selectiontype'), 'normal'), return, end
        
        set(gcbf,'windowbuttonmotionfcn',[mfilename ' move;'])
        set(gcbf,'windowbuttonupfcn',[mfilename ' up;'])
        
        ax = gca;
        p = get(ax,'currentpoint');
        cp = p([1 3]);
        set(ax, 'xlimmode', 'manual', 'ylimmode','manual');
        set(gcf, 'pointer', 'fleur')
        circh = line(circx*0+cp(1), circy*0+cp(2), ...
            'linestyle', ':', 'color', 'k', 'tag', 'circ');
        
    case 'move'
        p = get(gca,'currentpoint');
        p = p([1 3]);
        radius = sqrt(sum((p-cp).^2));
        set(circh, 'xdata', circx*radius+cp(1))
        set(circh, 'ydata', circy*radius+cp(2))
        drawnow
        
    case 'up'
        hf = gcf;
        set(hf,'windowbuttonmotionfcn','')
        set(hf,'windowbuttonupfcn','')
        set(hf, 'pointer', 'arrow')
        set(gca, 'xlimmode', 'auto', 'ylimmode','auto');
        
        set(circh, 'userdata', [cp radius])
        
        if strcmp(mod,'modal')
            uiresume(hf)
        end
    end
end