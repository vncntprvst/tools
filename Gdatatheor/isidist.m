function [t, pd, mean, cv] = isidist(x,res,maxt,dt)
% isidist: function returns the interspike interval distribution
% of a spike sequence and its mean and  coefficient of
% variation. If called without output arguments, the isi distribution
% is plotted.
%
%	[t, pd, mean, cv] = isidist(x,res,maxt,dt)
%
%	where 
%	  x = the vector containing the spike data
%	  dt = the sampling step of the spike train (msec)
%	  res = the resolution of the isi distribution (msec)      
%	  maxt = maximal time interval to be taken into account (msec)
%
%	res is expected to be a multiple of dt and will be
%	rounded down to the nearest multiple if not. 
%
% The return parameters are:
%	t = vector of time values for the ISIs.
%	pd = corresponding probability distribution.
%	mean = mean isi
%	cv = coefficient of variation of the isi distribution

if ( nargin ~= 4 )
  disp(' ');
  disp('usage: isidist(x,res,maxt,dt) ');
  disp('       for more information type "help isidist" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%initializes the various variables
n_conv = floor(res/dt);
true_res = dt*n_conv;
n = ceil(maxt/true_res) + 1;
isi_x = (0:true_res:n*true_res)';
isi_y =zeros(n+1,1);

%determines the size of x
x = x(:);
size = length(x);

%looks for the first spike
i = 1;
while ( x(i,1)==0 & i<size)
  i = i + 1;
end;
first_spike = i;
i = i + 1;

%computes the isi distribution
while ( i < size )
  if ( x(i,1)==1 )
    isi = i - first_spike;
    isi_bin = round(isi/n_conv);
    if ( isi_bin > n )
      isi_bin = n;
    end;
    isi_y(isi_bin+1,1) = isi_y(isi_bin+1,1) + 1;
    first_spike = i;
  end;
  i = i + 1;
end;

%normalizes to probability per bin
tot_spikes = 0;
for i=1:n+1
  tot_spikes = tot_spikes + isi_y(i,1); 
end;
isi_y = isi_y/tot_spikes;

%computes mean, covariance and cv of the isi distribution
mean = sum(isi_y.*isi_x);
cov = sum(isi_y.*((isi_x-mean).^2)); 
std = sqrt(cov);
cv = std/mean;
pd = isi_y;
t = isi_x;

if ( nargout == 0 )
%looks for the figure 'isidist', otherwise creates it
%and sets it to current
  fig_name = 'isidist';
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
  plot(isi_x,isi_y);
  title('Interspike interval distribution');
  xlabel('interspike interval [msec]');
  ylabel('probability per bin');
  meant = sprintf('mean = %.3g [msec]',mean);
  cvt = sprintf('cv = %.2g ',cv);
  totspkt = sprintf('number of spikes = %g',tot_spikes);
  xlim = get(gca,'XLim');
  ylim = get(gca,'YLim');
  meanx = xlim(1,2) - 0.4 * (xlim(1,2)-xlim(1,1));
  meany = ylim(1,2) - 0.1 * (ylim(1,2)-ylim(1,1));
  text(meanx,meany,meant);
  cvx = meanx;
  cvy = meany - 0.05 * (ylim(1,2)-ylim(1,1));
  text(cvx,cvy,cvt);
  totspkx = meanx;
  totspky = cvy - 0.05 * (ylim(1,2)-ylim(1,1)); 
  text(totspkx,totspky,totspkt);
  clear pd t mean cv;
end;



