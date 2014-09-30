function [m_cnt, var_cnt] = prefdisp(rho,ref,min_int,max_int,step)
% prefdisp: function which returns the variance in the spike count
% as a function of  the mean spike count for a Poisson process with refractory
% period. If called without output parameters, the function plots the
% variance as a function of the mean.
%
%	[m_cnt, var_cnt] = prefdisp(rho,ref,min_int,max_int,step)
%
%	where 
%	  rho = mean of the unperturbed Poisson process (Hz)
%	  ref = refractory period (msec)
%	  min_int = minimal interval (msec)
%	  max_int = maximal interval (msec)
%	  step = increment step for interval length (msec)
%
% The return parameters are:
%	mean = mean count values
%	var = corresponding variances
%
% The theoretical formulas for the mean and variance can be found in
% Mueller (Nucl. Inst. and Meth., 117, pp. 401-404, 1974).
%

if ( nargin ~= 5 )
  disp(' ');
  disp('usage: prefdisp(mean,ref,min_int,max_int,step) ');
  disp('       for more information type "help prefdisp" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%initializes the various variables
rho = rho*1e-3; %converts to kHz since time intervals are in ms. 
x = rho*ref;
lambda = 1/(1+x);

t = min_int;
s = 1;

while ( t <= max_int)
  mu = rho*t;
  K = floor(t/ref);
  if ( K < 50 )
    k_vect = (0:K)';
    T_k_vect = rho*(t - k_vect*ref);
    for l = 2:length(k_vect)
      j_vect = (0:k_vect(l)-1)';
      P(1:length(j_vect),1) = T_k_vect(l,1).^j_vect*exp(-T_k_vect(l,1)) ...
	                      ./gamma(j_vect+1);
      psum(l,1) = sum((k_vect(l,1) - j_vect).* P);
      clear P;
    end;
    var_cnt(s,1) = 2*lambda*(sum(T_k_vect - k_vect) + sum(psum)) ...
	           - lambda*mu - (lambda*mu)^2;
    clear psum;
  else
    var_cnt(s,1) = lambda^3*(mu + (1/6)*lambda*x^2*(6 + 4*x + x^2));
  end;  
  m_cnt(s,1) = lambda*mu;
  t = t + step;
  s = s+1;
end;

if ( nargout == 0 )
%looks if the figure 'dispersion' already exists, otherwise creates one
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
  plot(m_cnt,var_cnt,'g');
  title('Variance to mean dispersion');
  xlabel('mean spike count');
  ylabel('variance in spike count');
  clear m_cnt, var_cnt;
end;
