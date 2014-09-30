function [mean, var] = sndpdisp(mu,alpha,tau,ref,min_int,max_int,step)
% sndpdisp: function which returns the variance in the spike count
% as a function of  the mean spike count for a shot noise driven doubly 
% stochastic Poisson process with square impulse response and
% refractory period. If called without output arguments, the function
% plots the dispersion relation. 
%
%	[m_cnt, var_cnt] = sndpdisp(mu,alpha,tau,ref,min_int,max_int,step)
%
%	where 
%	  mu = mean rate of the driving Poisson process (Hz)
%	  tau = time constant of the square filter (msec)
%	  alpha = multiplication parameter (msec)
%	  ref = refractory period (msec)
%	  min_int = minimal interval (msec)
%	  max_int = maximal interval (msec)
%	  step = increment step for interval length (msec)
%
% The return parameters are:
%	mean = mean count values
%	var = corresponding variances
%
% The formulas implemented here are derived in Saleh, Tavolacci and Teich
% (IEEE J. Quant. El., vol Qe-17, pp. 2341-2350, 1981). See also Saleh and
% Teich (Biol. Cybern., 52, pp. 101-107, 1985).
%

if ( nargin ~= 7 )
  disp(' ');
  disp('usage: sndpdisp(mu,alpha,tau,ref,min_int,max_int,step) ');
  disp('       for more information type "help sndpdisp2" in the main');
  disp('       matlab window');
  disp(' ');
  return;
end;

%initializes the various variables
mu = mu*1e-3; %converts to kHz, since time is in msec. 
c = mu*tau;
lambdabar = mu*alpha;

n=10; %number of terms used in the series expansion for nu1, nu2 and nu3   

fac = gamma((2:n+1))'; % table of factorials from 1! to 100!

nu1 = 1; %k=0 term
nu2 = 1;
nu3 = 1;
for k=1:n
  nu1 = nu1 + c^(k+1)/(fac(k,1)*(c+lambdabar*ref*k));
  nu2 = nu2 + c^(k+2)/(fac(k,1)*(c+lambdabar*ref*k)^2);
  nu3 = nu3 + c^(k+3)/(fac(k,1)*(c+lambdabar*ref*k)^3);
end;
nu1 = (exp(-c)/(lambdabar*ref))*nu1;
nu2 = (exp(-c)/(lambdabar*ref))*nu2;
nu3 = (exp(-c)/(lambdabar*ref))*nu3;

t = min_int;
s = 1;
disp(' ');

while ( t <= max_int)
  infot = sprintf('Computing mean and variance for t=%g ...',t);
  disp(infot);

  Gamma = t/tau;
  if ( Gamma <= 1 )
    y = Gamma*c;
  else
    y = c;
  end;

%computes phi with n terms
  n = 10;
  fac = gamma((1:n+2))';      % table of factorials from 0! to n+1!
  ginc = gammainc(y,(1:n+2)').*fac; 
                            %incomplete gamma function for n=1 to n+2
  phi = 0;
  for k=0:n
    for l=0:k
      for m = 0:l
        for j = 0:(k-l)
          t_klmj = ((-1)^j)*c^(k-l-j+2)*...
                (ginc(l+j+1,1)-ginc(l+j+2,1)/(Gamma*c))*...
                (c +(k-l+m)*lambdabar*ref)^(-1)*...
                (c+(k-m)*lambdabar*ref)^(-1)*...
                (fac(max(k-l-j+1,1),1)*fac(max(l-m+1,1),1))^(-1)*...
                (fac(max(m+1,1),1)*fac(max(j+1,1),1))^(-1);
          phi = phi + t_klmj;
        end;
      end;
    end;
  end;

  w = (2*alpha*exp(-c)*phi)/(lambdabar*ref)^2;
  if ( Gamma < 1 ) 
    w1 = lambdabar*t*nu1^2;
  else
    w1 = lambdabar*t*nu1^2*( 1 - (1-Gamma^(-1))^2 );
  end;

  m_cnt(s,1) = (lambdabar*t)*( (lambdabar*ref)^(-1) - nu1 );
  var_cnt(s,1) = (lambdabar*t)*(nu2 - nu3 - w1 + w);

  t = t + step;
  s = s+1;
end;

disp(' ');
disp('done.');
disp(' ');

if ( nargout == 0 )
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
  plot(m_cnt,var_cnt,'g');
  title('Variance to mean dispersion');
  xlabel('mean spike count');
  ylabel('variance in spike count');
  clear m_cnt, var_cnt;
end;
