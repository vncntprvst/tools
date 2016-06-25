function lineSelecIdx=SelectLines(waveforms,axh)

switch nargin
    case 0
        axh=gca;
        lineH=findobj(gca,'Type', 'line');
        waveforms=get(lineH,'YData');
        waveforms=vertcat(waveforms{:});
        waveforms=flip(waveforms);
    case 1
        if exist('waveforms','var')
             axh=gca;
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
[exes, ouailles] = getline(axh); 
switch size(exes,1)
    case 1
        lineSelecIdx=0;
        return;
    case 2
    otherwise
    exes=[exes(1);exes(end)];
    ouailles=[ouailles(1);ouailles(end)];
end
selection = [exes', ouailles'];
segmentExes=linspace(floor(exes(1)),floor(exes(2)),abs(diff(abs(floor(exes))))+1);
%% draw selection (for debuging purposes)
% figure('position',[1200 500 500 500]); colormap lines; cmap=colormap; hold on
% plot(linspace(selection(1),selection(2),500),linspace(selection(3),selection(4),500),'linewidth',2,'color','r');

lineSelecIdx=zeros(size(waveforms,1),length(segmentExes)-1);
for segnum=1:length(segmentExes)-1
%% find segments of waveforms 
segments=mat2cell(double([repmat(floor(segmentExes(segnum)),size(waveforms,1),1),... 
    repmat(floor(segmentExes(segnum))+1,size(waveforms,1),1),... 
    waveforms(:,linspace(floor(segmentExes(segnum)),floor(segmentExes(segnum))+1,2))]),...
    ones(size(waveforms,1),1),4);

%% draw segments
% cellfun(@(x) plot(x(1:2),x(3:4),'color',cmap(segnum,:)),segments);
% xlims=get(gca,'Xlim');
% ylims=get(gca,'Ylim');

%rubish
% segments=mat2cell([repmat(floor(selection(1)),size(waveforms,1),1),... 
%     repmat(floor(selection(1))+1,size(waveforms,1),1),... 
%     waveforms(:,floor(selection(1)):floor(selection(1))+1)],...
%     ones(size(waveforms,1),1),4);

% segments=mat2cell([repmat(floor(selection(1)),size(waveforms,1),1),... 
%     repmat(floor(selection(2)),size(waveforms,1),1),... 
%     waveforms(:,floor(selection(1))),waveforms(:,floor(selection(2)))],...
%     ones(size(waveforms,1),1),4);

% foo=arrayfun(@(exess,exese,ouayss,ouayse) line([exess exese],[ouayss ouayse]),...
%     repmat(floor(rect(1)),size(segments,1),1),...
%     repmat(floor(rect(1))+1,size(segments,1),1),...
%     segments(:,1),segments(:,2),'UniformOutput',false)

%% Find intersections
selectionIntersect=cellfun(@(x) [(InterceptFun(x,SlopeFun(x))-InterceptFun(selection,SlopeFun(selection)))/...
    (SlopeFun(selection)-SlopeFun(x)) ...
	(SlopeFun(selection)*((InterceptFun(x,SlopeFun(x))-InterceptFun(selection,SlopeFun(selection)))/...
    (SlopeFun(selection)-SlopeFun(x))))+InterceptFun(selection,SlopeFun(selection))],...
    segments,'UniformOutput',false);

%% draw intersects
% intersects=vertcat(selectionIntersect{:});
% scatter(intersects(:,1),intersects(:,2),25,cmap(segnum,:))
% set(gca,'Xlim',xlims,'Ylim',ylims);

% dissection
% foo=double(segments{607})
% (InterceptFun(foo,SlopeFun(foo))-InterceptFun(selection,SlopeFun(selection)))/(SlopeFun(selection)-SlopeFun(foo))
% (SlopeFun(selection)*((InterceptFun(foo,SlopeFun(foo))-InterceptFun(selection,SlopeFun(selection)))/...
%     (SlopeFun(selection)-SlopeFun(foo))))+InterceptFun(selection,SlopeFun(selection))

lineSelecIdx(:,segnum)=cellfun(@(inters,segs) inters(1)>min([segs(1) segs(2)])...
    & inters(1)<max([segs(1) segs(2)]) & ...
    inters(2)>min([segs(3) segs(4)]) & inters(2)<max([segs(3) segs(4)]),...
    selectionIntersect,segments);

%% draw valid intersects
% scatter(ones(sum(logical(sum(lineSelecIdx,2))),1)*segmentExes(segnum)+0.5,...
%     intersects(logical(sum(lineSelecIdx,2)),2),25,'k','filled')
% scatter(ones(sum(logical(sum(lineSelecIdx,2))),1)*segmentExes(segnum)+0.5,...
%     intersects(logical(sum(lineSelecIdx,2)),2),15,cmap(segnum,:),'filled')
% dissection
% faa=selectionIntersect{607}
% cellfun(@(foo) faa(1)>min([foo(1) foo(2)]) & faa(1)<max([foo(1) foo(2)]) & ...
%     faa(2)>min([foo(3) foo(4)]) & faa(2)<max([foo(3) foo(4)]),...
%     selectionIntersect)

end

lineSelecIdx=logical(sum(lineSelecIdx,2));

%% plot intersected waveforms
% figure; plot(waveforms(lineSelecIdx,:)')


% set(lineH(flip(lineSelecIdx)),'Visible','off')
