function ploteyesac(filename,trials,info)
%% quick tool to plot eye positions for a given trial, with detected saccade times

if nargin<3
    info=num2str(trials);
end

load(filename);
figure;
if length(trials)>5
    trials=trials(1,5);
end
for i=1:length(trials)
    subplot(length(trials),1,i) %ceil(length(trials)/2)
    plot(allh(trials(i),:));
    hold;
    plot(allv(trials(i),:),'r');
    goodsac=find(~cellfun(@isempty,{saccadeInfo(trials(i),:).latency}),1);
    alltimes={saccadeInfo(trials(i),:).starttime};
    alltimes=cell2mat(alltimes(~cellfun(@isempty,alltimes)));
    plot(alltimes,5*ones(1,length(alltimes)),'dk');
    if ~isempty(goodsac)
        plot(alltimes(goodsac),5,'dr');
    end
    title(info(i,:));
    hold off;
end
end

% foo=trialq(find(wrongdircode));
% foo(end-4:end)

% trialstoplot=trialq(find(wrongdircode,1,'last'))-4 ...
% :trialq(find(wrongdircode,1,'last'))
% trialangle=anglediff(find(wrongdircode,1,'last')-4 ...
% :find(wrongdircode,1,'last'))
% trialcodes= allcodes(trialstoplot,2);

% foo=trialq(find(abs(anglediff)>45));
% foo(end-4:end)
% trialstoplot=foo(end-4:end);
% foo=anglediff(find(abs(anglediff)>45));
% trialangle=foo(end-4:end)
% trialcodes= allcodes(trialstoplot,2)

% foo=92:96;
% trialstoplot=trialq(foo);
% trialangle=anglediff(foo);
% info=round([trialstoplot,trialangle,trialcodes])
% ploteyesac(trialstoplot,rexloadedname,num2str(info))


