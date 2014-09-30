function [cnt, pd] = countprob(spk,interval,maxcount,dt)
% countprob: function which returns the probability density for the 
% distribution of the spike count in a fixed time interval. If called
% without output arguments, the distribution of spike count is
% plotted. 
%
%	[cnt, pd] = countprob(x,interval,maxcount,dt)
%
%	where 
%	  x = the vector containing the spike data
%	  interval = the length of the interval (in msec)
%	  maxcount = maximal count taken into account
%	  dt = the sampling step of the spike train (msec)
%
% The return parameters are:
%	cnt = vector of spike counts.
%	pd = corresponding probability distribution.
%

if ( nargin ~= 4 )
  disp(' ');
  disp('usage: countprob(x,interval,maxcount,dt) ');
  disp('       for more information type "help countprob" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%initializes the various variables
int_l = ceil(interval/dt);
spk = spk(:);
spk_l = length(spk);
k_max = floor(spk_l/int_l);

cnt = (0:1:maxcount+1)';
pd = zeros(maxcount+2,1);

for k = 1:k_max
  currcnt = sum(spk((k-1)*int_l+1:k*int_l,1));
  if ( currcnt > maxcount )
    %all counts above maxcount are stored in the last bin
    currcnt = maxcount+1;
  end;
  pd(currcnt+1,1) = pd(currcnt+1,1)+1;
end;

%normalizes to probability per bin
tot_count = sum(pd);
pd = pd/tot_count;
m_cnt = sum(cnt.*pd);
std_cnt = sqrt( sum( (cnt-m_cnt).^2.*pd));
disp = std_cnt^2/m_cnt;

if ( nargout == 0)
%looks for the figure 'countprob', otherwise creates it
%and sets it to current
  fig_name = 'countprob';
  Figures = get(0,'Chil');
  new_fig = 1;
  for i=1:length(Figures)
    if strcmp(get(Figures(i),'Type'),'figure')
      if strcmp(get(Figures(i),'Name'),fig_name)
        new_fig = 0;
        h_fig = Figures(i);
        set(0,'CurrentFigure',h_fig);
      end;
    end;
  end;
  if (new_fig == 1)
    h_fig = figure('Name',fig_name);
  end;

%sets decorations and plots the isi distribution
  plot(cnt,pd);
  titt = sprintf('Spike count distribution for an interval of %g [msec]',...
	  interval);
  title(titt);
  xlabel('spike count');
  ylabel('probability per bin');
  meant = sprintf('mean = %.3g spikes',m_cnt);
  stdt = sprintf('std = %.3g spikes',std_cnt);
  dispt = sprintf('dispersion = %.3g',disp);
  xlim = get(gca,'XLim');
  ylim = get(gca,'YLim');
  meanx = xlim(1,2) - 0.4 * (xlim(1,2)-xlim(1,1));
  meany = ylim(1,2) - 0.1 * (ylim(1,2)-ylim(1,1));
  text(meanx,meany,meant);
  stdx = meanx;
  stdy = meany - 0.05 * (ylim(1,2)-ylim(1,1));
  text(stdx,stdy,stdt);
  dispx = meanx;
  dispy = stdy - 0.05 * (ylim(1,2)-ylim(1,1)); 
  text(dispx,dispy,dispt);
  clear cnt, pd;
end;

