function [m_cnt, var_cnt] = dispersion(spk,dt,min_int,max_int,step)
% dispersion: function which returns the mean spike count and the
% variance in the spike count for time intervals of increasing
% size. If called without output arguments, the variance is plotted as
% a function of the mean.
%
%	[mean, var] = dispersion(spk,dt,min_int,max_int,step)
%
%	where 
%	  spk = vector containing the spike data
%	  dt = sampling step of the spike train (msec)
%	  min_int = minimal interval (msec)
%	  max_int = maximal interval (msec)
%	  step = increment step for interval length (msec)
%
% The return parameters are:
%	mean = mean count values
%	var = corresponding variances
%

if ( nargin ~= 5 )
  disp(' ');
  disp('usage: dispersion(spk,dt,min_int,max_int,step) ');
  disp('       for more information type "help dispersion" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%initializes the various variables
min_int_l = ceil(min_int/dt);
max_int_l = ceil(max_int/dt);
step_l = floor(step/dt);
spk = spk(:);
spk_l = length(spk);

int_l = min_int_l;
j = 1;

while ( int_l <= max_int_l)
  k_max = floor(spk_l/int_l);
  cnt = (0:1:int_l+1)'; %picks the max count as the interval length (worst
  pd = zeros(int_l+2,1);%case with no refractory period and
			%staturating rate).

  for k = 1:k_max
    currcnt = sum(spk((k-1)*int_l+1:k*int_l,1));
    if ( currcnt > int_l )
      currcnt = int_l + 1;
    end;
    pd(currcnt+1,1) = pd(currcnt+1,1)+1;
  end;

  %normalizes to a probability per bin
  tot_count = sum(pd);
  pd = pd/tot_count;
  m_cnt(j,1) = sum(cnt.*pd);
  var_cnt(j,1) = sum( (cnt-m_cnt(j,1)).^2.*pd);
  int_l = int_l + step_l;
  j = j+1;
end;

if ( nargout == 0)
%looks for the figure 'dispersion', otherwise creates it
%and sets it to current
  fig_name = 'dispersion';
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
  plot(m_cnt,var_cnt);
  title('Variance to mean dispersion');
  xlabel('mean spike count');
  ylabel('variance in spike count');
  clear m_cnt var_cnt;
end;

