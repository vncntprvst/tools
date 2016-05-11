function lineSelecIdx=SelectLines(waveforms,figh)

switch nargin
    case 0
        figh=gcf;
        lineH=findobj(gca,'Type', 'line');
        waveforms=get(lineH,'YData');
        waveforms=vertcat(waveforms{:});
        waveforms=flip(waveforms);
    case 1
        if exist('waveforms','var')
             figh=gcf;
        else
            lineH=findobj(gca,'Type', 'line');
            waveforms=get(lineH,'YData');
            waveforms=vertcat(waveforms{:});
        end
end

%declare functions
SlopeFun = @(line) (line(1,4) - line(1,3))/(line(1,2) - line(1,1));
InterceptFun = @(line,m) line(1,3) - m*line(1,1);

% rectangle selection
% rect = getrect; %rect is a four-element vector with the form [xmin ymin width height]
% selection = [rect(1) rect(1)+rect(3) rect(2)+rect(4) rect(2)];

% line selection 
[exes, ouays] = getline(figh);    
selection = [exes', ouays'];

% draw selection (for debuging purposes)
% line(selection(1:2),selection(3:4));

segments=mat2cell([repmat(floor(selection(1)),size(waveforms,1),1),... 
    repmat(floor(selection(1))+1,size(waveforms,1),1),... 
    waveforms(:,floor(selection(1)):floor(selection(1))+1)],...
    ones(size(waveforms,1),1),4);

% foo=arrayfun(@(exess,exese,ouayss,ouayse) line([exess exese],[ouayss ouayse]),...
%     repmat(floor(rect(1)),size(segments,1),1),...
%     repmat(floor(rect(1))+1,size(segments,1),1),...
%     segments(:,1),segments(:,2),'UniformOutput',false)

selectionIntersect=cellfun(@(x) [(InterceptFun(x,SlopeFun(x))-InterceptFun(selection,SlopeFun(selection)))/...
    (SlopeFun(selection)-SlopeFun(x)) ...
	(SlopeFun(selection)*((InterceptFun(x,SlopeFun(x))-InterceptFun(selection,SlopeFun(selection)))/...
    (SlopeFun(selection)-SlopeFun(x))))+InterceptFun(selection,SlopeFun(selection))],...
    segments,'UniformOutput',false);
% 
% foo=segments{1}
% (InterceptFun(foo,SlopeFun(foo))-InterceptFun(rect,SlopeFun(rect)))/(SlopeFun(rect)-SlopeFun(foo))
% (SlopeFun(rect)*((InterceptFun(foo,SlopeFun(foo))-InterceptFun(rect,SlopeFun(rect)))/...
%     (SlopeFun(rect)-SlopeFun(foo))))+InterceptFun(rect,SlopeFun(rect))

lineSelecIdx=cellfun(@(x) x(1)>min([selection(1) selection(2)]) & x(1)<max([selection(1) selection(2)]) & ...
    x(2)>min([selection(3) selection(4)]) & x(2)<max([selection(3) selection(4)]),...
    selectionIntersect);

% 
% foo=selectionIntersect{1}
% cellfun(@(foo) foo(1)>min([selection(1) selection(2)]) & foo(1)<max([selection(1) selection(2)]) & ...
%     foo(2)>min([selection(3) selection(4)]) & foo(2)<max([selection(3) selection(4)]),...
%     selectionIntersect)

% set(lineH(flip(lineSelecIdx)),'Visible','off')
